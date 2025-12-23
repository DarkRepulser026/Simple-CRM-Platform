import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateTask } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';

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
        { status: { not: 'Completed' } }
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
router.post('/', authorize(['CREATE_TASKS']), validateTask, async (req, res) => {
  try {
    const task = await prisma.task.create({
      data: {
        ...req.body,
        organizationId: req.organizationId,
        createdById: req.user.id
      }
    });
    res.status(201).json(task);
  } catch (error) {
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

// PUT /:id - Update task
router.put('/:id', authorize(['EDIT_TASKS']), async (req, res) => {
  try {
    const existing = await prisma.task.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Task not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { 
      oldValues[k] = existing[k]; 
      newValues[k] = req.body[k]; 
    });
    
    const updated = await prisma.task.update({ where: { id: req.params.id }, data: req.body });
    
    await createActivityLogEntry({ 
      action: 'TASK_UPDATED', 
      entityType: 'Task', 
      entityId: updated.id, 
      description: `Task updated by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });
    
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete task
router.delete('/:id', authorize(['DELETE_TASKS']), async (req, res) => {
  try {
    const task = await prisma.task.deleteMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (task.count === 0) {
      return res.status(404).json({ message: 'Task not found' });
    }
    res.json({ message: 'Task deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
