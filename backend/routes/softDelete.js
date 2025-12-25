// Phase 4: Soft Delete Routes
// Archive/restore endpoints instead of hard deletes
// Supports GDPR right-to-be-forgotten

import express from 'express';
import {
  softDeleteLead,
  restoreLead,
  softDeleteAccount,
  softDeleteContact,
  softDeleteTask,
  getDeletionHistory,
  permanentlyDeleteSoftDeleted
} from '../services/softDeleteService.js';

const router = express.Router();

// Middleware to extract organization from auth
const requireOrganization = (req, res, next) => {
  if (!req.organizationId) {
    return res.status(401).json({ error: 'Organization context required' });
  }
  next();
};

// Middleware to require admin role for permanent deletes
const requireAdmin = (req, res, next) => {
  if (req.user?.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Admin role required' });
  }
  next();
};

// ============================================================================
// LEAD SOFT DELETE ROUTES
// ============================================================================

/**
 * POST /leads/:id/archive
 * Soft-delete (archive) a lead
 * Reason: optional query param
 */
router.post('/leads/:leadId/archive', requireOrganization, async (req, res) => {
  try {
    const { reason } = req.body;

    const result = await softDeleteLead(
      req.params.leadId,
      req.user.id,
      req.organizationId,
      reason
    );

    res.json({
      success: true,
      data: result
    });
  } catch (err) {
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    if (err.message.includes('does not belong')) {
      return res.status(403).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * POST /leads/:id/restore
 * Restore a soft-deleted (archived) lead
 */
router.post('/leads/:leadId/restore', requireOrganization, async (req, res) => {
  try {
    const result = await restoreLead(
      req.params.leadId,
      req.user.id,
      req.organizationId
    );

    res.json({
      success: true,
      data: result
    });
  } catch (err) {
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    if (err.message.includes('not archived')) {
      return res.status(400).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * GET /leads/:id/deletion-history
 * Get audit trail of deletion/restoration events
 */
router.get('/leads/:leadId/deletion-history', requireOrganization, async (req, res) => {
  try {
    const history = await getDeletionHistory('LEAD', req.params.leadId, req.organizationId);

    res.json({
      success: true,
      data: history
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// ACCOUNT SOFT DELETE ROUTES
// ============================================================================

/**
 * POST /accounts/:id/archive
 * Soft-delete account (cascades to contacts and tasks)
 */
router.post('/accounts/:accountId/archive', requireOrganization, async (req, res) => {
  try {
    const { reason } = req.body;

    const result = await softDeleteAccount(
      req.params.accountId,
      req.user.id,
      req.organizationId,
      reason
    );

    res.json({
      success: true,
      data: result,
      _meta: {
        cascadeArchived: ['contacts', 'tasks']
      }
    });
  } catch (err) {
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * GET /accounts/:id/deletion-history
 * Get audit trail
 */
router.get('/accounts/:accountId/deletion-history', requireOrganization, async (req, res) => {
  try {
    const history = await getDeletionHistory('ACCOUNT', req.params.accountId, req.organizationId);

    res.json({
      success: true,
      data: history
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// CONTACT SOFT DELETE ROUTES
// ============================================================================

/**
 * POST /contacts/:id/archive
 * Soft-delete contact (cascades to related tasks)
 */
router.post('/contacts/:contactId/archive', requireOrganization, async (req, res) => {
  try {
    const { reason } = req.body;

    const result = await softDeleteContact(
      req.params.contactId,
      req.user.id,
      req.organizationId,
      reason
    );

    res.json({
      success: true,
      data: result,
      _meta: {
        cascadeArchived: ['tasks']
      }
    });
  } catch (err) {
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * GET /contacts/:id/deletion-history
 * Get audit trail
 */
router.get('/contacts/:contactId/deletion-history', requireOrganization, async (req, res) => {
  try {
    const history = await getDeletionHistory('CONTACT', req.params.contactId, req.organizationId);

    res.json({
      success: true,
      data: history
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// TASK SOFT DELETE ROUTES
// ============================================================================

/**
 * POST /tasks/:id/cancel
 * Soft-delete (cancel) a task
 */
router.post('/tasks/:taskId/cancel', requireOrganization, async (req, res) => {
  try {
    const { reason } = req.body;

    const result = await softDeleteTask(
      req.params.taskId,
      req.user.id,
      req.organizationId,
      reason
    );

    res.json({
      success: true,
      data: result
    });
  } catch (err) {
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * GET /tasks/:id/deletion-history
 * Get audit trail of cancellations
 */
router.get('/tasks/:taskId/deletion-history', requireOrganization, async (req, res) => {
  try {
    const history = await getDeletionHistory('TASK', req.params.taskId, req.organizationId);

    res.json({
      success: true,
      data: history
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// GDPR PERMANENT DELETE ROUTES
// ============================================================================

/**
 * DELETE /gdpr/permanent-delete
 * Permanently delete soft-deleted record (GDPR right-to-be-forgotten)
 * Requires:
 *   - Admin role
 *   - Admin confirmation flag
 *   - Audit trail in ActivityLog
 *
 * Body: { entityType, entityId, confirmation: true }
 */
router.delete('/gdpr/permanent-delete', requireOrganization, requireAdmin, async (req, res) => {
  try {
    const { entityType, entityId, confirmation } = req.body;

    if (!entityType || !entityId) {
      return res.status(400).json({
        error: 'entityType and entityId required',
        example: { entityType: 'LEAD', entityId: 'lead-123' }
      });
    }

    if (!confirmation) {
      return res.status(400).json({
        error: 'Admin confirmation required',
        requiredField: 'confirmation: true'
      });
    }

    const result = await permanentlyDeleteSoftDeleted(
      entityType,
      entityId,
      req.user.id,
      req.organizationId,
      confirmation
    );

    res.json({
      success: true,
      data: result,
      _meta: {
        gdpr: true,
        permanentlyDeleted: true,
        performedBy: req.user.email,
        timestamp: new Date()
      }
    });
  } catch (err) {
    if (err.message.includes('confirmation')) {
      return res.status(400).json({ error: err.message });
    }
    res.status(400).json({ error: err.message });
  }
});

/**
 * GET /gdpr/audit-trail
 * Get audit trail of all soft/permanent deletes
 * Query params:
 *   - entityType (optional): LEAD|ACCOUNT|CONTACT|TASK
 *   - startDate (optional): ISO date
 *   - endDate (optional): ISO date
 */
router.get('/gdpr/audit-trail', requireOrganization, async (req, res) => {
  try {
    const { entityType, startDate, endDate } = req.query;

    const where = {
      organizationId: req.organizationId,
      action: { in: ['SOFT_DELETE', 'PERMANENT_DELETE', 'RESTORE'] }
    };

    if (entityType) {
      where.entityType = entityType;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = new Date(startDate);
      }
      if (endDate) {
        where.createdAt.lte = new Date(endDate);
      }
    }

    const activities = await prisma.activityLog.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true, email: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: {
        total: activities.length,
        activities: activities.map(a => ({
          action: a.action,
          entityType: a.entityType,
          entityId: a.entityId,
          performedBy: a.user?.name || 'Unknown',
          performedByEmail: a.user?.email,
          timestamp: a.createdAt,
          reason: a.metadata?.reason || 'N/A',
          details: a.metadata
        }))
      }
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
