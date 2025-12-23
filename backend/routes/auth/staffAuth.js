import express from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { createActivityLogEntry } from '../../services/activityService.js';
import mailer from '../../lib/mailer.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET;

// Initiate Google OAuth
router.get('/google',
  passport.authenticate('google', {
    scope: ['profile', 'email']
  })
);

// Google OAuth callback
router.get('/google/callback',
  passport.authenticate('google', { failureRedirect: '/login' }),
  (req, res) => {
    // Successful authentication, generate JWT
    const token = jwt.sign(
      { id: req.user.id, email: req.user.email, tokenVersion: req.user.tokenVersion || 0 },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    // Redirect to frontend with token
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    res.redirect(`${frontendUrl}/auth-callback?token=${token}`);
  }
);

// Handle mobile app Google sign-in
router.post('/google', async (req, res) => {
  try {
    const { email, name, googleId } = req.body;

    if (!email || !name) {
      return res.status(400).json({ message: 'Email and name are required' });
    }

    let user = await prisma.user.findUnique({
      where: { googleId: googleId || email }
    });

    if (!user) {
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        user = await prisma.user.update({
          where: { id: existingUser.id },
          data: { googleId: googleId || email }
        });
      } else {
        user = await prisma.user.create({
          data: {
            email,
            name,
            googleId: googleId || email
          }
        });
      }
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, tokenVersion: user.tokenVersion || 0 },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        profileImage: user.profileImage
      },
      token
    });
  } catch (error) {
    console.error('Mobile auth error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Debug login endpoint
router.post('/debug-login', async (req, res) => {
  try {
    if (process.env.NODE_ENV === 'production') {
      return res.status(403).json({ message: 'Debug login not available in production' });
    }

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    let user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, tokenVersion: user.tokenVersion || 0 },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userOrg = await prisma.userOrganization.findFirst({
      where: { userId: user.id },
      include: { organization: true }
    });

    const organization = userOrg?.organization || null;

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        profileImage: user.profileImage
      },
      token,
      organization: organization ? {
        id: organization.id,
        name: organization.name,
        domain: organization.domain
      } : null
    });
  } catch (error) {
    console.error('Debug login error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Google OAuth callback
router.get('/google/callback',
  passport.authenticate('google', { failureRedirect: '/auth/google/failure' }),
  async (req, res) => {
    try {
      const token = jwt.sign(
        { id: req.user.id, email: req.user.email, tokenVersion: req.user.tokenVersion || 0 },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      res.json({
        user: {
          id: req.user.id,
          email: req.user.email,
          name: req.user.name,
          profileImage: req.user.profileImage
        },
        token
      });
    } catch (error) {
      res.status(500).json({ message: 'Authentication error', error: error.message });
    }
  }
);

router.get('/google/failure', (req, res) => {
  res.status(401).json({ message: 'Google authentication failed' });
});

router.post('/logout', (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ message: 'Logout failed' });
    }
    res.json({ message: 'Logged out successfully' });
  });
});

router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        profileImage: true,
        isActive: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Accept invite route
router.post('/invite/accept', async (req, res) => {
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
        return res.status(403).json({ message: 'Invalid authorization token' });
      }
    }

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const inv = await prisma.invitation.findFirst({ where: { tokenHash, organizationId: orgId, email, acceptedAt: null } });
    if (!inv) return res.status(400).json({ message: 'Invalid or used token' });
    if (new Date() > inv.expiresAt) return res.status(400).json({ message: 'Invite expired' });

    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({ data: { email, name: name || email } });
    }

    const existingUserOrg = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: orgId } });
    const upsert = await prisma.userOrganization.upsert({ where: { userId_organizationId: { userId: user.id, organizationId: orgId } }, create: { userId: user.id, organizationId: orgId, role }, update: { role } });
    
    if (existingUserOrg && existingUserOrg.role !== role) {
      await prisma.user.update({ where: { id: user.id }, data: { tokenVersion: { increment: 1 } } });
      user = await prisma.user.findUnique({ where: { id: user.id } });
    }

    await prisma.invitation.update({ where: { id: inv.id }, data: { acceptedAt: new Date() } });
    await createActivityLogEntry({ action: 'INVITE_ACCEPTED', entityType: 'Invitation', entityId: upsert.id, description: `${user.email} accepted invite for ${role}`, userId: user.id, organizationId: orgId });
    
    const newToken = jwt.sign({ id: user.id, email: user.email, tokenVersion: user.tokenVersion || 0 }, JWT_SECRET, { expiresIn: '24h' });
    
    if (role === 'ADMIN') {
      res.cookie('admin_session', newToken, { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', maxAge: 24 * 60 * 60 * 1000 });
    }
    
    const org = await prisma.organization.findUnique({ where: { id: orgId } });
    res.json({ token: newToken, user: { id: user.id, email: user.email, name: user.name }, organization: org ? { id: org.id, name: org.name } : { id: orgId } , role });
  } catch (err) {
    console.error('Invite accept error', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
