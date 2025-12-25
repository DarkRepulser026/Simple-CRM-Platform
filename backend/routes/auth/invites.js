import express from 'express';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';
import { authorize } from '../../middleware/permissions.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import mailer from '../../lib/mailer.js';
import { getUserPermissions } from '../../lib/permissions.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// POST /organizations/:id/invite - Create an invite
router.post('/organizations/:id/invite', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const orgId = req.params.id;
    if (orgId !== req.organizationId) return res.status(400).json({ message: 'Organization ID mismatch' });
    const { email, role } = req.body;
    if (!email || !role) return res.status(400).json({ message: 'Email and role required' });
    
    // Resolve role
    let roleEnum = null;
    const allowed = ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];
    
    if (allowed.includes(role)) {
      roleEnum = role;
    } else {
      // Check if it's a custom role name
      const userRole = await prisma.userRole.findFirst({
        where: { organizationId: orgId, name: role }
      });
      if (userRole) {
        roleEnum = userRole.roleType;
      }
    }

    if (!roleEnum) return res.status(400).json({ message: 'Invalid role' });

    const token = jwt.sign({ email, orgId, role: roleEnum, createdBy: req.user.id }, JWT_SECRET, { expiresIn: '48h' });
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const expiresAt = new Date(Date.now() + 48*3600*1000);
    
    await prisma.invitation.create({ 
      data: { email, role: roleEnum, organizationId: orgId, tokenHash, expiresAt, createdBy: req.user.id } 
    });
    
    const link = `${process.env.APP_BASE_URL || 'http://localhost:3000'}/invite/accept?token=${token}`;
    await mailer.sendInviteEmail(email, link, role); // Send the display name (e.g. "Sales Agent") in email
    
    await createActivityLogEntry({ 
      action: 'INVITE_CREATED', 
      entityType: 'Invitation', 
      entityId: orgId, 
      description: `${req.user.email} invited ${email} as ${role}`, 
      userId: req.user.id, 
      organizationId: orgId 
    });
    
    res.json({ success: true });
  } catch (err) {
    console.error('Create invite error', err);
    res.status(500).json({ message: err.message });
  }
});

// GET /organizations/:id/invitations - List pending invites
router.get('/organizations/:id/invitations', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const orgId = req.params.id;
    if (orgId !== req.organizationId) return res.status(400).json({ message: 'Organization ID mismatch' });
    const invites = await prisma.invitation.findMany({ 
      where: { organizationId: orgId, acceptedAt: null, revokedAt: null } 
    });
    res.json(invites);
  } catch (err) {
    console.error('List invitations error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST /admin/invitations/:id/revoke - Revoke an invite
router.post('/admin/invitations/:id/revoke', authenticateToken, async (req, res) => {
  try {
    const invId = req.params.id;
    const inv = await prisma.invitation.findUnique({ where: { id: invId } });
    if (!inv) return res.status(404).json({ message: 'Invitation not found' });
    
    // Check permissions for organization
    const perms = await getUserPermissions(prisma, req.user.id, inv.organizationId);
    if (!perms.includes('MANAGE_USERS')) return res.status(403).json({ message: 'Forbidden' });
    
    await prisma.invitation.update({ where: { id: invId }, data: { revokedAt: new Date() } });
    
    await createActivityLogEntry({ 
      action: 'INVITE_REVOKED', 
      entityType: 'Invitation', 
      entityId: invId, 
      description: `${req.user.email} revoked invite ${inv.email}`, 
      userId: req.user.id, 
      organizationId: inv.organizationId 
    });
    
    res.json({ success: true });
  } catch (err) {
    console.error('Revoke invitation error:', err);
    res.status(500).json({ message: err.message });
  }
});

// POST /accept - Accept an invite token
router.post('/accept', async (req, res) => {
  try {
    const { token, name } = req.body;
    if (!token) return res.status(400).json({ message: 'Token is required' });
    
    let payload;
    try {
      payload = jwt.verify(token, JWT_SECRET);
    } catch (e) {
      return res.status(400).json({ message: 'Invalid or expired token' });
    }
    const { email, orgId, role } = payload;

    const authHeader = req.headers['authorization'];
    if (authHeader) {
      try {
        const authToken = authHeader.split(' ')[1];
        const authPayload = jwt.verify(authToken, JWT_SECRET);
        if (authPayload && authPayload.email && authPayload.email !== email) {
          return res.status(403).json({ message: 'Authenticated user does not match invite email' });
        }
      } catch (e) {
        console.error('Invalid authorization token on invite accept:', e);
        return res.status(403).json({ message: 'Invalid authorization token' });
      }
    }

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const inv = await prisma.invitation.findFirst({ 
      where: { tokenHash, organizationId: orgId, email, acceptedAt: null } 
    });
    
    if (!inv) return res.status(400).json({ message: 'Invalid or used token' });
    if (new Date() > inv.expiresAt) return res.status(400).json({ message: 'Invite expired' });

    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({ data: { email, name: name || email } });
    }

    const existingUserOrg = await prisma.userOrganization.findFirst({ 
      where: { userId: user.id, organizationId: orgId } 
    });
    
    const upsert = await prisma.userOrganization.upsert({ 
      where: { userId_organizationId: { userId: user.id, organizationId: orgId } }, 
      create: { userId: user.id, organizationId: orgId, role }, 
      update: { role } 
    });

    if (existingUserOrg && existingUserOrg.role !== role) {
      await prisma.user.update({ where: { id: user.id }, data: { tokenVersion: { increment: 1 } } });
      user = await prisma.user.findUnique({ where: { id: user.id } });
    }

    await prisma.invitation.update({ where: { id: inv.id }, data: { acceptedAt: new Date() } });
    
    await prisma.activityLog.create({ 
      data: { 
        action: 'INVITE_ACCEPTED', 
        entityType: 'Invitation', 
        entityId: upsert.id, 
        description: `${user.email} accepted invite for ${role}`, 
        userId: user.id, 
        organizationId: orgId 
      } 
    });

    const newToken = jwt.sign({ 
      id: user.id, 
      email: user.email, 
      tokenVersion: user.tokenVersion || 0 
    }, JWT_SECRET, { expiresIn: '24h' });

    if (role === 'ADMIN') {
      res.cookie('admin_session', newToken, { 
        httpOnly: true, 
        secure: process.env.NODE_ENV === 'production', 
        sameSite: 'lax', 
        maxAge: 24 * 60 * 60 * 1000 
      });
    }

    const org = await prisma.organization.findUnique({ where: { id: orgId } });
    res.json({ 
      token: newToken, 
      user: { id: user.id, email: user.email, name: user.name }, 
      organization: org ? { id: org.id, name: org.name } : { id: orgId } , 
      role 
    });
  } catch (err) {
    console.error('Invite accept error', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
