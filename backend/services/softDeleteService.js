// Phase 4: Soft Delete Service
// Implements archive/restore functionality instead of hard deletes
// Maintains audit trail in ActivityLog (immutable)

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Soft-delete a lead (archive it)
 * @param {string} leadId - Lead to archive
 * @param {string} userId - User performing deletion
 * @param {string} organizationId - Organization context
 * @param {string} reason - Reason for deletion
 */
export async function softDeleteLead(leadId, userId, organizationId, reason = '') {
  return await prisma.$transaction(async (tx) => {
    // Verify ownership
    const lead = await tx.lead.findUnique({
      where: { id: leadId },
      select: { id: true, organizationId: true, status: true, email: true }
    });

    if (!lead) {
      throw new Error('Lead not found');
    }

    if (lead.organizationId !== organizationId) {
      throw new Error('Lead does not belong to this organization');
    }

    // Update lead - set deletedAt
    const updatedLead = await tx.lead.update({
      where: { id: leadId },
      data: {
        deletedAt: new Date(),
        status: 'UNQUALIFIED' // Move to terminal state
      }
    });

    // Log activity (immutable audit trail)
    await tx.activityLog.create({
      data: {
        action: 'SOFT_DELETE',
        entityType: 'LEAD',
        entityId: leadId,
        description: `Lead archived: ${lead.email}`,
        userId,
        organizationId,
        metadata: {
          deletedAt: new Date(),
          reason: reason || 'No reason provided',
          previousStatus: lead.status,
          deletedByUserId: userId
        }
      }
    });

    return {
      success: true,
      lead: updatedLead,
      message: `Lead "${lead.email}" archived successfully`
    };
  });
}

/**
 * Restore a soft-deleted lead
 * @param {string} leadId - Lead to restore
 * @param {string} userId - User performing restore
 * @param {string} organizationId - Organization context
 */
export async function restoreLead(leadId, userId, organizationId) {
  return await prisma.$transaction(async (tx) => {
    const lead = await tx.lead.findUnique({
      where: { id: leadId },
      select: { id: true, organizationId: true, deletedAt: true, email: true }
    });

    if (!lead) {
      throw new Error('Lead not found');
    }

    if (lead.organizationId !== organizationId) {
      throw new Error('Lead does not belong to this organization');
    }

    if (!lead.deletedAt) {
      throw new Error('Lead is not archived');
    }

    const restoredLead = await tx.lead.update({
      where: { id: leadId },
      data: {
        deletedAt: null,
        status: 'QUALIFIED' // Restore to last valid state
      }
    });

    await tx.activityLog.create({
      data: {
        action: 'RESTORE',
        entityType: 'LEAD',
        entityId: leadId,
        description: `Lead restored: ${lead.email}`,
        userId,
        organizationId,
        metadata: {
          restoredAt: new Date(),
          wasDeletdAt: lead.deletedAt,
          restoredByUserId: userId
        }
      }
    });

    return {
      success: true,
      lead: restoredLead,
      message: `Lead "${lead.email}" restored successfully`
    };
  });
}

/**
 * Soft-delete an account (archive it)
 */
export async function softDeleteAccount(accountId, userId, organizationId, reason = '') {
  return await prisma.$transaction(async (tx) => {
    const account = await tx.account.findUnique({
      where: { id: accountId },
      select: { id: true, organizationId: true, name: true }
    });

    if (!account) {
      throw new Error('Account not found');
    }

    if (account.organizationId !== organizationId) {
      throw new Error('Account does not belong to this organization');
    }

    const updatedAccount = await tx.account.update({
      where: { id: accountId },
      data: { deletedAt: new Date() }
    });

    // Also soft-delete related contacts (cascade)
    await tx.contact.updateMany({
      where: { accountId },
      data: { deletedAt: new Date() }
    });

    // Also soft-delete related tasks (cascade)
    await tx.task.updateMany({
      where: { accountId },
      data: { deletedAt: new Date() }
    });

    await tx.activityLog.create({
      data: {
        action: 'SOFT_DELETE',
        entityType: 'ACCOUNT',
        entityId: accountId,
        description: `Account archived: ${account.name} (and ${await tx.contact.count({ where: { accountId } })} contacts, ${await tx.task.count({ where: { accountId } })} tasks)`,
        userId,
        organizationId,
        metadata: {
          deletedAt: new Date(),
          reason: reason || 'No reason provided',
          cascadeDeleted: {
            contacts: 'cascaded',
            tasks: 'cascaded'
          }
        }
      }
    });

    return {
      success: true,
      account: updatedAccount,
      message: `Account "${account.name}" and related data archived`
    };
  });
}

/**
 * Soft-delete a contact (archive it)
 */
export async function softDeleteContact(contactId, userId, organizationId, reason = '') {
  return await prisma.$transaction(async (tx) => {
    const contact = await tx.contact.findUnique({
      where: { id: contactId },
      select: { id: true, organizationId: true, firstName: true, lastName: true }
    });

    if (!contact) {
      throw new Error('Contact not found');
    }

    if (contact.organizationId !== organizationId) {
      throw new Error('Contact does not belong to this organization');
    }

    const updatedContact = await tx.contact.update({
      where: { id: contactId },
      data: { deletedAt: new Date() }
    });

    // Also soft-delete related tasks
    await tx.task.updateMany({
      where: { contactId },
      data: { deletedAt: new Date() }
    });

    const contactName = `${contact.firstName} ${contact.lastName}`;

    await tx.activityLog.create({
      data: {
        action: 'SOFT_DELETE',
        entityType: 'CONTACT',
        entityId: contactId,
        description: `Contact archived: ${contactName}`,
        userId,
        organizationId,
        metadata: {
          deletedAt: new Date(),
          reason: reason || 'No reason provided',
          cascadeDeleted: { tasks: 'cascaded' }
        }
      }
    });

    return {
      success: true,
      contact: updatedContact,
      message: `Contact "${contactName}" archived`
    };
  });
}

/**
 * Soft-delete a task (cancel it)
 */
export async function softDeleteTask(taskId, userId, organizationId, reason = '') {
  return await prisma.$transaction(async (tx) => {
    const task = await tx.task.findUnique({
      where: { id: taskId },
      select: { id: true, organizationId: true, subject: true, status: true }
    });

    if (!task) {
      throw new Error('Task not found');
    }

    if (task.organizationId !== organizationId) {
      throw new Error('Task does not belong to this organization');
    }

    const updatedTask = await tx.task.update({
      where: { id: taskId },
      data: {
        deletedAt: new Date(),
        cancelledAt: new Date(),
        cancellationReason: reason,
        status: 'CANCELLED'
      }
    });

    await tx.activityLog.create({
      data: {
        action: 'SOFT_DELETE',
        entityType: 'TASK',
        entityId: taskId,
        description: `Task cancelled: ${task.subject}`,
        userId,
        organizationId,
        metadata: {
          deletedAt: new Date(),
          cancelledAt: new Date(),
          cancellationReason: reason || 'No reason provided',
          previousStatus: task.status
        }
      }
    });

    return {
      success: true,
      task: updatedTask,
      message: `Task "${task.subject}" cancelled`
    };
  });
}

/**
 * Get deletion history for an entity (audit trail)
 */
export async function getDeletionHistory(entityType, entityId, organizationId) {
  const activities = await prisma.activityLog.findMany({
    where: {
      entityType,
      entityId,
      organizationId,
      action: { in: ['SOFT_DELETE', 'RESTORE'] }
    },
    include: {
      user: {
        select: { id: true, name: true, email: true }
      }
    },
    orderBy: { createdAt: 'desc' }
  });

  return {
    entityType,
    entityId,
    history: activities.map(a => ({
      action: a.action,
      performedBy: a.user?.name || 'Unknown',
      performedByEmail: a.user?.email,
      timestamp: a.createdAt,
      reason: a.metadata?.reason || a.metadata?.cancellationReason || 'N/A',
      details: a.metadata
    }))
  };
}

/**
 * Permanently delete soft-deleted records (GDPR right-to-be-forgotten)
 * Only allowed by ADMIN role with explicit confirmation
 */
export async function permanentlyDeleteSoftDeleted(entityType, entityId, userId, organizationId, adminConfirmation = false) {
  if (!adminConfirmation) {
    throw new Error('Admin confirmation required for permanent deletion');
  }

  return await prisma.$transaction(async (tx) => {
    let deleted;

    switch (entityType) {
      case 'LEAD':
        deleted = await tx.lead.delete({
          where: { id: entityId }
        });
        break;
      case 'ACCOUNT':
        // Delete cascade: contacts, tasks
        await tx.contact.deleteMany({
          where: { accountId: entityId }
        });
        await tx.task.deleteMany({
          where: { accountId: entityId }
        });
        deleted = await tx.account.delete({
          where: { id: entityId }
        });
        break;
      case 'CONTACT':
        await tx.task.deleteMany({
          where: { contactId: entityId }
        });
        deleted = await tx.contact.delete({
          where: { id: entityId }
        });
        break;
      case 'TASK':
        deleted = await tx.task.delete({
          where: { id: entityId }
        });
        break;
      default:
        throw new Error('Invalid entity type');
    }

    // Log permanent deletion (immutable)
    await tx.activityLog.create({
      data: {
        action: 'PERMANENT_DELETE',
        entityType,
        entityId,
        description: `Permanently deleted (GDPR): ${entityType} #${entityId}`,
        userId,
        organizationId,
        metadata: {
          permanentlyDeletedAt: new Date(),
          gdprRequest: true,
          deletedByUserId: userId
        }
      }
    });

    return {
      success: true,
      message: `${entityType} #${entityId} permanently deleted (GDPR)`
    };
  });
}

export default {
  softDeleteLead,
  restoreLead,
  softDeleteAccount,
  softDeleteContact,
  softDeleteTask,
  getDeletionHistory,
  permanentlyDeleteSoftDeleted
};
