/**
 * Lead Conversion Protection Middleware
 * 
 * Prevents modifications to converted leads unless user is ADMIN
 * Protects data integrity and maintains conversion as historical artifact
 */

import prisma from '../lib/prismaClient.js';

/**
 * Middleware to protect converted leads from unauthorized modifications
 * Applies to: PUT, PATCH, POST (new tasks), DELETE
 * 
 * Usage:
 *   router.put('/:leadId', protectConvertedLead, updateLeadHandler)
 *   router.post('/:leadId/tasks', protectConvertedLead, createTaskHandler)
 */
export async function protectConvertedLead(req, res, next) {
  try {
    // Support both :id and :leadId parameters
    const leadId = req.params.leadId || req.params.id;

    if (!leadId) {
      return next(); // No lead ID in route
    }

    // Skip protection for GET/HEAD (read-only)
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next();
    }

    // Fetch lead with conversion info
    const lead = await prisma.lead.findUnique({
      where: { id: leadId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        isConverted: true,
        convertedAt: true,
        convertedAccountId: true,
        convertedContactId: true,
      },
    });

    if (!lead) {
      return next(); // Lead not found, let handler deal with 404
    }

    // Check if lead is converted
    if (lead.isConverted) {
      // Allow ADMIN to modify for audit/correction purposes
      const userRole = req.user?.role || req.organizationRole;

      if (userRole !== 'ADMIN') {
        return res.status(403).json({
          error: 'Cannot modify converted lead',
          code: 'LEAD_CONVERTED',
          details: {
            leadId: lead.id,
            leadName: `${lead.firstName} ${lead.lastName}`,
            convertedAt: lead.convertedAt,
            convertedAccountId: lead.convertedAccountId,
            convertedContactId: lead.convertedContactId,
            message: 'Converted leads are read-only. Only administrators can modify converted leads for audit purposes.',
          },
        });
      }

      // Log admin override
      console.warn(
        `⚠️  ADMIN OVERRIDE: Attempt to modify converted lead ${leadId} by user ${req.user?.id}`
      );

      // Attach conversion context to request for logging
      req.leadConversionInfo = {
        isConverted: true,
        convertedAt: lead.convertedAt,
        adminOverride: true,
      };
    }

    next();
  } catch (err) {
    console.error('Error in protectConvertedLead middleware:', err);
    res.status(500).json({
      error: 'Server error checking lead status',
      code: 'LEAD_PROTECTION_ERROR',
    });
  }
}

/**
 * Middleware to block task creation on converted leads
 * 
 * Usage:
 *   router.post('/leads/:leadId/tasks', blockTasksOnConvertedLead, createTaskHandler)
 */
export async function blockTasksOnConvertedLead(req, res, next) {
  try {
    // Support both :id and :leadId parameters
    const leadId = req.params.leadId || req.params.id;

    if (!leadId) {
      return next();
    }

    const lead = await prisma.lead.findUnique({
      where: { id: leadId },
      select: {
        id: true,
        isConverted: true,
        firstName: true,
        lastName: true,
        convertedAt: true,
      },
    });

    if (!lead) {
      return next();
    }

    if (lead.isConverted) {
      return res.status(403).json({
        error: 'Cannot create tasks on converted lead',
        code: 'CONVERTED_LEAD_TASK_BLOCKED',
        details: {
          leadId: lead.id,
          leadName: `${lead.firstName} ${lead.lastName}`,
          convertedAt: lead.convertedAt,
          message:
            'This lead has been converted to a customer account. ' +
            'Create tasks on the converted account or contact instead.',
        },
      });
    }

    next();
  } catch (err) {
    console.error('Error in blockTasksOnConvertedLead middleware:', err);
    res.status(500).json({
      error: 'Server error checking lead status',
      code: 'LEAD_PROTECTION_ERROR',
    });
  }
}

/**
 * Middleware to enforce read-only access to converted leads
 * Stricter than protectConvertedLead - blocks ALL modifications
 * 
 * Usage:
 *   router.get('/leads/:leadId', readOnlyConvertedLead, getLeadHandler)
 *   router.put('/leads/:leadId', readOnlyConvertedLead, updateLeadHandler) // blocks
 */
export async function readOnlyConvertedLead(req, res, next) {
  try {
    // Support both :id and :leadId parameters
    const leadId = req.params.leadId || req.params.id;

    if (!leadId || ['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next();
    }

    const lead = await prisma.lead.findUnique({
      where: { id: leadId },
      select: {
        id: true,
        isConverted: true,
        firstName: true,
        lastName: true,
      },
    });

    if (lead?.isConverted) {
      return res.status(403).json({
        error: 'Lead is converted and read-only',
        code: 'CONVERTED_LEAD_READ_ONLY',
        details: {
          leadId: lead.id,
          leadName: `${lead.firstName} ${lead.lastName}`,
          message:
            'This lead has been converted to a customer account. ' +
            'It is now a read-only historical record.',
        },
      });
    }

    next();
  } catch (err) {
    console.error('Error in readOnlyConvertedLead middleware:', err);
    res.status(500).json({
      error: 'Server error',
      code: 'LEAD_PROTECTION_ERROR',
    });
  }
}

/**
 * Create audit log for lead conversion protection violations
 * Can be used in error handlers to track unauthorized attempts
 */
export async function logConversionViolation(leadId, userId, action, reason) {
  try {
    await prisma.activityLog.create({
      data: {
        action: 'VIOLATION',
        entityType: 'LEAD',
        entityId: leadId,
        description: `Unauthorized attempt to ${action} converted lead`,
        userId,
        metadata: {
          reason,
          timestamp: new Date().toISOString(),
        },
      },
    });
  } catch (err) {
    console.error('Error logging conversion violation:', err);
  }
}
