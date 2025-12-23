import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { authorizeGlobalAdmin } from '../../middleware/permissions.js';

const router = express.Router();

// Apply middleware
router.use(authenticateToken);

// GET / - Get all domain mappings (Global Admin)
router.get('/', authorizeGlobalAdmin(['MANAGE_USERS']), async (req, res) => {
  try {
    const mappings = await prisma.organizationDomain.findMany({
      include: {
        organization: {
          select: { id: true, name: true, isActive: true },
        },
      },
      orderBy: [
        { priority: 'desc' },
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
        isActive: m.isActive,
        autoAssign: m.autoAssign,
        priority: m.priority,
        createdAt: m.createdAt,
      })),
    });
  } catch (error) {
    console.error('Error getting domain mappings:', error);
    res.status(500).json({ error: 'Failed to get domain mappings' });
  }
});

export default router;
