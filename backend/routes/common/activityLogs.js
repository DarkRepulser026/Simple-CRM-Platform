import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';

const router = express.Router();

// Apply middleware
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List activity logs
router.get('/', authorize(['VIEW_AUDIT_LOGS']), async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const entityType = req.query.entityType ? String(req.query.entityType) : null;
    const entityId = req.query.entityId ? String(req.query.entityId) : null;
    const userId = req.query.userId ? String(req.query.userId) : null;
    const search = req.query.search ? String(req.query.search) : null;
    
    const filters = { where: { organizationId: req.organizationId } };
    const whereClauses = [];
    if (entityType) whereClauses.push({ entityType });
    if (entityId) whereClauses.push({ entityId });
    if (userId) whereClauses.push({ userId });
    if (search) {
      whereClauses.push({ description: { contains: search, mode: 'insensitive' } });
    }
    if (whereClauses.length > 0) filters.where.AND = whereClauses;

    const total = await prisma.activityLog.count(filters);
    const logs = await prisma.activityLog.findMany({
      ...filters,
      include: { user: { select: { id: true, email: true, name: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });

    const mapped = await Promise.all(logs.map(async (l) => {
      let entityName = null;
      if (l.entityType === 'Account') {
        try {
          const acc = await prisma.account.findUnique({ where: { id: l.entityId } });
          entityName = acc ? acc.name : null;
        } catch (e) {
          entityName = null;
        }
      }
      return {
        id: l.id,
        activityType: l.action || 'Other',
        description: l.description,
        userId: l.userId,
        userName: l.user ? l.user.name || l.user.email : null,
        entityId: l.entityId,
        entityType: l.entityType,
        entityName,
        organizationId: l.organizationId,
        metadata: l.metadata || null,
        oldValues: l.metadata && l.metadata.oldValues ? l.metadata.oldValues : null,
        newValues: l.metadata && l.metadata.newValues ? l.metadata.newValues : null,
        createdAt: l.createdAt,
      };
    }));

    res.json({ 
      logs: mapped, 
      pagination: { 
        page, 
        limit, 
        total, 
        totalPages: Math.ceil(total / limit), 
        hasNext: page * limit < total, 
        hasPrev: page > 1 
      } 
    });
  } catch (err) {
    console.error('List activity logs error:', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
