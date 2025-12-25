import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateAccount } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List accounts with filtering and pagination
router.get('/', authorize(['VIEW_ACCOUNTS']), async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    
    const where = { organizationId: req.organizationId };
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { type: { contains: search, mode: 'insensitive' } },
      ];
    }

    const total = await prisma.account.count({ where });
    const accounts = await prisma.account.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      accounts,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      }
    });
  } catch (err) {
    console.error('List accounts error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST / - Create account
router.post('/', authorize(['CREATE_ACCOUNTS']), validateAccount, async (req, res) => {
  try {
    const data = { 
      ...req.body, 
      organizationId: req.organizationId,
      ownerId: req.body.ownerId || req.user.id
    };
    const acc = await prisma.account.create({ data });
    
    await createActivityLogEntry({ 
      action: 'ACCOUNT_CREATED', 
      entityType: 'Account', 
      entityId: acc.id, 
      description: `Account ${acc.name} created`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });

    res.status(201).json(acc);
  } catch (err) {
    console.error('Create account error:', err);
    res.status(500).json({ message: err.message });
  }
});

// GET /:id - Get account details
router.get('/:id', authorize(['VIEW_ACCOUNTS']), async (req, res) => {
  try {
    const account = await prisma.account.findFirst({ 
      where: { id: req.params.id, organizationId: req.organizationId },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contacts: { select: { id: true, firstName: true, lastName: true, email: true, title: true } },
        tasks: { 
          select: { id: true, subject: true, status: true, dueDate: true, priority: true },
          orderBy: { dueDate: 'asc' }
        },
        tickets: {
          select: { id: true, subject: true, status: true, priority: true, createdAt: true },
          orderBy: { createdAt: 'desc' }
        }
      }
    });
    if (!account) return res.status(404).json({ message: 'Account not found' });
    res.json(account);
  } catch (err) {
    console.error('Get account error:', err);
    res.status(500).json({ message: err.message });
  }
});

// GET /:id/activities - Get account activity log
router.get('/:id/activities', authorize(['VIEW_ACCOUNTS']), async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const _page = Math.max(parseInt(page), 1);
    const _limit = Math.min(parseInt(limit), 100);
    const skip = (_page - 1) * _limit;

    // Verify account exists
    const account = await prisma.account.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!account) {
      return res.status(404).json({ message: 'Account not found' });
    }

    const total = await prisma.activityLog.count({
      where: {
        entityType: 'Account',
        entityId: req.params.id,
        organizationId: req.organizationId
      }
    });

    const activities = await prisma.activityLog.findMany({
      where: {
        entityType: 'Account',
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
  } catch (err) {
    console.error('Get account activities error:', err);
    res.status(500).json({ message: err.message });
  }
});

// PUT /:id - Update account
router.put('/:id', authorize(['EDIT_ACCOUNTS']), async (req, res) => {
  try {
    const existing = await prisma.account.findFirst({ 
      where: { id: req.params.id, organizationId: req.organizationId } 
    });
    
    if (!existing) return res.status(404).json({ message: 'Account not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => {
      oldValues[k] = existing[k];
      newValues[k] = req.body[k];
    });

    const updated = await prisma.account.update({ 
      where: { id: req.params.id }, 
      data: req.body 
    });

    await createActivityLogEntry({ 
      action: 'ACCOUNT_UPDATED', 
      entityType: 'Account', 
      entityId: updated.id, 
      description: `Account updated by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });

    res.json(updated);
  } catch (err) {
    console.error('Update account error:', err);
    res.status(500).json({ message: err.message });
  }
});

// DELETE /:id - Delete account
router.delete('/:id', authorize(['DELETE_ACCOUNTS']), async (req, res) => {
  try {
    const del = await prisma.account.deleteMany({ 
      where: { id: req.params.id, organizationId: req.organizationId } 
    });
    
    if (del.count === 0) return res.status(404).json({ message: 'Account not found' });
    
    await createActivityLogEntry({ 
      action: 'ACCOUNT_DELETED', 
      entityType: 'Account', 
      entityId: req.params.id, 
      description: `Account deleted by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });

    res.json({ message: 'Account deleted' });
  } catch (err) {
    console.error('Delete account error:', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
