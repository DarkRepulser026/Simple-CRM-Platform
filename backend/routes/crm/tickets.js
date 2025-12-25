/**
 * Tickets Routes
 * 
 * Implements conversation-first support UI with proper permission enforcement
 * Based on ARCHITECTURE_PATTERNS.md specifications
 */

import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import {
  enforceTicketStatusTransitions,
  enforceTicketReassignment,
  enforceTicketReplyPermissions,
  enforceTicketClosure,
  validateTicketAssignee
} from '../../middleware/ticketPermissions.js';

const router = express.Router();

// Apply middleware to all routes
router.use(authenticateToken);
router.use(requireOrganization);

/**
 * GET / - List tickets with filtering
 * 
 * Filters: Status / Priority / Assignee
 * Includes unread indicator
 */
router.get('/', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const status = req.query.status ? String(req.query.status) : null;
    const priority = req.query.priority ? String(req.query.priority) : null;
    const ownerId = req.query.ownerId ? String(req.query.ownerId) : null;
    const customerId = req.query.customerId ? String(req.query.customerId) : null;
    const accountId = req.query.accountId ? String(req.query.accountId) : null;

    const where = { organizationId: req.organizationId };

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (ownerId) where.ownerId = ownerId;
    if (customerId) where.customerId = customerId;
    if (accountId) where.accountId = accountId;

    const total = await prisma.ticket.count({ where });
    const tickets = await prisma.ticket.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        customer: { select: { id: true, name: true, email: true } },
        account: { select: { id: true, name: true } },
        _count: {
          select: { messages: true }
        }
      }
    });

    res.json({
      tickets,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * POST / - Create new ticket
 */
router.post('/', authorize(['CREATE_TICKETS']), validateTicketAssignee, async (req, res) => {
  try {
    const { subject, description, priority, category, accountId, customerId } = req.body;

    if (!subject) {
      return res.status(400).json({ message: 'Subject is required' });
    }

    // Map frontend display values to Prisma enums
    const priorityMap = {
      'Low': 'LOW',
      'Normal': 'NORMAL',
      'High': 'HIGH',
      'Urgent': 'URGENT'
    };

    // Validate accountId if provided
    if (accountId) {
      const account = await prisma.account.findFirst({
        where: { id: accountId, organizationId: req.organizationId }
      });
      if (!account) {
        return res.status(400).json({ message: 'Invalid account ID or account not found' });
      }
    }

    // Validate customerId if provided
    if (customerId) {
      const customer = await prisma.user.findFirst({
        where: { id: customerId, type: 'CUSTOMER' }
      });
      if (!customer) {
        return res.status(400).json({ message: 'Invalid customer ID or customer not found' });
      }
    }

    // Helper to sanitize inputs (convert empty strings/nulls to undefined)
    const sanitize = (val) => (val === '' || val === null ? undefined : val);

    const ticket = await prisma.ticket.create({
      data: {
        subject,
        description: sanitize(description),
        priority: priorityMap[priority] || (Object.values(priorityMap).includes(priority) ? priority : 'NORMAL'),
        category: sanitize(category),
        accountId: sanitize(accountId),
        // customerId, // TODO: Add customerId to Ticket schema
        ownerId: sanitize(req.body.ownerId),
        createdById: req.user.id,
        organizationId: req.organizationId,
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        createdBy: { select: { id: true, name: true, email: true } },
        customer: { select: { id: true, name: true, email: true } }
      }
    });

    // Log activity
    await createActivityLogEntry({
      action: 'TICKET_CREATED',
      entityType: 'Ticket',
      entityId: ticket.id,
      description: `Ticket "${subject}" created`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.status(201).json(ticket);
  } catch (error) {
    console.error('Ticket creation error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /:id - Get ticket detail with conversation thread
 */
router.get('/:id', async (req, res) => {
  try {
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        customer: { select: { id: true, name: true, email: true } },
        account: { select: { id: true, name: true } },
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

/**
 * PUT /:id - Update ticket basic info
 */
router.put('/:id', authorize(['EDIT_TICKETS']), async (req, res) => {
  try {
    const { subject, description, priority, category, accountId } = req.body;

    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const updated = await prisma.ticket.update({
      where: { id: req.params.id },
      data: {
        subject,
        description,
        priority,
        category,
        accountId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    await createActivityLogEntry({
      action: 'TICKET_UPDATED',
      entityType: 'Ticket',
      entityId: updated.id,
      description: `Ticket updated by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * PUT /:id/status - Change ticket status
 * 🔒 UX Rule: Agents have limited transitions, Managers can override
 */
router.put('/:id/status', enforceTicketStatusTransitions, async (req, res) => {
  try {
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }

    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const updated = await prisma.ticket.update({
      where: { id: req.params.id },
      data: {
        status,
        resolvedAt: status === 'RESOLVED' || status === 'CLOSED' ? new Date() : ticket.resolvedAt
      },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    await createActivityLogEntry({
      action: 'TICKET_STATUS_CHANGED',
      entityType: 'Ticket',
      entityId: updated.id,
      description: `Ticket status changed from ${ticket.status} to ${status} by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: {
        oldStatus: ticket.status,
        newStatus: status
      }
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * PUT /:id/assign - Reassign ticket
 * 🔒 UX Rule: Only Managers+ can reassign
 */
router.put('/:id/assign', enforceTicketReassignment, validateTicketAssignee, async (req, res) => {
  try {
    const { ownerId } = req.body;

    if (!ownerId) {
      return res.status(400).json({ message: 'Owner ID is required' });
    }

    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    // Verify new owner exists in organization
    const newOwner = await prisma.user.findFirst({
      where: {
        id: ownerId,
        organizationId: req.organizationId
      }
    });

    if (!newOwner) {
      return res.status(404).json({ message: 'New owner not found in organization' });
    }

    const updated = await prisma.ticket.update({
      where: { id: req.params.id },
      data: { ownerId },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    await createActivityLogEntry({
      action: 'TICKET_REASSIGNED',
      entityType: 'Ticket',
      entityId: updated.id,
      description: `Ticket reassigned from ${ticket.owner?.name || 'unassigned'} to ${newOwner.name} by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: {
        oldOwnerId: ticket.ownerId,
        newOwnerId: ownerId
      }
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * POST /:id/messages - Add message to ticket (reply)
 * 👤 UX Rule: All users can reply, only staff can add internal notes
 */
router.post('/:id/messages', enforceTicketReplyPermissions, async (req, res) => {
  try {
    const { content, isInternal } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ message: 'Message content is required' });
    }

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
        content,
        isInternal: isInternal || false,
        ticketId: req.params.id,
        authorId: req.user.id
      },
      include: {
        author: { select: { id: true, name: true, email: true } }
      }
    });

    // Update ticket respondedAt if first staff response
    if (!ticket.respondedAt && req.user.type === 'STAFF') {
      await prisma.ticket.update({
        where: { id: req.params.id },
        data: { respondedAt: new Date() }
      });
    }

    await createActivityLogEntry({
      action: isInternal ? 'TICKET_INTERNAL_NOTE' : 'TICKET_MESSAGE_SENT',
      entityType: 'Ticket',
      entityId: ticket.id,
      description: `${isInternal ? 'Internal note' : 'Message'} added by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * POST /:id/close - Close ticket
 * 🔒 UX Rule: Agents can only close RESOLVED tickets, Managers can forcibly close
 */
router.post('/:id/close', enforceTicketClosure, async (req, res) => {
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

    const updated = await prisma.ticket.update({
      where: { id: req.params.id },
      data: {
        status: 'CLOSED',
        resolvedAt: ticket.resolvedAt || new Date()
      },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    await createActivityLogEntry({
      action: 'TICKET_CLOSED',
      entityType: 'Ticket',
      entityId: updated.id,
      description: `Ticket closed by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * DELETE /:id - Delete ticket
 */
router.delete('/:id', authorize(['DELETE_TICKETS']), async (req, res) => {
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

    await prisma.ticket.delete({
      where: { id: req.params.id }
    });

    await createActivityLogEntry({
      action: 'TICKET_DELETED',
      entityType: 'Ticket',
      entityId: req.params.id,
      description: `Ticket "${ticket.subject}" deleted by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: { deletedTicket: ticket }
    });

    res.json({ message: 'Ticket deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
