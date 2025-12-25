/**
 * CloseTicketCommand
 * 
 * Closes a resolved support ticket
 * Handles:
 *  - State transition validation (RESOLVED → CLOSED)
 *  - SLA tracking and closure metrics
 *  - Resolution notes
 *  - Activity logging
 *  - Customer notification (future)
 *  - Transactional safety
 */

import prisma from '../../lib/prismaClient.js';
import { validateTicketTransition } from '../validators/stateMachineValidator.js';

export class CloseTicketCommand {
  constructor(ticketId, userId, organizationId, resolutionNotes = null) {
    this.ticketId = ticketId;
    this.userId = userId;
    this.organizationId = organizationId;
    this.resolutionNotes = resolutionNotes;
  }

  /**
   * Execute the close command
   * @returns {Promise<Object>} { ticket, slaMetrics, message }
   * @throws {Error} If closure fails
   */
  async execute() {
    return await prisma.$transaction(
      async (tx) => {
        // Step 1: Fetch and validate ticket
        const ticket = await tx.ticket.findUnique({
          where: { id: this.ticketId },
          include: {
            account: true,
            owner: true,
          },
        });

        if (!ticket) {
          throw new Error(`Ticket not found: ${this.ticketId}`);
        }

        if (ticket.organizationId !== this.organizationId) {
          throw new Error(`Ticket does not belong to this organization`);
        }

        // Step 2: Validate state transition
        try {
          validateTicketTransition(ticket.status, 'CLOSED', 'SYSTEM');
        } catch (err) {
          throw new Error(
            `Cannot close ticket with status ${ticket.status}. ${err.message}`
          );
        }

        // Step 3: Calculate SLA metrics
        const slaMetrics = this.calculateSLAMetrics(ticket);

        // Step 4: Update ticket to closed
        const closedTicket = await tx.ticket.update({
          where: { id: this.ticketId },
          data: {
            status: 'CLOSED',
            resolvedAt: ticket.resolvedAt || new Date(),
            updatedAt: new Date(),
          },
          include: {
            account: true,
            owner: true,
          },
        });

        // Step 5: Log closure activity
        await tx.activityLog.create({
          data: {
            action: 'CLOSE',
            entityType: 'TICKET',
            entityId: ticket.id,
            description: `Ticket closed: ${ticket.subject}${
              slaMetrics.slaMet ? ' (SLA MET)' : ' (SLA MISSED)'
            }${this.resolutionNotes ? ` - ${this.resolutionNotes}` : ''}`,
            userId: this.userId,
            organizationId: this.organizationId,
            metadata: {
              ticketId: ticket.id,
              subject: ticket.subject,
              priority: ticket.priority,
              accountId: ticket.accountId,
              accountName: ticket.account?.name,
              closedBy: this.userId,
              closureTime: new Date(),
              slaMetrics,
              resolutionNotes: this.resolutionNotes,
            },
          },
        });

        // Step 6: Create message record (if notes provided)
        if (this.resolutionNotes) {
          await tx.ticketMessage.create({
            data: {
              content: `Ticket closed: ${this.resolutionNotes}`,
              ticketId: ticket.id,
              authorId: this.userId,
              isInternal: false, // Can be seen by customer
            },
          });
        }

        return {
          success: true,
          ticket: closedTicket,
          slaMetrics,
          message: `Ticket closed successfully${slaMetrics.slaMet ? ' - SLA requirements met' : ' - SLA exceeded'}`,
        };
      },
      {
        maxWait: 5000,
        timeout: 30000,
      }
    );
  }

  /**
   * Calculate SLA metrics for ticket closure
   * @private
   */
  calculateSLAMetrics(ticket) {
    const created = new Date(ticket.createdAt);
    const closure = new Date();

    // Define SLA times (in hours)
    const slaByPriority = {
      URGENT: 2,
      HIGH: 8,
      NORMAL: 24,
      LOW: 72,
    };

    const slaHours = slaByPriority[ticket.priority] || 24;
    const responseTime = ticket.respondedAt
      ? (new Date(ticket.respondedAt).getTime() - created.getTime()) /
        (1000 * 60 * 60)
      : null;
    const resolutionTime = (closure.getTime() - created.getTime()) / (1000 * 60 * 60);

    return {
      priority: ticket.priority,
      slaHours,
      responseTimeHours: responseTime,
      resolutionTimeHours: resolutionTime,
      slaMet: resolutionTime <= slaHours,
      responseTimeMet: responseTime
        ? responseTime <= Math.ceil(slaHours / 4)
        : null,
    };
  }
}
