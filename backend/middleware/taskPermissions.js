/**
 * Task Permission Middleware
 * 
 * Enforces ownership rules:
 * - Tasks can only be assigned to Managers and Agents (NOT Admins)
 * - Admins are supervisory and do not handle individual tasks
 */

import prisma from '../lib/prismaClient.js';

/**
 * Validates task assignee
 * Only Managers and Agents can be assigned tasks (not Admins - they are supervisory)
 * 
 * Usage:
 *   router.post('/', validateTaskAssignee, createHandler)
 *   router.put('/:id', validateTaskAssignee, updateHandler)
 */
export async function validateTaskAssignee(req, res, next) {
  try {
    const { ownerId } = req.body;
    
    if (!ownerId) {
      return next(); // Allow unassigned
    }
    
    // Check if assignee exists and get their role
    const userOrg = await prisma.userOrganization.findFirst({
      where: {
        userId: ownerId,
        organizationId: req.organizationId
      },
      include: {
        user: {
          select: { id: true, name: true, email: true }
        }
      }
    });
    
    if (!userOrg) {
      return res.status(404).json({
        message: 'User not found in organization'
      });
    }
    
    // Only MANAGER and AGENT roles can be assigned tasks (NOT ADMIN)
    if (userOrg.role !== 'MANAGER' && userOrg.role !== 'AGENT') {
      return res.status(400).json({
        message: 'Invalid assignment',
        code: 'INVALID_TASK_ASSIGNEE',
        details: {
          message: 'Tasks can only be assigned to Managers or Agents',
          assigneeRole: userOrg.role,
          assigneeName: userOrg.user.name,
          hint: 'Admins are supervisory roles and cannot be assigned tasks. Select a Manager or Agent.'
        }
      });
    }
    
    next();
  } catch (error) {
    console.error('validateTaskAssignee error:', error);
    res.status(500).json({ message: 'Error validating assignee' });
  }
}
