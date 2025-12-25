/**
 * Admin Domain Mapping Management Routes
 * Maps email domains to accounts for lead conversion
 */

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/**
 * GET /api/admin/domain-mappings
 * Get all domain mappings across all organizations
 */
router.get('/', async (req, res) => {
  try {
    const mappings = await prisma.organizationDomain.findMany({
      include: {
        organization: {
          select: {
            id: true,
            name: true,
            isActive: true,
          },
        },
        account: {
          select: {
            id: true,
            name: true,
            domain: true,
          },
        },
      },
      orderBy: [
        { domain: 'asc' },
      ],
    });

    res.json({
      success: true,
      count: mappings.length,
      mappings: mappings.map(m => ({
        id: m.id,
        domain: m.domain,
        organizationId: m.organizationId,
        organizationName: m.organization.name,
        accountId: m.accountId,
        accountName: m.account?.name,
        verified: m.verified,
        createdAt: m.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting domain mappings:', error);
    res.status(500).json({ error: 'Failed to get domain mappings' });
  }
});

/**
 * GET /api/admin/domain-mappings/verified
 * Get only verified domain mappings (for quick reference)
 */
router.get('/verified', async (req, res) => {
  try {
    const mappings = await prisma.organizationDomain.findMany({
      where: { verified: true },
      include: {
        organization: {
          select: { id: true, name: true },
        },
        account: {
          select: { id: true, name: true },
        },
      },
      orderBy: { domain: 'asc' },
    });
    
    res.json({
      success: true,
      count: mappings.length,
      mappings: mappings.map(m => ({
        id: m.id,
        domain: m.domain,
        organizationId: m.organizationId,
        organizationName: m.organization.name,
        accountId: m.accountId,
        accountName: m.account?.name,
      })),
    });
  } catch (error) {
    console.error('Error getting verified domain mappings:', error);
    res.status(500).json({ error: 'Failed to get active domain mappings' });
  }
});

/**
 * GET /api/admin/domain-mappings/organization/:organizationId
 * Get domain mappings for a specific organization
 */
router.get('/organization/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    const mappings = await prisma.organizationDomain.findMany({
      where: { organizationId },
      include: {
        account: {
          select: {
            id: true,
            name: true,
            domain: true,
          },
        },
      },
      orderBy: { domain: 'asc' },
    });

    res.json({
      success: true,
      organizationId,
      count: mappings.length,
      mappings,
    });
  } catch (error) {
    console.error('Error getting organization domains:', error);
    res.status(500).json({ error: 'Failed to get organization domains' });
  }
});

/**
 * POST /api/admin/domain-mappings
 * Create a new domain mapping
 */
router.post('/', async (req, res) => {
  try {
    const { organizationId, accountId, domain, verified = false } = req.body;
    const adminUserId = req.user?.id;

    // Validation
    if (!organizationId || !domain) {
      return res.status(400).json({ error: 'Organization ID and domain are required' });
    }

    // Validate domain format
    const domainRegex = /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$/i;
    if (!domainRegex.test(domain.trim())) {
      return res.status(400).json({ error: 'Invalid domain format' });
    }

    // Check if organization exists
    const organization = await prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      return res.status(404).json({ error: 'Organization not found' });
    }

    // Check if account exists (if provided)
    if (accountId) {
      const account = await prisma.account.findUnique({
        where: { id: accountId },
      });

      if (!account) {
        return res.status(404).json({ error: 'Account not found' });
      }

      if (account.organizationId !== organizationId) {
        return res.status(400).json({ error: 'Account does not belong to this organization' });
      }
    }

    // Check if domain already exists for this organization
    const existing = await prisma.organizationDomain.findUnique({
      where: { 
        domain_organizationId: {
          domain: domain.toLowerCase().trim(),
          organizationId: organizationId
        }
      },
    });

    if (existing) {
      return res.status(409).json({ 
        error: 'Domain already mapped in this organization',
        existingMapping: {
          domain: existing.domain,
          accountId: existing.accountId,
        },
      });
    }

    // Create mapping
    const mapping = await prisma.organizationDomain.create({
      data: {
        organizationId,
        accountId,
        domain: domain.toLowerCase().trim(),
        verified,
        createdBy: adminUserId,
      },
      include: {
        organization: {
          select: {
            id: true,
            name: true,
          },
        },
        account: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    // Log the action
    await prisma.activityLog.create({
      data: {
        action: 'DOMAIN_MAPPING_CREATED',
        entityType: 'OrganizationDomain',
        entityId: mapping.id,
        description: `Domain ${mapping.domain} mapped to ${mapping.account?.name || 'no account'}`,
        userId: adminUserId,
        organizationId,
        metadata: {
          domain: mapping.domain,
          accountId: mapping.accountId,
        },
      },
    });

    res.status(201).json({
      success: true,
      message: 'Domain mapping created',
      mapping: {
        id: mapping.id,
        domain: mapping.domain,
        organizationId: mapping.organizationId,
        organizationName: mapping.organization.name,
        accountId: mapping.accountId,
        accountName: mapping.account?.name,
        verified: mapping.verified,
      },
    });
  } catch (error) {
    console.error('Error creating domain mapping:', error);
    res.status(500).json({ error: 'Failed to create domain mapping' });
  }
});

/**
 * PATCH /api/admin/domain-mappings/:id
 * Update domain mapping (toggle active/autoAssign, change priority)
 */
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive, autoAssign, priority } = req.body;
    const adminUserId = req.user?.id;

    // Get existing mapping
    const existing = await prisma.organizationDomain.findUnique({
      where: { id },
      include: {
        organization: true,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Domain mapping not found' });
    }

    // Build update data
    const updateData = {};
    if (isActive !== undefined) updateData.isActive = isActive;
    if (autoAssign !== undefined) updateData.autoAssign = autoAssign;
    if (priority !== undefined) updateData.priority = priority;

    // Update mapping
    const updated = await prisma.organizationDomain.update({
      where: { id },
      data: updateData,
      include: {
        organization: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    // Log the action
    await prisma.activityLog.create({
      data: {
        action: 'DOMAIN_MAPPING_UPDATED',
        entityType: 'OrganizationDomain',
        entityId: updated.id,
        description: `Domain mapping ${updated.domain} updated`,
        userId: adminUserId,
        organizationId: updated.organizationId,
        metadata: {
          changes: updateData,
        },
      },
    });

    res.json({
      success: true,
      message: 'Domain mapping updated',
      mapping: {
        id: updated.id,
        domain: updated.domain,
        organizationId: updated.organizationId,
        organizationName: updated.organization.name,
        isActive: updated.isActive,
        autoAssign: updated.autoAssign,
        priority: updated.priority,
      },
    });
  } catch (error) {
    console.error('Error updating domain mapping:', error);
    res.status(500).json({ error: 'Failed to update domain mapping' });
  }
});

/**
 * DELETE /api/admin/domain-mappings/:id
 * Delete a domain mapping
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const adminUserId = req.user?.id;

    // Get existing mapping
    const existing = await prisma.organizationDomain.findUnique({
      where: { id },
      include: {
        organization: true,
      },
    });

    if (!existing) {
      return res.status(404).json({ error: 'Domain mapping not found' });
    }

    // Delete mapping
    await prisma.organizationDomain.delete({
      where: { id },
    });

    // Log the action
    await prisma.activityLog.create({
      data: {
        action: 'DOMAIN_MAPPING_DELETED',
        entityType: 'OrganizationDomain',
        entityId: id,
        description: `Domain mapping ${existing.domain} removed from ${existing.organization.name}`,
        userId: adminUserId,
        organizationId: existing.organizationId,
        metadata: {
          domain: existing.domain,
        },
      },
    });

    res.json({
      success: true,
      message: 'Domain mapping deleted',
    });
  } catch (error) {
    console.error('Error deleting domain mapping:', error);
    res.status(500).json({ error: 'Failed to delete domain mapping' });
  }
});

/**
 * GET /api/admin/domain-mappings/check/:domain
 * Check if a domain can be auto-assigned
 */
router.get('/check/:domain', async (req, res) => {
  try {
    const { domain } = req.params;

    const mapping = await prisma.organizationDomain.findUnique({
      where: { domain: domain.toLowerCase() },
      include: {
        organization: {
          select: {
            id: true,
            name: true,
            isActive: true,
          },
        },
      },
    });

    if (!mapping) {
      return res.json({
        success: true,
        exists: false,
        canAutoAssign: false,
      });
    }

    res.json({
      success: true,
      exists: true,
      canAutoAssign: mapping.isActive && mapping.autoAssign && mapping.organization.isActive,
      mapping: {
        id: mapping.id,
        domain: mapping.domain,
        organizationId: mapping.organizationId,
        organizationName: mapping.organization.name,
        isActive: mapping.isActive,
        autoAssign: mapping.autoAssign,
      },
    });
  } catch (error) {
    console.error('Error checking domain:', error);
    res.status(500).json({ error: 'Failed to check domain' });
  }
});

module.exports = router;
