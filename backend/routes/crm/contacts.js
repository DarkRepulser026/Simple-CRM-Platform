import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateContact } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';

const router = express.Router();

// Apply middleware to all routes in this router
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List contacts with filtering and pagination
router.get('/', async (req, res) => {
  try {
    const { page, limit, q, ownerId, city, department } = req.query;
    const _page = parseInt(page) || 1;
    const _limit = Math.min(parseInt(limit) || 1000, 1000);
    const skip = (_page - 1) * _limit;

    const where = { organizationId: req.organizationId };
    
    if (ownerId) where.ownerId = ownerId;
    if (city) where.city = { equals: city };
    if (department) where.department = { equals: department };
    
    if (q) {
      const qStr = String(q).toLowerCase();
      where.OR = [
        { firstName: { contains: qStr, mode: 'insensitive' } },
        { lastName: { contains: qStr, mode: 'insensitive' } },
        { email: { contains: qStr, mode: 'insensitive' } },
        { phone: { contains: qStr, mode: 'insensitive' } },
        { title: { contains: qStr, mode: 'insensitive' } },
      ];
    }

    const total = await prisma.contact.count({ where });

    const contacts = await prisma.contact.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        organization: { select: { id: true, name: true } }
      },
      skip,
      take: _limit,
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      contacts,
      pagination: {
        page: _page,
        limit: _limit,
        total,
        totalPages: Math.ceil(total / _limit),
        hasNext: _page * _limit < total,
        hasPrev: _page > 1,
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST / - Create contact
router.post('/', authorize(['CREATE_CONTACTS']), validateContact, async (req, res) => {
  try {
    const contact = await prisma.contact.create({
      data: {
        ...req.body,
        organizationId: req.organizationId,
        ownerId: req.body.ownerId || req.user.id
      }
    });
    res.status(201).json(contact);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /:id - Get contact details
router.get('/:id', async (req, res) => {
  try {
    const contact = await prisma.contact.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        organization: { select: { id: true, name: true } }
      }
    });
    if (!contact) {
      return res.status(404).json({ message: 'Contact not found' });
    }
    res.json(contact);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /:id - Update contact
router.put('/:id', authorize(['EDIT_CONTACTS']), async (req, res) => {
  try {
    const existing = await prisma.contact.findFirst({ 
      where: { id: req.params.id, organizationId: req.organizationId } 
    });
    
    if (!existing) return res.status(404).json({ message: 'Contact not found' });
    
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => {
      oldValues[k] = existing[k];
      newValues[k] = req.body[k];
    });

    const updated = await prisma.contact.update({ 
      where: { id: req.params.id }, 
      data: req.body 
    });

    await createActivityLogEntry({ 
      action: 'CONTACT_UPDATED', 
      entityType: 'Contact', 
      entityId: updated.id, 
      description: `Contact updated by ${req.user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues, newValues } 
    });

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// DELETE /:id - Delete contact
router.delete('/:id', authorize(['DELETE_CONTACTS']), async (req, res) => {
  try {
    const contact = await prisma.contact.deleteMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (contact.count === 0) {
      return res.status(404).json({ message: 'Contact not found' });
    }
    res.json({ message: 'Contact deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
