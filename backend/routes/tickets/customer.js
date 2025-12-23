import express from 'express';
import path from 'path';
import fs from 'fs';
import multer from 'multer';
import prisma from '../../lib/prismaClient.js';
import { requireCustomer } from '../../lib/customerMiddleware.js';

const router = express.Router();
const uploadsDir = path.join(process.cwd(), 'uploads');
const upload = multer({ dest: 'uploads/temp/' });

// Helper function to generate ticket number
function generateTicketNumber(organizationId) {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `TICKET-${timestamp}-${random}`;
}

// Apply middleware to all routes in this router
router.use(requireCustomer);

// GET / - Get customer's tickets with pagination
router.get('/', async (req, res) => {
  try {
    const { status, priority, page = '1', limit = '20' } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const where = { customerId: req.userId };
    if (status) where.status = status.toUpperCase();
    if (priority) where.priority = priority.toUpperCase();

    const [tickets, total] = await Promise.all([
      prisma.ticket.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limitNum,
        include: {
          organization: { select: { id: true, name: true } },
          owner: { select: { id: true, name: true, email: true } },
          messages: {
            where: { isInternal: false },
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: { content: true, createdAt: true }
          }
        }
      }),
      prisma.ticket.count({ where })
    ]);

    res.json({
      tickets,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Get tickets error:', error);
    res.status(500).json({ error: 'Failed to retrieve tickets' });
  }
});

// POST / - Create new ticket
router.post('/', async (req, res) => {
  try {
    const { subject, description, priority = 'NORMAL', category } = req.body;

    if (!subject || !description) {
      return res.status(400).json({ error: 'Subject and description are required' });
    }

    let organizationId;
    const userOrg = await prisma.userOrganization.findFirst({
      where: { userId: req.userId }
    });

    if (userOrg) {
      organizationId = userOrg.organizationId;
    } else {
      let defaultOrg = await prisma.organization.findFirst({
        where: { name: 'Customer Portal' }
      });

      if (!defaultOrg) {
        defaultOrg = await prisma.organization.create({
          data: {
            name: 'Customer Portal',
            description: 'Default organization for customer portal tickets'
          }
        });
      }
      organizationId = defaultOrg.id;
    }

    const ticketNumber = generateTicketNumber(organizationId);

    const ticket = await prisma.ticket.create({
      data: {
        subject,
        description,
        priority: priority.toUpperCase(),
        category: category || null,
        status: 'OPEN',
        customerId: req.userId,
        organizationId,
      },
      include: {
        organization: { select: { id: true, name: true } }
      }
    });

    res.status(201).json({
      ticketId: ticket.id,
      number: ticketNumber,
      status: ticket.status,
      ticket
    });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({ error: 'Failed to create ticket' });
  }
});

// GET /:id - Get ticket details
router.get('/:id', async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId },
      include: {
        organization: { select: { id: true, name: true } },
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          where: { isInternal: false },
          orderBy: { createdAt: 'asc' },
          include: {
            author: { select: { id: true, name: true, email: true, type: true } }
          }
        }
      }
    });

    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this ticket' });
    }

    res.json(ticket);
  } catch (error) {
    console.error('Get ticket detail error:', error);
    res.status(500).json({ error: 'Failed to retrieve ticket details' });
  }
});

// PUT /:id - Update ticket (limited fields)
router.put('/:id', async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { subject, description, priority } = req.body;

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to update this ticket' });
    }
    if (ticket.status !== 'OPEN') {
      return res.status(403).json({ error: 'Only open tickets can be edited' });
    }

    const updateData = {};
    if (subject) updateData.subject = subject;
    if (description) updateData.description = description;
    if (priority) updateData.priority = priority.toUpperCase();

    const updatedTicket = await prisma.ticket.update({
      where: { id: ticketId },
      data: updateData,
      include: {
        organization: { select: { id: true, name: true } }
      }
    });

    res.json(updatedTicket);
  } catch (error) {
    console.error('Update ticket error:', error);
    res.status(500).json({ error: 'Failed to update ticket' });
  }
});

// GET /:id/messages - Get ticket messages
router.get('/:id/messages', async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { page = '1', limit = '20' } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this ticket' });
    }

    const [messages, total] = await Promise.all([
      prisma.ticketMessage.findMany({
        where: { ticketId, isInternal: false },
        orderBy: { createdAt: 'asc' },
        skip,
        take: limitNum,
        include: {
          author: { select: { id: true, name: true, email: true, type: true } }
        }
      }),
      prisma.ticketMessage.count({ where: { ticketId, isInternal: false } })
    ]);

    res.json({
      messages,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Failed to retrieve messages' });
  }
});

// POST /:id/messages - Add message to ticket
router.post('/:id/messages', async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { content } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Message content is required' });
    }

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to add messages to this ticket' });
    }

    const message = await prisma.ticketMessage.create({
      data: {
        content: content.trim(),
        isInternal: false,
        ticketId,
        authorId: req.userId
      },
      include: {
        author: { select: { id: true, name: true, email: true, type: true } }
      }
    });

    await prisma.ticket.update({
      where: { id: ticketId },
      data: { updatedAt: new Date() }
    });

    res.status(201).json({
      messageId: message.id,
      createdAt: message.createdAt,
      message
    });
  } catch (error) {
    console.error('Create message error:', error);
    res.status(500).json({ error: 'Failed to add message' });
  }
});

// POST /:id/attachments - Upload attachment
router.post('/:id/attachments', upload.single('file'), async (req, res) => {
  try {
    const ticketId = req.params.id;
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket) {
      if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
      return res.status(403).json({ error: 'You do not have permission to add attachments to this ticket' });
    }

    const maxSize = 10 * 1024 * 1024;
    if (req.file.size > maxSize) {
      if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'File size exceeds 10MB limit' });
    }

    const filename = req.file.originalname || req.file.filename;
    const targetDir = path.join(uploadsDir, ticket.organizationId);
    if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
    const targetPath = path.join(targetDir, `${Date.now()}-${filename}`);
    fs.renameSync(req.file.path, targetPath);

    const url = `/uploads/${ticket.organizationId}/${path.basename(targetPath)}`;
    const attachment = await prisma.attachment.create({
      data: {
        filename,
        mimeType: req.file.mimetype,
        url,
        size: req.file.size,
        uploadedBy: req.userId,
        organizationId: ticket.organizationId,
        entityType: 'ticket',
        entityId: ticketId,
      }
    });

    res.status(201).json(attachment);
  } catch (error) {
    console.error('Upload attachment error:', error);
    res.status(500).json({ error: 'Failed to upload attachment' });
  }
});

// DELETE /:id/attachments/:attachmentId - Delete attachment
router.delete('/:id/attachments/:attachmentId', async (req, res) => {
  try {
    const { id: ticketId, attachmentId } = req.params;

    const attachment = await prisma.attachment.findUnique({ where: { id: attachmentId } });
    if (!attachment) return res.status(404).json({ error: 'Attachment not found' });

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to delete this attachment' });
    }

    const filePath = path.join(uploadsDir, attachment.organizationId, path.basename(attachment.url));
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    await prisma.attachment.delete({ where: { id: attachmentId } });
    res.json({ success: true, message: 'Attachment deleted' });
  } catch (error) {
    console.error('Delete attachment error:', error);
    res.status(500).json({ error: 'Failed to delete attachment' });
  }
});

// GET /:id/attachments/:attachmentId - Download attachment
router.get('/:id/attachments/:attachmentId', async (req, res) => {
  try {
    const { id: ticketId, attachmentId } = req.params;

    const attachment = await prisma.attachment.findUnique({ where: { id: attachmentId } });
    if (!attachment) return res.status(404).json({ error: 'Attachment not found' });

    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this attachment' });
    }

    const filePath = path.join(uploadsDir, attachment.organizationId, path.basename(attachment.url));
    if (!fs.existsSync(filePath)) return res.status(404).json({ error: 'File not found' });

    res.download(filePath, attachment.filename);
  } catch (error) {
    console.error('Download attachment error:', error);
    res.status(500).json({ error: 'Failed to download attachment' });
  }
});

export default router;
