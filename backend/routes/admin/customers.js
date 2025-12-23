import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize, authorizeGlobalAdmin } from '../../middleware/permissions.js';
import { createActivityLogEntry } from '../../services/activityService.js';

const router = express.Router();

// Apply middleware
router.use(authenticateToken);

// GET /unassigned - Get unassigned customers (Global Admin)
router.get('/unassigned', authorizeGlobalAdmin(['MANAGE_USERS']), async (req, res) => {
  try {
    const customers = await prisma.user.findMany({
      where: {
        type: 'CUSTOMER',
        customerProfile: { organizationId: null }
      },
      include: { customerProfile: true },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      count: customers.length,
      customers: customers.map(c => ({
        id: c.id,
        userId: c.id,
        name: c.name,
        email: c.email,
        companyName: c.customerProfile?.companyName,
        phone: c.customerProfile?.phone,
        createdAt: c.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting unassigned customers:', error);
    res.status(500).json({ error: 'Failed to get unassigned customers' });
  }
});

// GET /assigned - Get assigned customers (Global Admin)
router.get('/assigned', authorizeGlobalAdmin(['MANAGE_USERS']), async (req, res) => {
  try {
    const customers = await prisma.user.findMany({
      where: {
        type: 'CUSTOMER',
        customerProfile: { organizationId: { not: null } }
      },
      include: {
        customerProfile: {
          include: { organization: { select: { id: true, name: true } } }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      count: customers.length,
      customers: customers.map(c => ({
        id: c.id,
        userId: c.id,
        name: c.name,
        email: c.email,
        companyName: c.customerProfile?.companyName,
        phone: c.customerProfile?.phone,
        organizationId: c.customerProfile?.organizationId,
        organizationName: c.customerProfile?.organization?.name,
        createdAt: c.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting assigned customers:', error);
    res.status(500).json({ error: 'Failed to get assigned customers' });
  }
});

// GET /stats - Get customer statistics (Global Admin)
router.get('/stats', authorizeGlobalAdmin(['MANAGE_USERS']), async (req, res) => {
  try {
    const total = await prisma.user.count({ where: { type: 'CUSTOMER' } });
    const assigned = await prisma.user.count({
      where: {
        type: 'CUSTOMER',
        customerProfile: { organizationId: { not: null } }
      }
    });
    const unassigned = total - assigned;
    const assignmentRate = total > 0 ? Math.round((assigned / total) * 100) : 0;

    res.json({
      success: true,
      stats: { total, assigned, unassigned, assignmentRate }
    });
  } catch (error) {
    console.error('Error getting customer stats:', error);
    res.status(500).json({ error: 'Failed to get customer statistics' });
  }
});

// GET / - Get all customers (Global Admin)
router.get('/', authorizeGlobalAdmin(['MANAGE_USERS']), async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '50', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    
    const where = { type: 'CUSTOMER' };
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { name: { contains: search, mode: 'insensitive' } },
        { customerProfile: { companyName: { contains: search, mode: 'insensitive' } } }
      ];
    }

    const total = await prisma.user.count({ where });
    const customers = await prisma.user.findMany({
      where,
      include: {
        customerProfile: {
          include: { organization: { select: { id: true, name: true } } }
        }
      },
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });

    const formattedCustomers = customers.map(c => ({
      id: c.id,
      userId: c.id,
      name: c.name,
      email: c.email,
      companyName: c.customerProfile?.companyName,
      phone: c.customerProfile?.phone,
      organizationId: c.customerProfile?.organizationId,
      organizationName: c.customerProfile?.organization?.name,
      isActive: c.isActive,
      createdAt: c.createdAt
    }));

    res.json({
      success: true,
      customers: formattedCustomers,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
    });
  } catch (error) {
    console.error('Error fetching customers:', error);
    res.status(500).json({ error: 'Failed to fetch customers' });
  }
});

// POST /:userId/assign-organization - Assign customer to org
router.post('/:userId/assign-organization', requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const { userId } = req.params;
    const { organizationId } = req.body;

    if (!organizationId) return res.status(400).json({ error: 'Organization ID is required' });

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true },
    });

    if (!user || user.type !== 'CUSTOMER') return res.status(404).json({ error: 'Customer not found' });

    const organization = await prisma.organization.findUnique({ where: { id: organizationId } });
    if (!organization) return res.status(404).json({ error: 'Organization not found' });

    const updatedProfile = await prisma.customerProfile.update({
      where: { userId },
      data: { organizationId, assignedAt: new Date() },
    });

    await createActivityLogEntry({
      action: 'CUSTOMER_ASSIGNED',
      entityType: 'CustomerProfile',
      entityId: updatedProfile.id,
      description: `Customer ${user.name} assigned to ${organization.name}`,
      userId: req.user.id,
      organizationId: req.organizationId,
    });

    res.json({
      success: true,
      message: `Customer assigned to ${organization.name}`,
      profile: {
        id: updatedProfile.id,
        userId: updatedProfile.userId,
        organizationId: updatedProfile.organizationId,
        organizationName: organization.name,
      },
    });
  } catch (error) {
    console.error('Error assigning customer:', error);
    res.status(500).json({ error: 'Failed to assign customer' });
  }
});

// POST /:userId/unassign-organization - Unassign customer from org
router.post('/:userId/unassign-organization', requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { customerProfile: true },
    });

    if (!user || user.type !== 'CUSTOMER') return res.status(404).json({ error: 'Customer not found' });

    const updatedProfile = await prisma.customerProfile.update({
      where: { userId },
      data: { organizationId: null, assignedAt: null },
    });

    await createActivityLogEntry({
      action: 'CUSTOMER_UNASSIGNED',
      entityType: 'CustomerProfile',
      entityId: updatedProfile.id,
      description: `Customer ${user.name} unassigned from organization`,
      userId: req.user.id,
      organizationId: req.organizationId,
    });

    res.json({ success: true, message: 'Customer unassigned from organization' });
  } catch (error) {
    console.error('Error unassigning customer:', error);
    res.status(500).json({ error: 'Failed to unassign customer' });
  }
});

export default router;
