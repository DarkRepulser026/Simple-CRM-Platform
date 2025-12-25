import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { validateLead } from '../../middleware/validation.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import { protectConvertedLead } from '../../middleware/protectConvertedLead.js';

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
      },
      include: {
        owner: { select: { id: true, name: true, email: true } }
      }
    });

    // Log activity
    await createActivityLogEntry({
      action: 'LEAD_CREATED',
      entityType: 'Lead',
      entityId: lead.id,
      description: `Lead "${lead.firstName} ${lead.lastName}" created by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: { lead }
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

// GET /:id/activities - Get lead activity log
router.get('/:id/activities', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const _page = Math.max(parseInt(page), 1);
    const _limit = Math.min(parseInt(limit), 100);
    const skip = (_page - 1) * _limit;

    // Verify lead exists
    const lead = await prisma.lead.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }

    const total = await prisma.activityLog.count({
      where: {
        entityType: 'Lead',
        entityId: req.params.id,
        organizationId: req.organizationId
      }
    });

    const activities = await prisma.activityLog.findMany({
      where: {
        entityType: 'Lead',
        entityId: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        user: { select: { id: true, name: true, email: true } }
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: _limit
    });

    res.json({
      activities,
      pagination: {
        page: _page,
        limit: _limit,
        total,
        totalPages: Math.ceil(total / _limit),
        hasNext: _page * _limit < total,
        hasPrev: _page > 1
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PUT /:id - Update lead
// 🔒 UX Rule: After conversion → read-only (protectConvertedLead enforces this)
router.put('/:id', authorize(['EDIT_LEADS']), protectConvertedLead, async (req, res) => {
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
// 🔒 UX Rule: After conversion → read-only (protectConvertedLead blocks deletion)
router.delete('/:id', authorize(['DELETE_LEADS']), protectConvertedLead, async (req, res) => {
  try {
    const lead = await prisma.lead.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }

    await prisma.lead.delete({
      where: { id: req.params.id }
    });

    // Log activity
    await createActivityLogEntry({
      action: 'LEAD_DELETED',
      entityType: 'Lead',
      entityId: req.params.id,
      description: `Lead "${lead.firstName} ${lead.lastName}" deleted by ${req.user.email}`,
      userId: req.user.id,
      organizationId: req.organizationId,
      metadata: { deletedLead: lead }
    });

    res.json({ message: 'Lead deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /:id/convert - Convert lead to contact and account
// ✅ UX Rule: Convert CTA only visible if status ≠ CONVERTED (already has check inside)
router.post('/:id/convert', authorize(['CONVERT_LEADS']), async (req, res) => {
  try {
    const { accountId, accountName, accountDomain, contactFirstName, contactLastName, contactEmail, contactPhone, contactTitle } = req.body;

    // Validate lead exists
    const lead = await prisma.lead.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });

    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }

    if (lead.isConverted) {
      return res.status(400).json({ message: 'Lead is already converted' });
    }

    let account;
    let contact;

    // Start a transaction for atomicity
    try {
      // Step 1: Create or get account
      if (accountId) {
        // Use existing account
        account = await prisma.account.findFirst({
          where: {
            id: accountId,
            organizationId: req.organizationId
          }
        });
        if (!account) {
          return res.status(404).json({ message: 'Account not found' });
        }
      } else if (accountName) {
        // Create new account
        account = await prisma.account.create({
          data: {
            name: accountName,
            domain: accountDomain || null,
            type: 'CUSTOMER',
            organizationId: req.organizationId,
            ownerId: lead.ownerId || req.user.id
          }
        });
      } else {
        return res.status(400).json({ message: 'Either accountId or accountName is required' });
      }

      // Step 2: Create contact linked to account
      contact = await prisma.contact.create({
        data: {
          firstName: contactFirstName || lead.firstName,
          lastName: contactLastName || lead.lastName,
          email: contactEmail || lead.email || null,
          phone: contactPhone || lead.phone || null,
          title: contactTitle || lead.title || null,
          accountId: account.id,
          organizationId: req.organizationId,
          ownerId: lead.ownerId || req.user.id
        }
      });

      // Step 3: Update lead as converted
      const convertedLead = await prisma.lead.update({
        where: { id: lead.id },
        data: {
          isConverted: true,
          convertedAt: new Date(),
          convertedAccountId: account.id,
          convertedContactId: contact.id,
          status: 'CONVERTED'
        },
        include: {
          owner: { select: { id: true, name: true, email: true } }
        }
      });

      // Step 4: Log activity
      await createActivityLogEntry({
        action: 'LEAD_CONVERTED',
        entityType: 'Lead',
        entityId: lead.id,
        description: `Lead "${lead.firstName} ${lead.lastName}" converted to Account "${account.name}" and Contact by ${req.user.email}`,
        userId: req.user.id,
        organizationId: req.organizationId,
        metadata: {
          leadId: lead.id,
          accountId: account.id,
          contactId: contact.id
        }
      });

      res.json({
        success: true,
        message: 'Lead converted successfully',
        data: {
          lead: convertedLead,
          account,
          contact
        }
      });
    } catch (transactionError) {
      console.error('Lead conversion transaction error:', transactionError);
      
      // Handle specific Prisma errors
      if (transactionError.code === 'P2002') {
        return res.status(400).json({ 
          message: 'A contact with this email already exists for this account' 
        });
      }
      
      res.status(500).json({ message: `Conversion failed: ${transactionError.message}` });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
