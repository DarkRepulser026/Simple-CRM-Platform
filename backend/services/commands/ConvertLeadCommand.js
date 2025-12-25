/**
 * ConvertLeadCommand
 * 
 * Converts a qualified lead into a customer account with contact
 * Handles:
 *  - Permission validation
 *  - Lead status verification
 *  - Account deduplication via domain matching
 *  - Contact creation
 *  - Lead update
 *  - Activity logging
 *  - Transactional integrity
 */

import prisma from '../../lib/prismaClient.js';
import { validateLeadTransition } from '../validators/stateMachineValidator.js';

export class ConvertLeadCommand {
  constructor(leadId, userId, organizationId) {
    this.leadId = leadId;
    this.userId = userId;
    this.organizationId = organizationId;
  }

  /**
   * Execute the conversion command
   * @returns {Promise<Object>} { lead, account, contact, message }
   * @throws {Error} If conversion fails
   */
  async execute() {
    return await prisma.$transaction(
      async (tx) => {
        // Step 1: Fetch and validate lead
        const lead = await tx.lead.findUnique({
          where: { id: this.leadId },
        });

        if (!lead) {
          throw new Error(`Lead not found: ${this.leadId}`);
        }

        if (lead.isConverted) {
          throw new Error(
            `Lead already converted on ${lead.convertedAt}`
          );
        }

        if (lead.organizationId !== this.organizationId) {
          throw new Error(
            `Lead does not belong to this organization`
          );
        }

        // Step 2: Validate state transition
        validateLeadTransition(lead.status, 'CONVERTED', 'SYSTEM', false);

        // Step 3: Find or create account
        const account = await this.findOrCreateAccount(lead, tx);

        // Step 4: Create contact from lead
        const contact = await tx.contact.create({
          data: {
            firstName: lead.firstName,
            lastName: lead.lastName,
            email: lead.email,
            phone: lead.phone,
            title: lead.title,
            company: lead.company,
            accountId: account.id,
            organizationId: this.organizationId,
            ownerId: lead.ownerId,
          },
        });

        // Step 5: Update lead to converted state
        const updatedLead = await tx.lead.update({
          where: { id: this.leadId },
          data: {
            status: 'CONVERTED',
            isConverted: true,
            convertedAt: new Date(),
            convertedAccountId: account.id,
            convertedContactId: contact.id,
          },
        });

        // Step 6: Log conversion activity
        await tx.activityLog.create({
          data: {
            action: 'CONVERT',
            entityType: 'LEAD',
            entityId: lead.id,
            description: `Lead converted: ${lead.firstName} ${lead.lastName} → Account: ${account.name}, Contact created`,
            userId: this.userId,
            organizationId: this.organizationId,
            metadata: {
              leadId: lead.id,
              leadCompany: lead.company,
              accountId: account.id,
              accountName: account.name,
              accountIsNew: account.createdAt === account.updatedAt,
              contactId: contact.id,
              contactName: `${contact.firstName} ${contact.lastName}`,
            },
          },
        });

        return {
          success: true,
          lead: updatedLead,
          account,
          contact,
          message: `Successfully converted ${lead.firstName} ${lead.lastName} to customer account`,
        };
      },
      {
        maxWait: 5000,
        timeout: 30000,
      }
    );
  }

  /**
   * Find existing account by domain or create new one
   * @private
   */
  async findOrCreateAccount(lead, tx) {
    // Extract domain from email
    const [, leadDomain] = lead.email.split('@');

    if (!leadDomain) {
      // No email domain, create new account
      return await tx.account.create({
        data: {
          name: lead.company,
          domain: lead.company.toLowerCase().replace(/\s+/g, '-'),
          industry: lead.industry,
          type: 'CUSTOMER',
          organizationId: this.organizationId,
          ownerId: lead.ownerId,
        },
      });
    }

    // Check if organization has domain mapping for this domain
    const domainMapping = await tx.organizationDomain.findUnique({
      where: { 
        domain_organizationId: {
          domain: leadDomain,
          organizationId: this.organizationId
        }
      },
    });

    if (domainMapping && domainMapping.accountId) {
      // Domain mapped to specific account - return that account
      const existingAccount = await tx.account.findUnique({
        where: { id: domainMapping.accountId },
      });
      
      if (existingAccount) {
        return existingAccount;
      }
    }

    // No domain mapping or mapping without account - create new account
    return await tx.account.create({
      data: {
        name: lead.company,
        domain: leadDomain,
        industry: lead.industry,
        type: 'CUSTOMER',
        organizationId: this.organizationId,
        ownerId: lead.ownerId,
      },
    });
  }
}
