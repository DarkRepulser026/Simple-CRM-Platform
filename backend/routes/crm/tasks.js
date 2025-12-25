import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateTask } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import { validateTaskAssignee } from '../../middleware/taskPermissions.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List tasks with filtering and pagination
router.get('/', async (req, res) => {
  try {
    const { page, limit, status, priority, ownerId, overdue, q } = req.query;
    const _page = parseInt(page) || 1;
    const _limit = Math.min(parseInt(limit) || 20, 1000);
    const skip = (_page - 1) * _limit;

    const where = { organizationId: req.organizationId };
    
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (ownerId) where.ownerId = ownerId;
    
    if (overdue === 'true') {
      where.AND = [
        { dueDate: { lt: new Date() } },
        { status: { not: 'COMPLETED' } }
      ];
    }
    
    if (q) {
      const qStr = String(q).toLowerCase();
      where.OR = [
        { subject: { contains: qStr, mode: 'insensitive' } },
        { description: { contains: qStr, mode: 'insensitive' } }
      ];
    }

    const total = await prisma.task.count({ where });

    const tasks = await prisma.task.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } },
        lead: { select: { id: true, firstName: true, lastName: true } }
      },
      skip,
      take: _limit,
      orderBy: { dueDate: 'asc' }
    });

    res.json({
      tasks,
      pagination: {
        page: _page,
        limit: _limit,
        total,
        totalPages: Math.ceil(total / _limit),
        hasNext: _page * _limit < total,
        hasPrev: _page > 1,
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST / - Create task
router.post('/', authorize(['CREATE_TASKS']), validateTask, validateTaskAssignee, async (req, res) => {
  try {
    const { 
      subject, description, status, priority, dueDate, 
      ownerId, accountId, contactId, leadId, opportunityId, caseId 
    } = req.body;

    // Validate accountId if provided
    if (accountId) {
      const account = await prisma.account.findFirst({
        where: { id: accountId, organizationId: req.organizationId }
      });
      if (!account) {
        return res.status(400).json({ message: 'Invalid account ID or account not found' });
      }
    }

    // Validate contactId if provided
    if (contactId) {
      const contact = await prisma.contact.findFirst({
        where: { id: contactId, organizationId: req.organizationId }
      });
      if (!contact) {
        return res.status(400).json({ message: 'Invalid contact ID or contact not found' });
      }
    }

    // Validate leadId if provided
    if (leadId) {
      const lead = await prisma.lead.findFirst({
        where: { id: leadId, organizationId: req.organizationId }
      });
      if (!lead) {
        return res.status(400).json({ message: 'Invalid lead ID or lead not found' });
      }
    }

    const statusMap = {
      'Not Started': 'NOT_STARTED',
      'In Progress': 'IN_PROGRESS',
      'Completed': 'COMPLETED',
      'Cancelled': 'CANCELLED'
    };
    
    const priorityMap = {
      'High': 'HIGH',
      'Normal': 'NORMAL',
      'Low': 'LOW'
    };

    // Helper to sanitize inputs (convert empty strings/nulls to undefined)
    const sanitize = (val) => (val === '' || val === null ? undefined : val);

    const task = await prisma.task.create({
      data: {
        subject,
        description: sanitize(description),
        status: statusMap[status] || (Object.values(statusMap).includes(status) ? status : undefined),
        priority: priorityMap[priority] || (Object.values(priorityMap).includes(priority) ? priority : undefined),
        dueDate: sanitize(dueDate) ? new Date(sanitize(dueDate)) : undefined,
        ownerId: sanitize(ownerId),
        accountId: sanitize(accountId),
        contactId: sanitize(contactId),
        leadId: sanitize(leadId),
        opportunityId: sanitize(opportunityId),
        caseId: sanitize(caseId),
        organizationId: req.organizationId,
        createdById: req.user.id
      }
    });

    await createActivityLogEntry({
      action: 'TASK_CREATED',
      entityType: 'Task',
      entityId: task.id,
      description: `Task ${task.subject} created by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId
    });

    res.status(201).json(task);
  } catch (error) {
    console.error('Task creation error:', error);
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get task details
router.get('/:id', async (req, res) => {
  try {
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } },
        lead: { select: { id: true, firstName: true, lastName: true } }
      }
    });
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id/activities - Get task activity log
router.get('/:id/activities', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const _page = Math.max(parseInt(page), 1);
    const _limit = Math.min(parseInt(limit), 100);
    const skip = (_page - 1) * _limit;

    // Verify task exists
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    const total = await prisma.activityLog.count({
      where: {
        entityType: 'Task',
        entityId: req.params.id,
        organizationId: req.organizationId
      }
    });

    const activities = await prisma.activityLog.findMany({
      where: {
        entityType: 'Task',
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

// PUT /:id - Update task
router.put('/:id', authorize(['EDIT_TASKS']), validateTaskAssignee, async (req, res) => {
  try {
    const existing = await prisma.task.findFirst({ 
      where: { id: req.params.id, organizationId: req.organizationId },
      include: { owner: { select: { name: true, email: true } } }
    });
    if (!existing) return res.status(404).json({ message: 'Task not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { 
      oldValues[k] = existing[k]; 
      newValues[k] = req.body[k]; 
    });
    
    // Check if owner is being reassigned
    const isReassignment = req.body.ownerId && req.body.ownerId !== existing.ownerId;
    
    const updated = await prisma.task.update({ 
      where: { id: req.params.id }, 
      data: req.body,
      include: { owner: { select: { name: true, email: true } } }
    });
    
    // Log specific reassignment activity if owner changed
    if (isReassignment) {
      await createActivityLogEntry({ 
        action: 'TASK_REASSIGNED', 
        entityType: 'Task', 
        entityId: updated.id, 
        description: `Task reassigned from ${existing.owner?.name || 'Unassigned'} to ${updated.owner?.name || 'Unassigned'} by ${req.user.email}`, 
        userId: req.user.id, 
        organizationId: req.organizationId, 
        metadata: { 
          oldOwnerId: existing.ownerId, 
          newOwnerId: updated.ownerId,
          oldOwnerName: existing.owner?.name,
          newOwnerName: updated.owner?.name
        } 
      });
    } else {
      // Log generic update activity
      await createActivityLogEntry({ 
        action: 'TASK_UPDATED', 
        entityType: 'Task', 
        entityId: updated.id, 
        description: `Task updated by ${req.user.email}`, 
        userId: req.user.id, 
        organizationId: req.organizationId, 
        metadata: { oldValues, newValues } 
      });
    }
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete task
router.delete('/:id', authorize(['DELETE_TASKS']), async (req, res) => {
  try {
    const existing = await prisma.task.findFirst({
      where: { id: req.params.id, organizationId: req.organizationId }
    });

    if (!existing) return res.status(404).json({ message: 'Task not found' });

    await prisma.task.delete({
      where: { id: req.params.id }
    });

    await createActivityLogEntry({
      action: 'TASK_DELETED',
      entityType: 'Task',
      entityId: req.params.id,
      description: `Task ${existing.subject} deleted by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: { task: existing }
    });

    res.json({ message: 'Task deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
