/**
 * Admin Customer Management Routes
 * Manage customer-to-organization assignments
 */

const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const {
  assignCustomerToOrganization,
  getUnassignedCustomers,
  getCustomersByOrganization,
} = require('../lib/organizationMatcher');

const prisma = new PrismaClient();

/**
 * GET /api/admin/customers/unassigned
 * Get all unassigned customers (no organization)
 */
router.get('/unassigned', async (req, res) => {
  try {
    const customers = await getUnassignedCustomers();
    res.json({
      success: true,
      count: customers.length,
      customers: customers.map(profile => ({
        id: profile.id,
        userId: profile.user.id,
        name: profile.user.name,
        email: profile.user.email,
        companyName: profile.companyName,
        phone: profile.phone,
        createdAt: profile.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting unassigned customers:', error);
    res.status(500).json({ error: 'Failed to get unassigned customers' });
  }
});

/**
 * GET /api/admin/customers/by-organization/:organizationId
 * Get customers by organization
 */
router.get('/by-organization/:organizationId', async (req, res) => {
  try {
    const { organizationId } = req.params;
    const customers = await getCustomersByOrganization(organizationId);
    
    res.json({
      success: true,
      organizationId,
      count: customers.length,
      customers: customers.map(profile => ({
        id: profile.id,
        userId: profile.user.id,
        name: profile.user.name,
        email: profile.user.email,
        companyName: profile.companyName,
        phone: profile.phone,
        assignedAt: profile.assignedAt,
        createdAt: profile.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting customers by organization:', error);
    res.status(500).json({ error: 'Failed to get customers' });
  }
});

/**
 * POST /api/admin/customers/:userId/assign-organization
 * Assign customer to organization
 */
router.post('/:userId/assign-organization', async (req, res) => {
  try {
    const { userId } = req.params;
    const { organizationId } = req.body;
    const adminUserId = req.user?.id; // Assuming middleware sets req.user

    if (!organizationId) {
      return res.status(400).json({ error: 'Organization ID is required' });
    }

    // Verify customer exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true },
    });

    if (!user || user.type !== 'CUSTOMER') {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Verify organization exists
    const organization = await prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      return res.status(404).json({ error: 'Organization not found' });
    }

    // Assign customer
    const updatedProfile = await assignCustomerToOrganization(
      userId,
      organizationId,
      adminUserId
    );

    res.json({
      success: true,
      message: `Customer assigned to ${organization.name}`,
      profile: {
        id: updatedProfile.id,
        userId: updatedProfile.userId,
        organizationId: updatedProfile.organizationId,
        organizationName: organization.name,
        assignedAt: updatedProfile.assignedAt,
      },
    });
  } catch (error) {
    console.error('Error assigning customer:', error);
    res.status(500).json({ error: 'Failed to assign customer' });
  }
});

/**
 * POST /api/admin/customers/:userId/unassign-organization
 * Remove customer from organization
 */
router.post('/:userId/unassign-organization', async (req, res) => {
  try {
    const { userId } = req.params;
    const adminUserId = req.user?.id;

    // Verify customer exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true },
    });

    if (!user || user.type !== 'CUSTOMER') {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Unassign customer
    const updatedProfile = await assignCustomerToOrganization(
      userId,
      null,
      adminUserId
    );

    res.json({
      success: true,
      message: 'Customer unassigned from organization',
      profile: {
        id: updatedProfile.id,
        userId: updatedProfile.userId,
        organizationId: null,
      },
    });
  } catch (error) {
    console.error('Error unassigning customer:', error);
    res.status(500).json({ error: 'Failed to unassign customer' });
  }
});

/**
 * POST /api/admin/customers/bulk-assign
 * Bulk assign multiple customers to an organization
 */
router.post('/bulk-assign', async (req, res) => {
  try {
    const { userIds, organizationId } = req.body;
    const adminUserId = req.user?.id;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({ error: 'User IDs array is required' });
    }

    if (!organizationId) {
      return res.status(400).json({ error: 'Organization ID is required' });
    }

    // Verify organization exists
    const organization = await prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      return res.status(404).json({ error: 'Organization not found' });
    }

    // Assign all customers
    const results = await Promise.allSettled(
      userIds.map(userId =>
        assignCustomerToOrganization(userId, organizationId, adminUserId)
      )
    );

    const successful = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected').length;

    res.json({
      success: true,
      message: `Bulk assignment complete`,
      organizationName: organization.name,
      total: userIds.length,
      successful,
      failed,
    });
  } catch (error) {
    console.error('Error bulk assigning customers:', error);
    res.status(500).json({ error: 'Failed to bulk assign customers' });
  }
});

/**
 * GET /api/admin/customers/stats
 * Get customer assignment statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const [total, assigned, unassigned] = await Promise.all([
      prisma.customerProfile.count({
        where: { isActive: true },
      }),
      prisma.customerProfile.count({
        where: {
          isActive: true,
          organizationId: { not: null },
        },
      }),
      prisma.customerProfile.count({
        where: {
          isActive: true,
          organizationId: null,
        },
      }),
    ]);

    // Get top organizations by customer count
    const orgStats = await prisma.customerProfile.groupBy({
      by: ['organizationId'],
      where: {
        isActive: true,
        organizationId: { not: null },
      },
      _count: {
        id: true,
      },
      orderBy: {
        _count: {
          id: 'desc',
        },
      },
      take: 10,
    });

    // Get organization details
    const orgIds = orgStats.map(s => s.organizationId);
    const organizations = await prisma.organization.findMany({
      where: { id: { in: orgIds } },
      select: { id: true, name: true },
    });

    const orgMap = Object.fromEntries(organizations.map(o => [o.id, o.name]));

    res.json({
      success: true,
      stats: {
        total,
        assigned,
        unassigned,
        assignmentRate: total > 0 ? ((assigned / total) * 100).toFixed(1) : 0,
      },
      topOrganizations: orgStats.map(stat => ({
        organizationId: stat.organizationId,
        organizationName: orgMap[stat.organizationId] || 'Unknown',
        customerCount: stat._count.id,
      })),
    });
  } catch (error) {
    console.error('Error getting customer stats:', error);
    res.status(500).json({ error: 'Failed to get statistics' });
  }
});

module.exports = router;
