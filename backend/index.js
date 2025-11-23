import express from 'express';
import cors from 'cors';
import session from 'express-session';
import passport from 'passport';
import cookieParser from 'cookie-parser';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import prisma from './lib/prismaClient.js';
import mailer from './lib/mailer.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const app = express();

console.log('Using DATABASE_URL:', process.env.DATABASE_URL ? '********REDACTED' : 'not set');
// Prisma Client is provided by `backend/lib/prismaClient.js` (singleton)

// Try connecting to the database and log health status (non-blocking, with a few retries)
async function checkDatabaseConnection(retries = 3, delayMs = 1000) {
  let attempt = 0;
  while (attempt < retries) {
    try {
      await prisma.$connect();
      console.log('Database connected successfully');
      await prisma.$disconnect();
      return true;
    } catch (e) {
      console.error('Database connection attempt failed:', e.message || e);
      attempt += 1;
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  return false;
}
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET;

// Passport configuration
passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: process.env.GOOGLE_REDIRECT_URI
  },
  async (accessToken, refreshToken, profile, done) => {
    try {
      // Find or create user based on Google profile
      let user = await prisma.user.findUnique({
        where: { googleId: profile.id }
      });

      if (!user) {
        // Check if user exists with same email
        const existingUser = await prisma.user.findUnique({
          where: { email: profile.emails[0].value }
        });

        if (existingUser) {
          // Update existing user with Google ID
          user = await prisma.user.update({
            where: { id: existingUser.id },
            data: { googleId: profile.id }
          });
        } else {
          // Create new user
          user = await prisma.user.create({
            data: {
              email: profile.emails[0].value,
              name: profile.displayName,
              googleId: profile.id,
              profileImage: profile.photos[0]?.value
            }
          });
        }
      }

      return done(null, user);
    } catch (error) {
      return done(error, null);
    }
  }
));

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { id } });
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

// Middleware
// Configure CORS explicitly for known local dev origin and allow required headers
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests from local dev server(s) and null (file://) for testing
    const allowed = [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3001',
      undefined,
      null,
    ];
    if (!origin || allowed.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true); // fallback to allow all origins to avoid development friction
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Organization-ID', 'X-Requested-With'],
  exposedHeaders: ['X-Organization-ID'],
};
app.use(cors(corsOptions));

// `app.use(cors(corsOptions))` above already handles CORS preflight requests
// so this explicit `options` route is redundant and may cause path parsing issues.

// Request logging for debugging CORS and network issues
app.use((req, res, next) => {
  console.log(`Incoming request: ${req.method} ${req.path} Origin:${req.headers.origin || 'none'}`);
  next();
});
app.use(express.json());
app.use(cookieParser());
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false, // Set to true in production with HTTPS
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));
app.use(passport.initialize());
app.use(passport.session());

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
const upload = multer({ dest: uploadsDir });
// Serve uploaded files statically at /uploads
app.use('/uploads', express.static(uploadsDir));

// Generic Express error handler to return JSON errors and log them
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err && (err.stack || err));
  if (res.headersSent) return next(err);
  res.status(500).json({ message: 'Internal server error', error: err && err.message ? err.message : String(err) });
});

// Health check endpoint to verify server + database connectivity
app.get('/health', async (req, res) => {
  try {
    const ok = await checkDatabaseConnection(1, 0);
    if (ok) return res.json({ status: 'ok' });
    return res.status(500).json({ status: 'error', message: 'Database connection failed' });
  } catch (e) {
    return res.status(500).json({ status: 'error', message: e.message });
  }
});

// Authentication middleware
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    let token = authHeader && authHeader.split(' ')[1];
    // Also accept admin_session cookie for admin flows
    if (!token && req.cookies && req.cookies.admin_session) {
      token = req.cookies.admin_session;
    }
    if (!token) return res.status(401).json({ message: 'Access token required' });

    let payload;
    try {
      payload = jwt.verify(token, JWT_SECRET);
    } catch (e) {
      return res.status(403).json({ message: 'Invalid token' });
    }

    // Validate tokenVersion for revocation
    const userRec = await prisma.user.findUnique({ where: { id: payload.id } });
    if (!userRec) return res.status(401).json({ message: 'Invalid user' });
    if (userRec.tokenVersion !== (payload.tokenVersion || 0)) {
      return res.status(401).json({ message: 'Token revoked. Please sign in again.' });
    }

    req.user = { id: userRec.id, email: userRec.email, name: userRec.name, tokenVersion: userRec.tokenVersion };
    next();
  } catch (err) {
    console.error('Authentication error:', err);
    return res.status(500).json({ message: 'Authentication error' });
  }
};

// Organization middleware
const requireOrganization = (req, res, next) => {
  const orgId = req.headers['x-organization-id'];
  if (!orgId) {
    return res.status(400).json({ message: 'Organization ID required' });
  }
  req.organizationId = orgId;
  next();
};

// Helper to get user permissions for an organization by resolving the user's role
const getUserPermissions = async (userId, organizationId) => {
  const userOrg = await prisma.userOrganization.findFirst({ where: { userId, organizationId } });
  if (!userOrg) return [];
  const roleType = userOrg.role;
  const role = await prisma.userRole.findFirst({ where: { organizationId, roleType } });
  if (!role) return [];
  return role.permissions || [];
};

// Authorization middleware - requires at least one permission to pass
const authorize = (requiredPermissions) => {
  return async (req, res, next) => {
    try {
      const userId = req.user && req.user.id;
      const orgId = req.organizationId;
      if (!userId || !orgId) return res.status(403).json({ message: 'Forbidden' });
      const permissions = await getUserPermissions(userId, orgId);
      const hasPermission = requiredPermissions.some(p => permissions.includes(p));
      if (!hasPermission) return res.status(403).json({ message: 'Forbidden: insufficient permissions' });
      next();
    } catch (e) {
      console.error('Authorization check error:', e);
      return res.status(500).json({ message: 'Authorization error' });
    }
  };
};

// Input validation middleware
const validateContact = (req, res, next) => {
  const { firstName, lastName } = req.body;
  if (!firstName || !lastName) {
    return res.status(400).json({ message: 'First name and last name are required' });
  }
  next();
};

const validateLead = (req, res, next) => {
  const { firstName, lastName } = req.body;
  if (!firstName || !lastName) {
    return res.status(400).json({ message: 'First name and last name are required' });
  }
  next();
};

const validateTask = (req, res, next) => {
  const { subject } = req.body;
  if (!subject) {
    return res.status(400).json({ message: 'Subject is required' });
  }
  next();
};

const validateTicket = (req, res, next) => {
  const { subject } = req.body;
  if (!subject) {
    return res.status(400).json({ message: 'Subject is required' });
  }
  next();
};

const validateOrganization = (req, res, next) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ message: 'Name is required' });
  }
  next();
};

// Routes

// Auth routes
// Initiate Google OAuth (for web clients)
app.get('/auth/google',
  passport.authenticate('google', {
    scope: ['profile', 'email']
  })
);

// Handle mobile app Google sign-in (exchange Google token for JWT)
app.post('/auth/google', async (req, res) => {
  try {
    // Quick database health check: return 503 if DB not reachable
    const dbOk = await checkDatabaseConnection(1, 0);
    if (!dbOk) return res.status(503).json({ message: 'Database unavailable' });
    const { idToken, email, name, googleId } = req.body;

    if (!email || !name) {
      return res.status(400).json({ message: 'Email and name are required' });
    }

    // Find or create user based on Google data
    let user = await prisma.user.findUnique({
      where: { googleId: googleId || email }
    });

    if (!user) {
      // Check if user exists with same email
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        // Update existing user with Google ID
        user = await prisma.user.update({
          where: { id: existingUser.id },
          data: { googleId: googleId || email }
        });
      } else {
        // Create new user
        user = await prisma.user.create({
          data: {
            email,
            name,
            googleId: googleId || email
          }
        });
      }
    }

    // Generate JWT token (include tokenVersion for revocation checks)
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

// Google OAuth callback
app.get('/auth/google/callback',
  passport.authenticate('google', { failureRedirect: '/auth/google/failure' }),
  async (req, res) => {
    try {
      // Generate JWT token for the authenticated user
      const token = jwt.sign(
        { id: req.user.id, email: req.user.email, tokenVersion: req.user.tokenVersion || 0 },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      // Redirect to frontend with token (or return JSON for API clients)
      // For API, we'll return JSON. For web app, you might want to redirect with token in query param
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

// Auth failure route
app.get('/auth/google/failure', (req, res) => {
  res.status(401).json({ message: 'Google authentication failed' });
});

// Logout route
app.post('/auth/logout', (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ message: 'Logout failed' });
    }
    res.json({ message: 'Logged out successfully' });
  });
});

// Get current user info
app.get('/auth/me', authenticateToken, async (req, res) => {
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

// Contacts routes
app.get('/contacts', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const contacts = await prisma.contact.findMany({
      where: { organizationId: req.organizationId },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        organization: { select: { id: true, name: true } }
      }
    });
    res.json(contacts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/contacts', authenticateToken, requireOrganization, authorize(['CREATE_CONTACTS']), validateContact, async (req, res) => {
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

app.get('/contacts/:id', authenticateToken, requireOrganization, async (req, res) => {
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

app.put('/contacts/:id', authenticateToken, requireOrganization, authorize(['EDIT_CONTACTS']), async (req, res) => {
  try {
    const contact = await prisma.contact.updateMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      data: req.body
    });
    if (contact.count === 0) {
      return res.status(404).json({ message: 'Contact not found' });
    }
    res.json({ message: 'Contact updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete('/contacts/:id', authenticateToken, requireOrganization, authorize(['DELETE_CONTACTS']), async (req, res) => {
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

// Attachments endpoints - store files on disk and metadata in DB
app.post('/attachments', authenticateToken, requireOrganization, upload.single('file'), async (req, res) => {
  try {
    const { entityType, entityId } = req.body;
    if (!entityType || !entityId) return res.status(400).json({ message: 'entityType and entityId required' });
    if (!req.file) return res.status(400).json({ message: 'file is required' });

    // Determine required permission based on entity type
    const permissionMap = {
      ticket: 'CREATE_TICKETS',
      contact: 'CREATE_CONTACTS',
      lead: 'CREATE_LEADS',
      task: 'CREATE_TASKS',
      account: 'CREATE_CONTACTS'
    };
    const requiredPermission = permissionMap[entityType] || 'CREATE_TICKETS';
    const perms = await getUserPermissions(req.user.id, req.organizationId);
    if (!perms.includes(requiredPermission)) return res.status(403).json({ message: 'Forbidden' });

    // Move file to organization folder and save metadata
    const filename = req.file.originalname || req.file.filename;
    const targetDir = path.join(uploadsDir, req.organizationId);
    if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
    const targetPath = path.join(targetDir, `${Date.now()}-${filename}`);
    fs.renameSync(req.file.path, targetPath);

    // Save metadata in DB
    const url = `/uploads/${req.organizationId}/${path.basename(targetPath)}`; // public path
    const saved = await prisma.attachment.create({
      data: {
        filename,
        mimeType: req.file.mimetype,
        url,
        size: req.file.size,
        uploadedBy: req.user.id,
        organizationId: req.organizationId,
        entityType,
        entityId,
      }
    });
    res.status(201).json(saved);
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Invite create - sends an invite token to an email. Caller must have MANAGE_USERS
app.post('/organizations/:id/invite', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const orgId = req.params.id;
    if (orgId !== req.organizationId) return res.status(400).json({ message: 'Organization ID mismatch' });
    const { email, role } = req.body;
    if (!email || !role) return res.status(400).json({ message: 'Email and role required' });
    // Validate role
    const allowed = ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];
    if (!allowed.includes(role)) return res.status(400).json({ message: 'Invalid role' });

    // create token and store hashed token
    const token = jwt.sign({ email, orgId, role, createdBy: req.user.id }, JWT_SECRET, { expiresIn: '48h' });
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const expiresAt = new Date(Date.now() + 48*3600*1000);
    await prisma.invitation.create({ data: { email, role, organizationId: orgId, tokenHash, expiresAt, createdBy: req.user.id } });
    // Send invite email (uses nodemailer if configured)
    const link = `${process.env.APP_BASE_URL || 'http://localhost:3000'}/invite/accept?token=${token}`;
    await mailer.sendInviteEmail(email, link, role);
    await prisma.activityLog.create({ data: { action: 'INVITE_CREATED', entityType: 'Invitation', entityId: orgId, description: `${req.user.email} invited ${email} as ${role}`, userId: req.user.id, organizationId: orgId } });
    res.json({ success: true });
  } catch (err) {
    console.error('Create invite error', err);
    res.status(500).json({ message: err.message });
  }
});

// Accept invite route - accept an invite token and create/associate user and assign role.
app.post('/invite/accept', async (req, res) => {
  try {
    const { token, name } = req.body;
    if (!token) return res.status(400).json({ message: 'Token is required' });
    // Verify token signature
    let payload;
    try {
      payload = jwt.verify(token, JWT_SECRET);
    } catch (e) {
      return res.status(400).json({ message: 'Invalid or expired token' });
    }
    const { email, orgId, role } = payload;
    // Check token hash against stored invitation
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const inv = await prisma.invitation.findFirst({ where: { tokenHash, organizationId: orgId, email, acceptedAt: null } });
    if (!inv) return res.status(400).json({ message: 'Invalid or used token' });
    if (new Date() > inv.expiresAt) return res.status(400).json({ message: 'Invite expired' });

    // Create user if not exists
    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({ data: { email, name: name || email } });
    }

    // Associate user to org with role (and check for role changes to revoke tokens)
    const existingUserOrg = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: orgId } });
    const upsert = await prisma.userOrganization.upsert({ where: { userId_organizationId: { userId: user.id, organizationId: orgId } }, create: { userId: user.id, organizationId: orgId, role }, update: { role } });
    // If role changed for an existing association, increment tokenVersion to revoke tokens
    if (existingUserOrg && existingUserOrg.role !== role) {
      await prisma.user.update({ where: { id: user.id }, data: { tokenVersion: { increment: 1 } } });
      user = await prisma.user.findUnique({ where: { id: user.id } }); // refresh user tokenVersion
    }
    // Mark invitation accepted
    await prisma.invitation.update({ where: { id: inv.id }, data: { acceptedAt: new Date() } });
    // Log activity
    await prisma.activityLog.create({ data: { action: 'INVITE_ACCEPTED', entityType: 'Invitation', entityId: upsert.id, description: `${user.email} accepted invite for ${role}`, userId: user.id, organizationId: orgId } });
    // generate JWT for new/existing user
    const newToken = jwt.sign({ id: user.id, email: user.email, tokenVersion: user.tokenVersion || 0 }, JWT_SECRET, { expiresIn: '24h' });
    // If invited as ADMIN, set httpOnly admin_session cookie aligned with workflow
    if (role === 'ADMIN') {
      res.cookie('admin_session', newToken, { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', maxAge: 24 * 60 * 60 * 1000 });
    }
    res.json({ token: newToken, user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    console.error('Invite accept error', err);
    res.status(500).json({ message: err.message });
  }
});

  // List pending invites for an organization - admin permission required
  app.get('/organizations/:id/invitations', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
    try {
      const orgId = req.params.id;
      if (orgId !== req.organizationId) return res.status(400).json({ message: 'Organization ID mismatch' });
      const invites = await prisma.invitation.findMany({ where: { organizationId: orgId, acceptedAt: null, revokedAt: null } });
      res.json(invites);
    } catch (err) {
      console.error('List invitations error:', err);
      res.status(500).json({ message: err.message });
    }
  });

  // Revoke an invite - only for admins (MANAGE_USERS)
  app.post('/admin/invitations/:id/revoke', authenticateToken, async (req, res) => {
    try {
      const invId = req.params.id;
      const inv = await prisma.invitation.findUnique({ where: { id: invId } });
      if (!inv) return res.status(404).json({ message: 'Invitation not found' });
      // Check permissions for organization
      req.organizationId = inv.organizationId;
      const perms = await getUserPermissions(req.user.id, req.organizationId);
      if (!perms.includes('MANAGE_USERS')) return res.status(403).json({ message: 'Forbidden' });
      await prisma.invitation.update({ where: { id: invId }, data: { revokedAt: new Date() } });
      await prisma.activityLog.create({ data: { action: 'INVITE_REVOKED', entityType: 'Invitation', entityId: invId, description: `${req.user.email} revoked invite ${inv.email}`, userId: req.user.id, organizationId: inv.organizationId } });
      res.json({ success: true });
    } catch (err) {
      console.error('Revoke invitation error:', err);
      res.status(500).json({ message: err.message });
    }
  });

// List attachments
app.get('/attachments', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const { entityType, entityId } = req.query;
    if (!entityType || !entityId) return res.status(400).json({ message: 'entityType and entityId required' });
    const permissionMap = {
      ticket: 'VIEW_TICKETS',
      contact: 'VIEW_CONTACTS',
      lead: 'VIEW_LEADS',
      task: 'VIEW_TASKS',
      account: 'VIEW_CONTACTS'
    };
    const requiredPermission = permissionMap[entityType] || 'VIEW_TICKETS';
    const perms = await getUserPermissions(req.user.id, req.organizationId);
    if (!perms.includes(requiredPermission)) return res.status(403).json({ message: 'Forbidden' });

    const attachments = await prisma.attachment.findMany({
      where: { entityType: String(entityType), entityId: String(entityId), organizationId: req.organizationId }
    });
    res.json(attachments);
  } catch (error) {
    console.error('List attachments error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Admin: impersonate (view-as) a user within the organization
app.post('/admin/view-as/:userId', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const targetUserId = req.params.userId;
    // Verify the target user belongs to the organization
    const targetUserOrg = await prisma.userOrganization.findFirst({ where: { userId: targetUserId, organizationId: req.organizationId } });
    if (!targetUserOrg) return res.status(404).json({ message: 'Target user not found in organization' });
    // create short-lived impersonation token
    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) return res.status(404).json({ message: 'User not found' });
    const impersonationToken = jwt.sign({ id: targetUser.id, email: targetUser.email, tokenVersion: targetUser.tokenVersion || 0, impersonatorId: req.user.id }, JWT_SECRET, { expiresIn: '30m' });
    await prisma.activityLog.create({ data: { action: 'IMPERSONATION', entityType: 'User', entityId: targetUser.id, description: `${req.user.email} impersonated ${targetUser.email}`, userId: req.user.id, organizationId: req.organizationId } });
    res.json({ token: impersonationToken });
  } catch (err) {
    console.error('Impersonation error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Get attachment metadata
app.get('/attachments/:id', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const att = await prisma.attachment.findUnique({ where: { id: req.params.id } });
    if (!att) return res.status(404).json({ message: 'Not found' });
    if (att.organizationId !== req.organizationId) return res.status(403).json({ message: 'Forbidden' });
    res.json(att);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Download attachment content
app.get('/attachments/:id/download', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const att = await prisma.attachment.findUnique({ where: { id: req.params.id } });
    if (!att) return res.status(404).json({ message: 'Not found' });
    if (att.organizationId !== req.organizationId) return res.status(403).json({ message: 'Forbidden' });
    const filePath = path.join(uploadsDir, att.organizationId, path.basename(att.url));
    if (!fs.existsSync(filePath)) return res.status(404).json({ message: 'file not found' });
    res.sendFile(filePath);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Leads routes
app.get('/leads', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const leads = await prisma.lead.findMany({
      where: { organizationId: req.organizationId },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } }
      }
    });
    res.json(leads);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/leads', authenticateToken, requireOrganization, authorize(['CREATE_LEADS']), validateLead, async (req, res) => {
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

app.get('/leads/:id', authenticateToken, requireOrganization, async (req, res) => {
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

app.put('/leads/:id', authenticateToken, requireOrganization, authorize(['EDIT_LEADS']), async (req, res) => {
  try {
    const lead = await prisma.lead.updateMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      data: req.body
    });
    if (lead.count === 0) {
      return res.status(404).json({ message: 'Lead not found' });
    }
    res.json({ message: 'Lead updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete('/leads/:id', authenticateToken, requireOrganization, authorize(['DELETE_LEADS']), async (req, res) => {
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

// Tasks routes
app.get('/tasks', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { organizationId: req.organizationId },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } },
        lead: { select: { id: true, firstName: true, lastName: true } }
      }
    });
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/tasks', authenticateToken, requireOrganization, authorize(['CREATE_TASKS']), validateTask, async (req, res) => {
  try {
    const task = await prisma.task.create({
      data: {
        ...req.body,
        organizationId: req.organizationId,
        createdById: req.user.id
      }
    });
    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/tasks/:id', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const task = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } },
        lead: { select: { id: true, firstName: true, lastName: true } }
      }
    });
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/tasks/:id', authenticateToken, requireOrganization, authorize(['EDIT_TASKS']), async (req, res) => {
  try {
    const task = await prisma.task.updateMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      data: req.body
    });
    if (task.count === 0) {
      return res.status(404).json({ message: 'Task not found' });
    }
    res.json({ message: 'Task updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete('/tasks/:id', authenticateToken, requireOrganization, authorize(['DELETE_TASKS']), async (req, res) => {
  try {
    const task = await prisma.task.deleteMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (task.count === 0) {
      return res.status(404).json({ message: 'Task not found' });
    }
    res.json({ message: 'Task deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Tickets routes
app.get('/tickets', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const tickets = await prisma.ticket.findMany({
      where: { organizationId: req.organizationId },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          include: {
            author: { select: { id: true, name: true, email: true } }
          },
          orderBy: { createdAt: 'asc' }
        }
      }
    });
    res.json(tickets);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/tickets', authenticateToken, requireOrganization, authorize(['CREATE_TICKETS']), validateTicket, async (req, res) => {
  try {
    const ticket = await prisma.ticket.create({
      data: {
        ...req.body,
        organizationId: req.organizationId,
        ownerId: req.body.ownerId || req.user.id
      }
    });
    res.status(201).json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/tickets/:id', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          include: {
            author: { select: { id: true, name: true, email: true } }
          },
          orderBy: { createdAt: 'asc' }
        }
      }
    });
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }
    res.json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/tickets/:id', authenticateToken, requireOrganization, authorize(['EDIT_TICKETS']), async (req, res) => {
  try {
    const ticket = await prisma.ticket.updateMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      },
      data: req.body
    });
    if (ticket.count === 0) {
      return res.status(404).json({ message: 'Ticket not found' });
    }
    res.json({ message: 'Ticket updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete('/tickets/:id', authenticateToken, requireOrganization, authorize(['DELETE_TICKETS']), async (req, res) => {
  try {
    const ticket = await prisma.ticket.deleteMany({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (ticket.count === 0) {
      return res.status(404).json({ message: 'Ticket not found' });
    }
    res.json({ message: 'Ticket deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Ticket messages routes
app.post('/tickets/:id/messages', authenticateToken, requireOrganization, async (req, res) => {
  try {
    // Verify ticket belongs to organization
    const ticket = await prisma.ticket.findFirst({
      where: {
        id: req.params.id,
        organizationId: req.organizationId
      }
    });
    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    const message = await prisma.ticketMessage.create({
      data: {
        content: req.body.content,
        isInternal: req.body.isInternal || false,
        ticketId: req.params.id,
        authorId: req.user.id
      },
      include: {
        author: { select: { id: true, name: true, email: true } }
      }
    });
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Organizations routes
app.get('/organizations', authenticateToken, async (req, res) => {
  try {
    const userOrganizations = await prisma.userOrganization.findMany({
      where: { userId: req.user.id },
      include: {
        organization: true
      }
    });
    const organizations = userOrganizations.map(uo => uo.organization);
    res.json(organizations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/organizations', authenticateToken, validateOrganization, async (req, res) => {
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

app.get('/organizations/:id', authenticateToken, async (req, res) => {
  try {
    // Check if user has access to this organization
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

    res.json(userOrg.organization);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/organizations/:id', authenticateToken, async (req, res) => {
  try {
    // Check if user is admin of this organization
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

// Update a user's role within an organization
app.put('/organizations/:id/users/:userId/role', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const orgId = req.params.id;
    if (orgId !== req.organizationId) return res.status(400).json({ message: 'Organization ID mismatch' });
    const targetUserId = req.params.userId;
    const { role } = req.body;
    if (!role) return res.status(400).json({ message: 'Role is required' });
    const userOrg = await prisma.userOrganization.findFirst({ where: { userId: targetUserId, organizationId: orgId } });
    if (!userOrg) return res.status(404).json({ message: 'User not found in organization' });
    if (userOrg.role === role) return res.json({ message: 'No change' });
    await prisma.userOrganization.update({ where: { id: userOrg.id }, data: { role } });
    // Revoke tokens by incrementing tokenVersion
    await prisma.user.update({ where: { id: targetUserId }, data: { tokenVersion: { increment: 1 } } });
    await prisma.activityLog.create({ data: { action: 'USER_ROLE_UPDATED', entityType: 'UserOrganization', entityId: userOrg.id, description: `${req.user.email} changed role for user ${targetUserId} to ${role}`, userId: req.user.id, organizationId: orgId } });
    res.json({ success: true });
  } catch (err) {
    console.error('Update user role error:', err);
    res.status(500).json({ message: err.message });
  }
});

app.delete('/organizations/:id', authenticateToken, async (req, res) => {
  try {
    // Check if user is admin of this organization
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

// Dashboard route
app.get('/dashboard', authenticateToken, requireOrganization, async (req, res) => {
  try {
    // Get counts for dashboard
    const [contactCount, leadCount, taskCount, ticketCount] = await Promise.all([
      prisma.contact.count({ where: { organizationId: req.organizationId } }),
      prisma.lead.count({ where: { organizationId: req.organizationId } }),
      prisma.task.count({ where: { organizationId: req.organizationId } }),
      prisma.ticket.count({ where: { organizationId: req.organizationId } })
    ]);

    // Get recent activities
    const recentActivities = await prisma.activityLog.findMany({
      where: { organizationId: req.organizationId },
      include: {
        user: { select: { id: true, name: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    // Get task status breakdown
    const taskStats = await prisma.task.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    // Get lead status breakdown
    const leadStats = await prisma.lead.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    // Get ticket status breakdown
    const ticketStats = await prisma.ticket.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    res.json({
      counts: {
        contacts: contactCount,
        leads: leadCount,
        tasks: taskCount,
        tickets: ticketCount
      },
      recentActivities,
      taskStats,
      leadStats,
      ticketStats
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Gracefully shutdown the server and Prisma connection
async function shutdown(signal) {
  console.log(`Received ${signal}. Shutting down server...`);
  try {
    await prisma.$disconnect();
  } catch (err) {
    console.warn('Prisma disconnect failed during shutdown:', err);
  }
  server.close(() => {
    process.exit(0);
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));