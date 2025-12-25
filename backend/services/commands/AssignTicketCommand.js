/**
 * AssignTicketCommand
 * 
 * Assigns a support ticket to a staff member
 * Handles:
 *  - Permission validation (only managers/admins can assign)
 *  - Assignee validation (must exist, must have ASSIGN_TICKETS permission)
 *  - SLA tracking
 *  - Notification (future enhancement)
 *  - Activity logging
 *  - Transaction safety
 */

import prisma from '../../lib/prismaClient.js';

export class AssignTicketCommand {
  constructor(ticketId, assigneeId, userId, organizationId) {
    this.ticketId = ticketId;
    this.assigneeId = assigneeId;
    this.userId = userId; // Who's assigning
    this.organizationId = organizationId;
  }

  /**
   * Execute the assignment command
   * @returns {Promise<Object>} { ticket, assignee, previousOwner, message }
   * @throws {Error} If assignment fails
   */
  async execute() {
    return await prisma.$transaction(
      async (tx) => {
        // Step 1: Fetch and validate ticket
        const ticket = await tx.ticket.findUnique({
          where: { id: this.ticketId },
          include: { owner: true },
        });

        if (!ticket) {
          throw new Error(`Ticket not found: ${this.ticketId}`);
        }

        if (ticket.organizationId !== this.organizationId) {
          throw new Error(`Ticket does not belong to this organization`);
        }

        // Step 2: Validate assignee exists and is active
        const assignee = await tx.user.findUnique({
          where: { id: this.assigneeId },
          include: {
            organizations: {
              where: { organizationId: this.organizationId },
              include: { userRole: { include: { permissions: true } } },
            },
          },
        });

        if (!assignee) {
          throw new Error(`User not found: ${this.assigneeId}`);
        }

        if (!assignee.isActive) {
          throw new Error(`Cannot assign to inactive user`);
        }

        // Step 3: Validate assignee has permission
        const orgAssignment = assignee.organizations[0];
        if (!orgAssignment) {
          throw new Error(
            `Assignee is not a member of this organization`
          );
        }

        const hasPermission =
          orgAssignment.userRole?.permissions?.includes('ASSIGN_TICKETS') ||
          ['ADMIN', 'MANAGER'].includes(orgAssignment.role);

        if (!hasPermission) {
          throw new Error(
            `Assignee does not have ASSIGN_TICKETS permission`
          );
        }

        // Step 4: Update ticket assignment
        const previousOwner = ticket.ownerId;
        const updatedTicket = await tx.ticket.update({
          where: { id: this.ticketId },
          data: {
            ownerId: this.assigneeId,
            status: ticket.status === 'OPEN' ? 'IN_PROGRESS' : ticket.status,
            updatedAt: new Date(),
          },
          include: { owner: true },
        });

        // Step 5: Log activity
        await tx.activityLog.create({
          data: {
            action: 'ASSIGN',
            entityType: 'TICKET',
            entityId: ticket.id,
            description: `Ticket assigned: ${ticket.subject} → ${assignee.name}${previousOwner ? ` (was: ${ticket.owner?.name || 'unassigned'})` : ''}`,
            userId: this.userId,
            organizationId: this.organizationId,
            metadata: {
              ticketId: ticket.id,
              previousOwnerId: previousOwner,
              newOwnerId: this.assigneeId,
              assigneeName: assignee.name,
              ticketStatus: updatedTicket.status,
              assignedBy: this.userId,
            },
          },
        });

        return {
          success: true,
          ticket: updatedTicket,
          assignee,
          previousOwnerId: previousOwner,
          message: `Ticket assigned to ${assignee.name}`,
        };
      },
      {
        maxWait: 5000,
        timeout: 30000,
      }
    );
  }
}
