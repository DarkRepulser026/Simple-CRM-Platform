import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateTicket } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List tickets with filtering and pagination
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status ? String(req.query.status).toUpperCase() : undefined;
    const priority = req.query.priority ? String(req.query.priority).toUpperCase() : undefined;
    const ownerId = req.query.ownerId ? String(req.query.ownerId) : undefined;
    const accountId = req.query.accountId ? String(req.query.accountId) : undefined;
    const search = req.query.search ? String(req.query.search).toLowerCase() : undefined;

    const skip = (page - 1) * limit;

    const where = { organizationId: req.organizationId };
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (ownerId) where.ownerId = ownerId;
    if (accountId) where.accountId = accountId;

    const tickets = await prisma.ticket.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          include: {
            author: { select: { id: true, name: true, email: true } }
          },
          orderBy: { createdAt: 'asc' }
        }
      },
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });

    let filteredTickets = tickets;
    if (search) {
      filteredTickets = tickets.filter(t => 
        t.subject.toLowerCase().includes(search) || 
        (t.description && t.description.toLowerCase().includes(search))
      );
    }

    const total = await prisma.ticket.count({ where });

    res.json({
      tickets: filteredTickets,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST / - Create ticket
router.post('/', authorize(['CREATE_TICKETS']), validateTicket, async (req, res) => {
  try {
    const { subject, description, status, priority, category, accountId, ownerId, slaDeadline } = req.body;

    // Map frontend display values to Prisma enums
    const statusMap = {
      'Open': 'OPEN',
      'In Progress': 'IN_PROGRESS',
      'Resolved': 'RESOLVED',
      'Closed': 'CLOSED'
    };

    const priorityMap = {
      'Low': 'LOW',
      'Normal': 'NORMAL',
      'High': 'HIGH',
      'Urgent': 'URGENT'
    };

    // Helper to sanitize inputs (convert empty strings/nulls to undefined)
    const sanitize = (val) => (val === '' || val === null ? undefined : val);

    const ticket = await prisma.ticket.create({
      data: {
        subject,
        description: sanitize(description),
        status: statusMap[status] || (Object.values(statusMap).includes(status) ? status : undefined),
        priority: priorityMap[priority] || (Object.values(priorityMap).includes(priority) ? priority : undefined),
        category: sanitize(category),
        accountId: sanitize(accountId),
        ownerId: sanitize(ownerId) || req.user.id,
        slaDeadline: sanitize(slaDeadline) ? new Date(sanitize(slaDeadline)) : undefined,
        organizationId: req.organizationId,
        createdById: req.user.id
      }
    });

    await createActivityLogEntry({
      action: 'TICKET_CREATED',
      entityType: 'Ticket',
      entityId: ticket.id,
      description: `Ticket ${ticket.subject} created by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.status(201).json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get ticket details
router.get('/:id', async (req, res) => {
  try {
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          include: {
            author: { select: { id: true, name: true, email: true } }
          },
          orderBy: { createdAt: 'asc' }
        }
      }
    });
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }
    res.json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id/activities - Get ticket activity log
router.get('/:id/activities', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const _page = Math.max(parseInt(page), 1);
    const _limit = Math.min(parseInt(limit), 100);
    const skip = (_page - 1) * _limit;

    // Verify ticket exists
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const total = await prisma.activityLog.count({
      where: {
        entityType: 'Ticket',
        entityId: req.params.id,
        organizationId: req.organizationId
      }
    });

    const activities = await prisma.activityLog.findMany({
      where: {
        entityType: 'Ticket',
        entityId: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        user: { select: { id: true, name: true, email: true } }
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: _limit
    });

    res.json({
      activities,
      pagination: {
        page: _page,
        limit: _limit,
        total,
        totalPages: Math.ceil(total / _limit),
        hasNext: _page * _limit < total,
        hasPrev: _page > 1
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /:id - Update ticket
router.put('/:id', authorize(['EDIT_TICKETS']), async (req, res) => {
  try {
    const existing = await prisma.ticket.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Ticket not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { 
      oldValues[k] = existing[k]; 
      newValues[k] = req.body[k]; 
    });
    
    const updated = await prisma.ticket.update({ where: { id: req.params.id }, data: req.body });
    
    await createActivityLogEntry({ 
      action: 'TICKET_UPDATED', 
      entityType: 'Ticket', 
      entityId: updated.id, 
      description: `Ticket updated by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/assign - Assign ticket to agent
router.post('/:id/assign', authorize(['ASSIGN_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { assignedToId } = req.body;
    if (!assignedToId) return res.status(400).json({ message: 'assignedToId is required' });
    
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    
    const agentOrg = await prisma.userOrganization.findFirst({ where: { userId: assignedToId, organizationId: req.organizationId } });
    if (!agentOrg) return res.status(400).json({ message: 'Assigned user not in organization' });
    
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { ownerId: assignedToId } });
    
    await createActivityLogEntry({ 
      action: 'TICKET_ASSIGNED', 
      entityType: 'Ticket', 
      entityId: updated.id, 
      description: `${req.user.email} assigned ticket to ${assignedToId}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    await prisma.ticketMessage.create({ 
      data: { ticketId: updated.id, authorId: req.user.id, content: `Assigned to user ${assignedToId}`, isInternal: true } 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/resolve - Resolve ticket
router.post('/:id/resolve', authorize(['RESOLVE_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    
    const { resolution } = req.body;
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'RESOLVED' } });
    
    if (resolution) {
      await prisma.ticketMessage.create({ 
        data: { ticketId: ticketId, authorId: req.user.id, content: `Resolution: ${String(resolution)}`, isInternal: true } 
      });
    }
    
    await createActivityLogEntry({ 
      action: 'TICKET_RESOLVED', 
      entityType: 'Ticket', 
      entityId: updated.id, 
      description: `${req.user.email} resolved ticket ${updated.id}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/close - Close ticket
router.post('/:id/close', authorize(['RESOLVE_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'CLOSED' } });
    
    await createActivityLogEntry({ 
      action: 'TICKET_CLOSED', 
      entityType: 'Ticket', 
      entityId: updated.id, 
      description: `${req.user.email} closed ticket ${updated.id}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/reopen - Reopen ticket
router.post('/:id/reopen', authorize(['EDIT_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'OPEN' } });
    
    await createActivityLogEntry({ 
      action: 'TICKET_REOPENED', 
      entityType: 'Ticket', 
      entityId: updated.id, 
      description: `${req.user.email} reopened ticket ${updated.id}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/satisfaction - Add satisfaction rating
router.post('/:id/satisfaction', async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    
    const { rating, feedback } = req.body;
    if (rating == null) return res.status(400).json({ message: 'rating is required' });
    
    const content = `Satisfaction rating: ${rating}${feedback ? ' • ' + String(feedback) : ''}`;
    const msg = await prisma.ticketMessage.create({ 
      data: { ticketId: ticketId, authorId: req.user.id, content, isInternal: false } 
    });
    
    await createActivityLogEntry({ 
      action: 'TICKET_SATISFACTION', 
      entityType: 'Ticket', 
      entityId: ticketId, 
      description: `${req.user.email} left satisfaction rating ${rating} for ticket ${ticketId}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json({ success: true, message: msg });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete ticket
router.delete('/:id', authorize(['DELETE_TICKETS']), async (req, res) => {
  try {
    const existing = await prisma.ticket.findFirst({
      where: { id: req.params.id, organizationId: req.organizationId }
    });

    if (!existing) return res.status(404).json({ message: 'Ticket not found' });

    await prisma.ticket.delete({
      where: { id: req.params.id }
    });

    await createActivityLogEntry({
      action: 'TICKET_DELETED',
      entityType: 'Ticket',
      entityId: req.params.id,
      description: `Ticket ${existing.subject} deleted by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: { ticket: existing }
    });

    res.json({ message: 'Ticket deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/messages - Add ticket message
router.post('/:id/messages', async (req, res) => {
  try {
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const message = await prisma.ticketMessage.create({
      data: {
        content: req.body.content,
        isInternal: req.body.isInternal || false,
        ticketId: req.params.id,
        authorId: req.user.id
      },
      include: {
        author: { select: { id: true, name: true, email: true } }
      }
    });
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
