import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateLead } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List leads with filtering and pagination
router.get('/', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    const status = req.query.status ? String(req.query.status) : null;
    const leadSource = req.query.leadSource ? String(req.query.leadSource) : null;
    const industry = req.query.industry ? String(req.query.industry) : null;

    const where = { organizationId: req.organizationId };

    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { company: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) where.status = status;
    if (leadSource) where.leadSource = leadSource;
    if (industry) where.industry = { contains: industry, mode: 'insensitive' };

    const total = await prisma.lead.count({ where });
    const leads = await prisma.lead.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } }
      }
    });

    res.json({
      leads,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST / - Create lead
router.post('/', authorize(['CREATE_LEADS']), validateLead, async (req, res) => {
  try {
    const lead = await prisma.lead.create({
      data: {
        ...req.body,
        organizationId: req.organizationId,
        ownerId: req.body.ownerId || req.user.id
      }
    });
    res.status(201).json(lead);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get lead details
router.get('/:id', async (req, res) => {
  try {
    const lead = await prisma.lead.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } }
      }
    });
    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }
    res.json(lead);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /:id - Update lead
router.put('/:id', authorize(['EDIT_LEADS']), async (req, res) => {
  try {
    const existing = await prisma.lead.findFirst({ 
      where: { id: req.params.id, organizationId: req.organizationId } 
    });
    
    if (!existing) return res.status(404).json({ message: 'Lead not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { 
      oldValues[k] = existing[k]; 
      newValues[k] = req.body[k]; 
    });

    const updated = await prisma.lead.update({ 
      where: { id: req.params.id }, 
      data: req.body 
    });

    await createActivityLogEntry({ 
      action: 'LEAD_UPDATED', 
      entityType: 'Lead', 
      entityId: updated.id, 
      description: `Lead updated by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete lead
router.delete('/:id', authorize(['DELETE_LEADS']), async (req, res) => {
  try {
    const lead = await prisma.lead.deleteMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (lead.count === 0) {
      return res.status(404).json({ message: 'Lead not found' });
    }
    res.json({ message: 'Lead deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
