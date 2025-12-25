/**
 * Ticket Permission Middleware
 * 
 * Enforces UX rules from ARCHITECTURE_PATTERNS.md:
 * 
 * Permission logic (critical):
 * 
 * 👤 Agent:
 *   - Reply
 *   - Change status (limited transitions)
 * 
 * 👔 Manager+:
 *   - Reassign ticket
 *   - Override status
 *   - Escalate / Close forcibly
 */

import prisma from '../lib/prismaClient.js';

/**
 * Valid ticket status transitions based on role
 */
const TICKET_STATUS_TRANSITIONS = {
  AGENT: {
    OPEN: ['IN_PROGRESS', 'WAITING_ON_CUSTOMER'],
    IN_PROGRESS: ['WAITING_ON_CUSTOMER', 'RESOLVED'],
    WAITING_ON_CUSTOMER: ['IN_PROGRESS', 'RESOLVED'],
    RESOLVED: ['CLOSED'], // Agent can only close after resolved
    CLOSED: [], // No transitions from closed for agents
  },
  MANAGER: {
    // Managers can make any transition
    OPEN: ['IN_PROGRESS', 'WAITING_ON_CUSTOMER', 'RESOLVED', 'CLOSED'],
    IN_PROGRESS: ['OPEN', 'WAITING_ON_CUSTOMER', 'RESOLVED', 'CLOSED'],
    WAITING_ON_CUSTOMER: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
    RESOLVED: ['OPEN', 'IN_PROGRESS', 'CLOSED'],
    CLOSED: ['OPEN'], // Managers can reopen
  },
  ADMIN: {
    // Admins can make any transition
    OPEN: ['IN_PROGRESS', 'WAITING_ON_CUSTOMER', 'RESOLVED', 'CLOSED'],
    IN_PROGRESS: ['OPEN', 'WAITING_ON_CUSTOMER', 'RESOLVED', 'CLOSED'],
    WAITING_ON_CUSTOMER: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
    RESOLVED: ['OPEN', 'IN_PROGRESS', 'CLOSED'],
    CLOSED: ['OPEN'],
  }
};

/**
 * Middleware to enforce ticket status transition rules
 * 
 * 👤 Agent: Limited transitions
 * 👔 Manager+: All transitions allowed
 * 
 * Usage:
 *   router.put('/:id/status', enforceTicketStatusTransitions, updateStatusHandler)
 */
export async function enforceTicketStatusTransitions(req, res, next) {
  try {
    const ticketId = req.params.id || req.params.ticketId;
    const newStatus = req.body.status;

    if (!ticketId || !newStatus) {
      return next();
    }

    // Get current ticket
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: ticketId,
        organizationId: req.organizationId
      },
      select: {
        id: true,
        subject: true,
        status: true,
        ownerId: true
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const currentStatus = ticket.status;
    const userRole = req.user?.role || req.organizationRole || 'AGENT';

    // If status hasn't changed, allow
    if (currentStatus === newStatus) {
      return next();
    }

    // Get allowed transitions for this role
    const roleTransitions = TICKET_STATUS_TRANSITIONS[userRole] || TICKET_STATUS_TRANSITIONS.AGENT;
    const allowedTransitions = roleTransitions[currentStatus] || [];

    // Check if transition is allowed
    if (!allowedTransitions.includes(newStatus)) {
      return res.status(403).json({
        message: 'Status transition not allowed',
        code: 'INVALID_STATUS_TRANSITION',
        details: {
          currentStatus,
          requestedStatus: newStatus,
          allowedTransitions,
          userRole,
          hint: userRole === 'AGENT' 
            ? 'Agents have limited status transitions. Contact a Manager to override.'
            : 'This transition is not permitted.'
        }
      });
    }

    next();
  } catch (error) {
    console.error('enforceTicketStatusTransitions error:', error);
    res.status(500).json({ message: 'Error checking ticket status transition' });
  }
}

/**
 * Middleware to enforce ticket reassignment permissions
 * 
 * 👤 Agent: Cannot reassign
 * 👔 Manager+: Can reassign
 * 
 * Usage:
 *   router.put('/:id/assign', enforceTicketReassignment, reassignHandler)
 */
export async function enforceTicketReassignment(req, res, next) {
  try {
    const ticketId = req.params.id || req.params.ticketId;
    const newOwnerId = req.body.ownerId;

    if (!ticketId || !newOwnerId) {
      return next();
    }

    const userRole = req.user?.role || req.organizationRole || 'AGENT';

    // Only MANAGER and ADMIN can reassign tickets
    if (userRole === 'AGENT' || userRole === 'VIEWER') {
      return res.status(403).json({
        message: 'Permission denied',
        code: 'REASSIGNMENT_NOT_ALLOWED',
        details: {
          userRole,
          message: 'Only Managers and Admins can reassign tickets.',
          hint: 'Contact your manager if this ticket needs to be reassigned.'
        }
      });
    }

    next();
  } catch (error) {
    console.error('enforceTicketReassignment error:', error);
    res.status(500).json({ message: 'Error checking reassignment permissions' });
  }
}

/**
 * Middleware to enforce ticket reply permissions
 * 
 * 👤 All authenticated users can reply
 * 🔒 Internal notes restricted to staff only
 * 
 * Usage:
 *   router.post('/:id/messages', enforceTicketReplyPermissions, createMessageHandler)
 */
export async function enforceTicketReplyPermissions(req, res, next) {
  try {
    const isInternal = req.body.isInternal;
    const userType = req.user?.type || 'STAFF';

    // If it's an internal note, only STAFF can create it
    if (isInternal && userType !== 'STAFF') {
      return res.status(403).json({
        message: 'Permission denied',
        code: 'INTERNAL_NOTE_NOT_ALLOWED',
        details: {
          message: 'Only staff members can create internal notes.',
        }
      });
    }

    next();
  } catch (error) {
    console.error('enforceTicketReplyPermissions error:', error);
    res.status(500).json({ message: 'Error checking reply permissions' });
  }
}

/**
 * Middleware to enforce ticket closure permissions
 * 
 * 👤 Agent: Can close only if status is RESOLVED
 * 👔 Manager+: Can forcibly close at any time
 * 
 * Usage:
 *   router.post('/:id/close', enforceTicketClosure, closeHandler)
 */
export async function enforceTicketClosure(req, res, next) {
  try {
    const ticketId = req.params.id || req.params.ticketId;
    const userRole = req.user?.role || req.organizationRole || 'AGENT';

    // Get current ticket
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: ticketId,
        organizationId: req.organizationId
      },
      select: {
        id: true,
        status: true
      }
    });

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    // Agents can only close if ticket is already RESOLVED
    if (userRole === 'AGENT' && ticket.status !== 'RESOLVED') {
      return res.status(403).json({
        message: 'Cannot close ticket',
        code: 'PREMATURE_CLOSURE',
        details: {
          currentStatus: ticket.status,
          message: 'Agents can only close tickets that are already marked as RESOLVED.',
          hint: 'First change the ticket status to RESOLVED, then close it. Or ask a Manager to forcibly close it.'
        }
      });
    }

    next();
  } catch (error) {
    console.error('enforceTicketClosure error:', error);
    res.status(500).json({ message: 'Error checking closure permissions' });
  }
}

/**
 * Middleware to validate ticket assignee
 * Only Agents can be assigned tickets (not Admins or Managers - they are supervisory)
 * 
 * Usage:
 *   router.post('/', validateTicketAssignee, createHandler)
 *   router.put('/:id/assign', validateTicketAssignee, assignHandler)
 */
export async function validateTicketAssignee(req, res, next) {
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
    
    // Only AGENT role can be assigned tickets
    if (userOrg.role !== 'AGENT') {
      return res.status(400).json({
        message: 'Invalid assignment',
        code: 'INVALID_TICKET_ASSIGNEE',
        details: {
          message: 'Tickets can only be assigned to Agents',
          assigneeRole: userOrg.role,
          assigneeName: userOrg.user.name,
          hint: 'Admins and Managers are supervisory roles. Select an Agent from the dropdown.'
        }
      });
    }
    
    next();
  } catch (error) {
    console.error('validateTicketAssignee error:', error);
    res.status(500).json({ message: 'Error validating assignee' });
  }
}

/**
 * Utility function to check if user can modify a specific ticket
 */
export async function canModifyTicket(ticketId, userId, userRole, organizationId) {
  const ticket = await prisma.ticket.findFirst({
    where: {
      id: ticketId,
      organizationId
    },
    select: {
      ownerId: true
    }
  });

  if (!ticket) {
    return false;
  }

  // ADMIN and MANAGER can modify any ticket
  if (userRole === 'ADMIN' || userRole === 'MANAGER') {
    return true;
  }

  // AGENT can only modify their own tickets
  if (userRole === 'AGENT') {
    return ticket.ownerId === userId;
  }

  // VIEWER cannot modify tickets
  return false;
}
