import express from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize, getUserPermissions } from '../../middleware/permissions.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import mailer from '../../lib/mailer.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Apply middleware
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - List users (paginated)
router.get('/', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    
    const filter = { where: { organizationId: req.organizationId } };
    if (search) {
      filter.where.OR = [
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { name: { contains: search, mode: 'insensitive' } } }
      ];
    }
    
    const total = await prisma.userOrganization.count({ where: filter.where });
    const userOrgs = await prisma.userOrganization.findMany({
      where: filter.where,
      include: { user: true },
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { joinedAt: 'desc' }
    });
    
    const users = userOrgs.map(uo => ({ ...uo.user, role: uo.role }));
    return res.json({ 
      users, 
      pagination: { 
        page, 
        limit, 
        total, 
        totalPages: Math.ceil(total / limit), 
        hasNext: page * limit < total, 
        hasPrev: page > 1 
      } 
    });
  } catch (err) {
    console.error('List users error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST / - Create user
router.post('/', authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const { email, name, role, isActive } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });
    
    let user = await prisma.user.findUnique({ where: { email } });
    if (user) return res.status(409).json({ message: 'User already exists' });
    
    user = await prisma.user.create({ 
      data: { email, name, isActive: isActive !== false } 
    });
    
    await prisma.userOrganization.create({ 
      data: { userId: user.id, organizationId: req.organizationId, role: role || 'VIEWER' } 
    });
    
    await createActivityLogEntry({ 
      action: 'USER_CREATED', 
      entityType: 'User', 
      entityId: user.id, 
      description: `${req.user.email} created user ${user.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    if (process.env.SEND_WELCOME_EMAILS === 'true') {
      try {
        const org = await prisma.organization.findUnique({ where: { id: req.organizationId } });
        await mailer.sendWelcomeEmail(user.email, user.name, org.name);
      } catch (e) {
        console.warn('Failed to send welcome email', e);
      }
    }
    
    res.status(201).json(user);
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// GET /:id - Get user by id
router.get('/:id', async (req, res) => {
  try {
    const uo = await prisma.userOrganization.findFirst({ 
      where: { userId: req.params.id, organizationId: req.organizationId }, 
      include: { user: true } 
    });
    if (!uo) return res.status(404).json({ message: 'User not found in organization' });
    res.json({ ...uo.user, role: uo.role });
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// PUT /:id - Update user
router.put('/:id', async (req, res) => {
  try {
    const targetUserId = req.params.id;
    
    if (req.user.id !== targetUserId) {
      const perms = await getUserPermissions(req.user.id, req.organizationId);
      if (!perms.includes('MANAGE_USERS')) return res.status(403).json({ message: 'Forbidden' });
    }
    
    const existing = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!existing) return res.status(404).json({ message: 'User not found' });
    
    const existingUserOrg = await prisma.userOrganization.findFirst({ 
      where: { userId: targetUserId, organizationId: req.organizationId } 
    });
    const currentRole = existingUserOrg?.role;
    
    const data = { ...req.body };
    delete data.id;
    delete data.createdAt;
    delete data.updatedAt;
    delete data.tokenVersion;
    delete data.googleId;
    delete data.permissions;
    
    if (data.role && data.role !== currentRole) {
      const role = data.role;
      delete data.role;
      await prisma.userOrganization.updateMany({ 
        where: { userId: targetUserId, organizationId: req.organizationId }, 
        data: { role } 
      });
      await prisma.user.update({ where: { id: targetUserId }, data: { tokenVersion: { increment: 1 } } });
      await createActivityLogEntry({ 
        action: 'USER_ROLE_UPDATED', 
        entityType: 'UserOrganization', 
        entityId: targetUserId, 
        description: `${req.user.email} changed role for user ${targetUserId} to ${role}`, 
        userId: req.user.id, 
        organizationId: req.organizationId, 
        metadata: { oldValues: { role: currentRole }, newValues: { role } } 
      });
    } else {
      delete data.role;
    }
    
    if (Object.keys(data).length > 0) {
      data.updatedAt = new Date();
    }
    
    let updated = existing;
    if (Object.keys(data).length > 0) {
      updated = await prisma.user.update({ where: { id: targetUserId }, data });
    }
    
    const uo = await prisma.userOrganization.findFirst({ 
      where: { userId: targetUserId, organizationId: req.organizationId }, 
      include: { user: true } 
    });
    const userWithRole = uo ? { ...uo.user, role: uo.role } : { ...updated, role: 'VIEWER' };
    
    await createActivityLogEntry({ 
      action: 'USER_UPDATED', 
      entityType: 'User', 
      entityId: updated.id, 
      description: `${req.user.email} updated user ${updated.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId, 
      metadata: { oldValues: { name: existing.name, email: existing.email }, newValues: data } 
    });
    
    res.json(userWithRole);
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// DELETE /:id - Remove user from organization
router.delete('/:id', authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const del = await prisma.userOrganization.deleteMany({ 
      where: { userId: targetUserId, organizationId: req.organizationId } 
    });
    if (del.count === 0) return res.status(404).json({ message: 'User not found in organization' });
    
    await createActivityLogEntry({ 
      action: 'USER_DELETED', 
      entityType: 'User', 
      entityId: targetUserId, 
      description: `${req.user.email} removed user ${targetUserId} from org`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });
    
    res.json({ message: 'User removed from organization' });
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST /view-as/:userId - Impersonate user
router.post('/view-as/:userId', authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const targetUserId = req.params.userId;
    const targetUserOrg = await prisma.userOrganization.findFirst({ 
      where: { userId: targetUserId, organizationId: req.organizationId } 
    });
    
    if (!targetUserOrg) return res.status(404).json({ message: 'Target user not found in organization' });
    
    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) return res.status(404).json({ message: 'User not found' });
    
    const impersonationToken = jwt.sign({ 
      id: targetUser.id, 
      email: targetUser.email, 
      tokenVersion: targetUser.tokenVersion || 0, 
      impersonatorId: req.user.id 
    }, JWT_SECRET, { expiresIn: '30m' });

    await createActivityLogEntry({ 
      action: 'IMPERSONATION', 
      entityType: 'User', 
      entityId: targetUser.id, 
      description: `${req.user.email} impersonated ${targetUser.email}`, 
      userId: req.user.id, 
      organizationId: req.organizationId 
    });

    res.json({ token: impersonationToken });
  } catch (err) {
    console.error('Impersonation error:', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
