import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { validateOrganization } from '../../middleware/validation.js';

const router = express.Router();

// Apply middleware
router.use(authenticateToken);

// GET / - List user's organizations
router.get('/', async (req, res) => {
  try {
    const userOrganizations = await prisma.userOrganization.findMany({
      where: { userId: req.user.id },
      include: {
        organization: true
      }
    });
    const organizations = userOrganizations.map(uo => ({ ...uo.organization, role: uo.role }));
    res.json(organizations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST / - Create organization
router.post('/', validateOrganization, async (req, res) => {
  try {
    const organization = await prisma.organization.create({
      data: req.body
    });

    // Add creator as admin
    await prisma.userOrganization.create({
      data: {
        userId: req.user.id,
        organizationId: organization.id,
        role: 'ADMIN'
      }
    });

    res.status(201).json(organization);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get organization details
router.get('/:id', async (req, res) => {
  try {
    const userOrg = await prisma.userOrganization.findFirst({
      where: {
        userId: req.user.id,
        organizationId: req.params.id
      },
      include: {
        organization: true
      }
    });

    if (!userOrg) {
      return res.status(404).json({ message: 'Organization not found' });
    }

    res.json({ ...userOrg.organization, role: userOrg.role });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /:id - Update organization
router.put('/:id', async (req, res) => {
  try {
    const userOrg = await prisma.userOrganization.findFirst({
      where: {
        userId: req.user.id,
        organizationId: req.params.id,
        role: 'ADMIN'
      }
    });

    if (!userOrg) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }

    const organization = await prisma.organization.update({
      where: { id: req.params.id },
      data: req.body
    });

    res.json(organization);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete organization
router.delete('/:id', async (req, res) => {
  try {
    const userOrg = await prisma.userOrganization.findFirst({
      where: {
        userId: req.user.id,
        organizationId: req.params.id,
        role: 'ADMIN'
      }
    });

    if (!userOrg) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }

    await prisma.organization.delete({
      where: { id: req.params.id }
    });

    res.json({ message: 'Organization deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
