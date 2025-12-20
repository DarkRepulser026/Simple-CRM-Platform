import express from 'express';
import cors from 'cors';
import session from 'express-session';
import passport from 'passport';
import cookieParser from 'cookie-parser';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import prisma from './lib/prismaClient.js';
import { ALLOWED_PERMISSIONS, normalizePermissionsArray as normalizePermissionsArrayLib, normalizeRoleType as normalizeRoleTypeLib, getUserPermissions as getUserPermissionsLib } from './lib/permissions.js';
import mailer from './lib/mailer.js';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';
import { registerCustomer, loginCustomer, refreshAccessToken, invalidateUserTokens, verifyCustomerUser } from './lib/customerAuth.js';
import { verifyCustomerToken, requireCustomer } from './lib/customerMiddleware.js';

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

// Ensure GOOGLE_REDIRECT_URI falls back to the backend server's callback route
const DEFAULT_GOOGLE_REDIRECT_URI = `http://localhost:${PORT}/auth/google/callback`;
const GOOGLE_REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || DEFAULT_GOOGLE_REDIRECT_URI;

// Log basic Google OAuth configuration for debugging (don't print secrets)
console.log('Google OAuth config:');
console.log(' - GOOGLE_CLIENT_ID:', process.env.GOOGLE_CLIENT_ID ? '***REDACTED' : 'not set');
console.log(' - GOOGLE_REDIRECT_URI:', GOOGLE_REDIRECT_URI);
console.log(' - Passport callbackURL used for GoogleStrategy:', GOOGLE_REDIRECT_URI);

// Passport configuration
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: GOOGLE_REDIRECT_URI
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

// User Role endpoints were moved below near user endpoints to ensure middleware is initialized

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

// Dev-only headers debug middleware — logs presence of Authorization and organization headers (not values)
app.use((req, res, next) => {
  if (process.env.NODE_ENV !== 'production') {
    const authPresent = req.headers['authorization'] ? true : false;
    const xOrg = req.headers['x-organization-id'] ? req.headers['x-organization-id'] : null;
    console.log(`Header check: Authorization present=${authPresent} X-Organization-ID=${xOrg}`);
  }
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
// app.get('/health', async (req, res) => {
//   try {
//     const ok = await checkDatabaseConnection(1, 0);
//     if (ok) return res.json({ status: 'ok' });
//     return res.status(500).json({ status: 'error', message: 'Database connection failed' });
//   } catch (e) {
//     return res.status(500).json({ status: 'error', message: e.message });
//   }
// });

app.get('/health', async (req, res) => {
  try {
    const dbOk = await checkDatabaseConnection(1, 0);

    if (dbOk) {
      return res.json({
        status: 'Healthy',              // <--- đổi ở đây
        details: {
          database: 'up'
        }
      });
    }

    return res.status(500).json({
      status: 'Unhealthy',             // <--- thay cho 'error'
      message: 'Database connection failed',
      details: {
        database: 'down'
      }
    });
  } catch (e) {
    return res.status(500).json({
      status: 'Unhealthy',
      message: e.message,
      details: {
        database: 'error'
      }
    });
  }
});

// Dev helper route to inspect received headers for debugging (not enabled in production)
app.get('/debug/headers', (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ message: 'Disabled in production' });
  }
  const auth = req.headers['authorization'];
  const xorg = req.headers['x-organization-id'];
  return res.json({ authorization: auth ? (typeof auth === 'string' ? `${auth.substring(0, 12)}...` : true) : null, xOrganizationId: xorg || null });
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

// Wrapper around helper from lib/permissions, bound to the Prisma client
const getUserPermissions = async (userId, organizationId) => getUserPermissionsLib(prisma, userId, organizationId);

// Centralized helper to create activity log entries (standardizes metadata & optional activity options)
const createActivityLogEntry = async ({ action, entityType, entityId, description, userId, organizationId, metadata = null }) => {
  try {
    const data = { action, entityType, entityId, description, userId, organizationId };
    if (metadata) data.metadata = metadata;
    return await prisma.activityLog.create({ data });
  } catch (e) {
    console.error('createActivityLogEntry error:', e);
    // Non-blocking: swallowing error is safer than failing API call, but log for investigation
    return null;
  }
};

// Helpers to map user-provided role and permission strings to Prisma enum values
// helper wrappers for backward-compatible usage
const normalizeRoleType = normalizeRoleTypeLib;

// ALLOWED_PERMISSIONS moved to lib/permissions for reuse
const ALLOWED_PERMISSIONS_LOCAL = ALLOWED_PERMISSIONS;

const normalizePermissionsArray = (arr) => normalizePermissionsArrayLib(arr);

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

// Account input validation
const validateAccount = (req, res, next) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ message: 'Account name is required' });
  }
  next();
};

// Routes

// Rate limiter for customer auth endpoints (5 attempts per 15 minutes)
// Disabled in test environment
const baseRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

// Wrapper that checks NODE_ENV at runtime
const customerAuthLimiter = (req, res, next) => {
  if (process.env.NODE_ENV === 'test') {
    return next();
  }
  return baseRateLimiter(req, res, next);
};

console.log(`[Rate Limiter] Initial NODE_ENV=${process.env.NODE_ENV}`);

// ====================
// CUSTOMER PORTAL ROUTES
// ====================

// Customer Authentication Routes
// POST /api/external/auth/register - Register new customer
app.post('/api/external/auth/register', customerAuthLimiter, async (req, res) => {
  try {
    const { email, password, name, companyName, phone } = req.body;
    
    const result = await registerCustomer({
      email,
      password,
      name,
      companyName,
      phone
    });

    res.status(201).json(result);
  } catch (error) {
    console.error('Customer registration error:', error);
    
    if (error.message === 'User with this email already exists') {
      return res.status(409).json({ error: error.message });
    }
    
    if (error.message.includes('required')) {
      return res.status(400).json({ error: error.message });
    }
    
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// POST /api/external/auth/login - Login customer
app.post('/api/external/auth/login', customerAuthLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const result = await loginCustomer({ email, password });
    
    res.json(result);
  } catch (error) {
    console.error('Customer login error:', error);
    
    if (error.message === 'Invalid email or password' || 
        error.message.includes('inactive')) {
      return res.status(401).json({ error: error.message });
    }
    
    if (error.message.includes('required')) {
      return res.status(400).json({ error: error.message });
    }
    
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// POST /api/external/auth/refresh - Refresh access token
app.post('/api/external/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }
    
    const result = await refreshAccessToken(refreshToken);
    
    res.json(result);
  } catch (error) {
    console.error('Token refresh error:', error);
    
    if (error.message.includes('Invalid') || 
        error.message.includes('expired') ||
        error.message.includes('invalidated')) {
      return res.status(401).json({ error: error.message });
    }
    
    res.status(500).json({ error: 'Token refresh failed. Please try again.' });
  }
});

// POST /api/external/auth/logout - Logout customer (invalidate all tokens)
app.post('/api/external/auth/logout', requireCustomer, async (req, res) => {
  try {
    await invalidateUserTokens(req.userId);
    
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Logout failed. Please try again.' });
  }
});

// GET /api/external/auth/verify - Verify current token
app.get('/api/external/auth/verify', requireCustomer, async (req, res) => {
  try {
    // If we get here, the token is valid (verified by middleware)
    res.json({
      isValid: true,
      user: req.user
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// Customer Ticket Management Endpoints

// Helper function to generate ticket number
function generateTicketNumber(organizationId) {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `TICKET-${timestamp}-${random}`;
}

// GET /api/external/tickets - Get customer's tickets with pagination
app.get('/api/external/tickets', requireCustomer, async (req, res) => {
  try {
    const { status, priority, page = '1', limit = '20' } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Build where clause
    const where = {
      customerId: req.userId
    };

    if (status) {
      where.status = status.toUpperCase();
    }

    if (priority) {
      where.priority = priority.toUpperCase();
    }

    // Get tickets with pagination
    const [tickets, total] = await Promise.all([
      prisma.ticket.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limitNum,
        include: {
          organization: {
            select: {
              id: true,
              name: true
            }
          },
          owner: {
            select: {
              id: true,
              name: true,
              email: true
            }
          },
          messages: {
            where: {
              isInternal: false
            },
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: {
              content: true,
              createdAt: true
            }
          }
        }
      }),
      prisma.ticket.count({ where })
    ]);

    res.json({
      tickets,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Get tickets error:', error);
    res.status(500).json({ error: 'Failed to retrieve tickets' });
  }
});

// POST /api/external/tickets - Create new ticket
app.post('/api/external/tickets', requireCustomer, async (req, res) => {
  try {
    const { subject, description, priority = 'NORMAL', category } = req.body;

    // Validation
    if (!subject || !description) {
      return res.status(400).json({ error: 'Subject and description are required' });
    }

    // Get customer's organization (or use a default one)
    // For now, we'll get the first organization or create a default customer organization
    let organizationId;
    const userOrg = await prisma.userOrganization.findFirst({
      where: { userId: req.userId }
    });

    if (userOrg) {
      organizationId = userOrg.organizationId;
    } else {
      // Create or get default customer organization
      let defaultOrg = await prisma.organization.findFirst({
        where: { name: 'Customer Portal' }
      });

      if (!defaultOrg) {
        defaultOrg = await prisma.organization.create({
          data: {
            name: 'Customer Portal',
            description: 'Default organization for customer portal tickets'
          }
        });
      }

      organizationId = defaultOrg.id;
    }

    // Generate ticket number
    const ticketNumber = generateTicketNumber(organizationId);

    // Create ticket
    const ticket = await prisma.ticket.create({
      data: {
        subject,
        description,
        priority: priority.toUpperCase(),
        category: category || null,
        status: 'OPEN',
        customerId: req.userId,
        organizationId,
        // Store ticket number in subject or add a new field if needed
      },
      include: {
        organization: {
          select: {
            id: true,
            name: true
          }
        }
      }
    });

    // TODO: Send confirmation email to customer
    // await mailer.sendTicketConfirmation(req.user.email, ticket);

    res.status(201).json({
      ticketId: ticket.id,
      number: ticketNumber,
      status: ticket.status,
      ticket
    });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({ error: 'Failed to create ticket' });
  }
});

// GET /api/external/tickets/:id - Get ticket details
app.get('/api/external/tickets/:id', requireCustomer, async (req, res) => {
  try {
    const ticketId = req.params.id;

    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId },
      include: {
        organization: {
          select: {
            id: true,
            name: true
          }
        },
        owner: {
          select: {
            id: true,
            name: true,
            email: true
          }
        },
        messages: {
          where: {
            isInternal: false
          },
          orderBy: { createdAt: 'asc' },
          include: {
            author: {
              select: {
                id: true,
                name: true,
                email: true,
                type: true
              }
            }
          }
        }
      }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    // Verify customer owns ticket
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this ticket' });
    }

    res.json(ticket);
  } catch (error) {
    console.error('Get ticket detail error:', error);
    res.status(500).json({ error: 'Failed to retrieve ticket details' });
  }
});

// PUT /api/external/tickets/:id - Update ticket (limited fields)
app.put('/api/external/tickets/:id', requireCustomer, async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { subject, description, priority } = req.body;

    // Get ticket first
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    // Verify customer owns ticket
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to update this ticket' });
    }

    // Only allow updates if status is OPEN
    if (ticket.status !== 'OPEN') {
      return res.status(403).json({ error: 'Only open tickets can be edited' });
    }

    // Build update data
    const updateData = {};
    if (subject) updateData.subject = subject;
    if (description) updateData.description = description;
    if (priority) updateData.priority = priority.toUpperCase();

    // Update ticket
    const updatedTicket = await prisma.ticket.update({
      where: { id: ticketId },
      data: updateData,
      include: {
        organization: {
          select: {
            id: true,
            name: true
          }
        }
      }
    });

    res.json(updatedTicket);
  } catch (error) {
    console.error('Update ticket error:', error);
    res.status(500).json({ error: 'Failed to update ticket' });
  }
});

// Customer Ticket Message Endpoints

// GET /api/external/tickets/:id/messages - Get ticket messages
app.get('/api/external/tickets/:id/messages', requireCustomer, async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { page = '1', limit = '20' } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Verify ticket exists and customer owns it
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this ticket' });
    }

    // Get messages (exclude internal notes)
    const [messages, total] = await Promise.all([
      prisma.ticketMessage.findMany({
        where: {
          ticketId,
          isInternal: false
        },
        orderBy: { createdAt: 'asc' },
        skip,
        take: limitNum,
        include: {
          author: {
            select: {
              id: true,
              name: true,
              email: true,
              type: true
            }
          }
        }
      }),
      prisma.ticketMessage.count({
        where: {
          ticketId,
          isInternal: false
        }
      })
    ]);

    res.json({
      messages,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Failed to retrieve messages' });
  }
});

// POST /api/external/tickets/:id/messages - Add message to ticket
app.post('/api/external/tickets/:id/messages', requireCustomer, async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { content } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Message content is required' });
    }

    // Verify ticket exists and customer owns it
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to add messages to this ticket' });
    }

    // Create message
    const message = await prisma.ticketMessage.create({
      data: {
        content: content.trim(),
        isInternal: false,
        ticketId,
        authorId: req.userId
      },
      include: {
        author: {
          select: {
            id: true,
            name: true,
            email: true,
            type: true
          }
        }
      }
    });

    // Update ticket timestamp
    await prisma.ticket.update({
      where: { id: ticketId },
      data: { updatedAt: new Date() }
    });

    // TODO: Notify assigned agent
    // if (ticket.ownerId) {
    //   await mailer.sendNewMessageNotification(ticket.ownerId, ticket, message);
    // }

    res.status(201).json({
      messageId: message.id,
      createdAt: message.createdAt,
      message
    });
  } catch (error) {
    console.error('Create message error:', error);
    res.status(500).json({ error: 'Failed to add message' });
  }
});

// PUT /api/external/tickets/:id/messages/:msgId - Update message
app.put('/api/external/tickets/:id/messages/:msgId', requireCustomer, async (req, res) => {
  try {
    const { id: ticketId, msgId } = req.params;
    const { content } = req.body;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Message content is required' });
    }

    // Get message
    const message = await prisma.ticketMessage.findUnique({
      where: { id: msgId },
      include: {
        ticket: true
      }
    });

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Verify customer owns the message
    if (message.authorId !== req.userId) {
      return res.status(403).json({ error: 'You can only edit your own messages' });
    }

    // Verify customer owns the ticket
    if (message.ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access this ticket' });
    }

    // Check if message was created within 15 minutes
    const messageAge = Date.now() - new Date(message.createdAt).getTime();
    const fifteenMinutes = 15 * 60 * 1000;

    if (messageAge > fifteenMinutes) {
      return res.status(403).json({ error: 'Messages can only be edited within 15 minutes of creation' });
    }

    // Update message
    const updatedMessage = await prisma.ticketMessage.update({
      where: { id: msgId },
      data: { content: content.trim() },
      include: {
        author: {
          select: {
            id: true,
            name: true,
            email: true,
            type: true
          }
        }
      }
    });

    res.json(updatedMessage);
  } catch (error) {
    console.error('Update message error:', error);
    res.status(500).json({ error: 'Failed to update message' });
  }
});

// Customer Profile Endpoints

// GET /api/external/profile - Get customer profile
app.get('/api/external/profile', requireCustomer, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: {
        customerProfile: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      type: user.type,
      profile: user.customerProfile
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to retrieve profile' });
  }
});

// PUT /api/external/profile - Update customer profile
app.put('/api/external/profile', requireCustomer, async (req, res) => {
  try {
    const { name, phone, companyName, address, city, state, postalCode, country } = req.body;

    // Update user name if provided
    const updateData = {};
    if (name) updateData.name = name;

    if (Object.keys(updateData).length > 0) {
      await prisma.user.update({
        where: { id: req.userId },
        data: updateData
      });
    }

    // Update or create customer profile
    const profileData = {};
    if (phone !== undefined) profileData.phone = phone;
    if (companyName !== undefined) profileData.companyName = companyName;
    if (address !== undefined) profileData.address = address;
    if (city !== undefined) profileData.city = city;
    if (state !== undefined) profileData.state = state;
    if (postalCode !== undefined) profileData.postalCode = postalCode;
    if (country !== undefined) profileData.country = country;

    let profile;
    if (Object.keys(profileData).length > 0) {
      profile = await prisma.customerProfile.upsert({
        where: { userId: req.userId },
        create: {
          userId: req.userId,
          ...profileData
        },
        update: profileData
      });
    } else {
      profile = await prisma.customerProfile.findUnique({
        where: { userId: req.userId }
      });
    }

    // Get updated user
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: {
        customerProfile: true
      }
    });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      type: user.type,
      profile: user.customerProfile
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// PUT /api/external/profile/password - Change password
app.put('/api/external/profile/password', requireCustomer, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }

    // Validate new password strength
    if (newPassword.length < 8) {
      return res.status(400).json({ error: 'New password must be at least 8 characters long' });
    }

    // Get user
    const user = await prisma.user.findUnique({
      where: { id: req.userId }
    });

    if (!user || !user.passwordHash) {
      return res.status(400).json({ error: 'Cannot change password for this account' });
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const newPasswordHash = await bcrypt.hash(newPassword, salt);

    // Update password and increment token version to invalidate all sessions
    await prisma.user.update({
      where: { id: req.userId },
      data: {
        passwordHash: newPasswordHash,
        tokenVersion: {
          increment: 1
        }
      }
    });

    res.json({ success: true, message: 'Password changed successfully. Please log in again.' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// GET /api/external/profile/tickets-summary - Get tickets summary
app.get('/api/external/profile/tickets-summary', requireCustomer, async (req, res) => {
  try {
    const [totalCount, openCount, resolvedCount, closedCount] = await Promise.all([
      prisma.ticket.count({
        where: { customerId: req.userId }
      }),
      prisma.ticket.count({
        where: { customerId: req.userId, status: 'OPEN' }
      }),
      prisma.ticket.count({
        where: { customerId: req.userId, status: 'RESOLVED' }
      }),
      prisma.ticket.count({
        where: { customerId: req.userId, status: 'CLOSED' }
      })
    ]);

    res.json({
      totalCount,
      openCount,
      resolvedCount,
      closedCount,
      inProgressCount: totalCount - openCount - resolvedCount - closedCount
    });
  } catch (error) {
    console.error('Get tickets summary error:', error);
    res.status(500).json({ error: 'Failed to retrieve tickets summary' });
  }
});

// Customer Attachment Endpoints

// POST /api/external/tickets/:id/attachments - Upload attachment
app.post('/api/external/tickets/:id/attachments', requireCustomer, upload.single('file'), async (req, res) => {
  try {
    const ticketId = req.params.id;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Verify ticket exists and customer owns it
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      // Clean up uploaded file
      fs.unlinkSync(req.file.path);
      return res.status(403).json({ error: 'You do not have permission to add attachments to this ticket' });
    }

    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (req.file.size > maxSize) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'File size must not exceed 10MB' });
    }

    // Validate file type
    const allowedMimeTypes = [
      'application/pdf',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain'
    ];

    if (!allowedMimeTypes.includes(req.file.mimetype)) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'File type not allowed. Allowed types: PDF, images, Word, Excel, text files' });
    }

    // Create attachment record
    const attachment = await prisma.attachment.create({
      data: {
        filename: req.file.originalname,
        mimeType: req.file.mimetype,
        url: `/uploads/${req.file.filename}`,
        size: req.file.size,
        uploadedBy: req.userId,
        entityType: 'ticket',
        entityId: ticketId,
        organizationId: ticket.organizationId
      }
    });

    res.status(201).json({
      attachmentId: attachment.id,
      url: attachment.url,
      size: attachment.size,
      filename: attachment.filename,
      mimeType: attachment.mimeType
    });
  } catch (error) {
    console.error('Upload attachment error:', error);
    // Clean up file if it exists
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ error: 'Failed to upload attachment' });
  }
});

// DELETE /api/external/tickets/:id/attachments/:attachmentId - Delete attachment
app.delete('/api/external/tickets/:id/attachments/:attachmentId', requireCustomer, async (req, res) => {
  try {
    const { id: ticketId, attachmentId } = req.params;

    // Get attachment
    const attachment = await prisma.attachment.findUnique({
      where: { id: attachmentId }
    });

    if (!attachment) {
      return res.status(404).json({ error: 'Attachment not found' });
    }

    // Verify ticket exists and customer owns it
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to delete attachments from this ticket' });
    }

    // Verify attachment belongs to this ticket
    if (attachment.entityId !== ticketId || attachment.entityType !== 'ticket') {
      return res.status(403).json({ error: 'Attachment does not belong to this ticket' });
    }

    // Verify customer uploaded the attachment
    if (attachment.uploadedBy !== req.userId) {
      return res.status(403).json({ error: 'You can only delete your own attachments' });
    }

    // Delete file from filesystem
    const filePath = path.join(process.cwd(), 'uploads', path.basename(attachment.url));
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    // Delete attachment record
    await prisma.attachment.delete({
      where: { id: attachmentId }
    });

    res.json({ success: true, message: 'Attachment deleted successfully' });
  } catch (error) {
    console.error('Delete attachment error:', error);
    res.status(500).json({ error: 'Failed to delete attachment' });
  }
});

// GET /api/external/tickets/:id/attachments/:attachmentId - Download attachment
app.get('/api/external/tickets/:id/attachments/:attachmentId', requireCustomer, async (req, res) => {
  try {
    const { id: ticketId, attachmentId } = req.params;

    // Get attachment
    const attachment = await prisma.attachment.findUnique({
      where: { id: attachmentId }
    });

    if (!attachment) {
      return res.status(404).json({ error: 'Attachment not found' });
    }

    // Verify ticket exists and customer owns it
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (ticket.customerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have permission to access attachments from this ticket' });
    }

    // Verify attachment belongs to this ticket
    if (attachment.entityId !== ticketId || attachment.entityType !== 'ticket') {
      return res.status(403).json({ error: 'Attachment does not belong to this ticket' });
    }

    // Get file path
    const filePath = path.join(process.cwd(), 'uploads', path.basename(attachment.url));

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found on server' });
    }

    // Send file
    res.download(filePath, attachment.filename);
  } catch (error) {
    console.error('Download attachment error:', error);
    res.status(500).json({ error: 'Failed to download attachment' });
  }
});

// ====================
// END CUSTOMER PORTAL ROUTES
// ====================

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

// Debug login endpoint (development only) - sign in with email/password
app.post('/auth/debug-login', async (req, res) => {
  try {
    // Check if running in development mode
    if (process.env.NODE_ENV === 'production') {
      return res.status(403).json({ message: 'Debug login not available in production' });
    }

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user by email
    let user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email, tokenVersion: user.tokenVersion || 0 },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Find user's organization (assuming first organization)
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
    // Parse query params for filtering & pagination
    const { page, limit, q, ownerId, city, department } = req.query;
    const _page = parseInt(page) || 1;
    const _limit = Math.min(parseInt(limit) || 1000, 1000);
    const skip = (_page - 1) * _limit;

    const where = { organizationId: req.organizationId };
    // Add optional filters
    if (ownerId) where.ownerId = ownerId;
    if (city) where.city = { equals: city };
    if (department) where.department = { equals: department };
    if (q) {
      const qStr = String(q).toLowerCase();
      // Use OR search across fields
      where.OR = [
        { firstName: { contains: qStr, mode: 'insensitive' } },
        { lastName: { contains: qStr, mode: 'insensitive' } },
        { email: { contains: qStr, mode: 'insensitive' } },
        { phone: { contains: qStr, mode: 'insensitive' } },
        { title: { contains: qStr, mode: 'insensitive' } },
      ];
    }

    // Count total matching records for pagination
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

    const pageNum = _page;
    const pagination = {
      page: pageNum,
      limit: _limit,
      total,
      totalPages: Math.ceil(total / _limit),
      hasNext: pageNum * _limit < total,
      hasPrev: pageNum > 1,
    };

    res.json({ contacts, pagination });
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
    const existing = await prisma.contact.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Contact not found' });
    // prepare old/new for fields provided in body
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => {
      oldValues[k] = existing[k];
      newValues[k] = req.body[k];
    });
    const updated = await prisma.contact.update({ where: { id: req.params.id }, data: req.body });
    await createActivityLogEntry({ action: 'CONTACT_UPDATED', entityType: 'Contact', entityId: updated.id, description: `Contact updated by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    res.json(updated);
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
    await createActivityLogEntry({ action: 'INVITE_CREATED', entityType: 'Invitation', entityId: orgId, description: `${req.user.email} invited ${email} as ${role}`, userId: req.user.id, organizationId: orgId });
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

    // If the client provided an auth header, verify that the auth'd user's email matches the invite email
    const authHeader = req.headers['authorization'];
    if (authHeader) {
      try {
        const authToken = authHeader.split(' ')[1];
        const authPayload = jwt.verify(authToken, JWT_SECRET);
        // If the token resolves to an email that differs, reject — we don't allow accepting invites on behalf of others
        if (authPayload && authPayload.email && authPayload.email !== email) {
          return res.status(403).json({ message: 'Authenticated user does not match invite email' });
        }
      } catch (e) {
        console.error('Invalid authorization token on invite accept:', e);
        return res.status(403).json({ message: 'Invalid authorization token' });
      }
    }
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
    // Also include organization context in response so the web UI can auto-select org after acceptance
    const org = await prisma.organization.findUnique({ where: { id: orgId } });
    res.json({ token: newToken, user: { id: user.id, email: user.email, name: user.name }, organization: org ? { id: org.id, name: org.name } : { id: orgId } , role });
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
      await createActivityLogEntry({ action: 'INVITE_REVOKED', entityType: 'Invitation', entityId: invId, description: `${req.user.email} revoked invite ${inv.email}`, userId: req.user.id, organizationId: inv.organizationId });
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
    await createActivityLogEntry({ action: 'IMPERSONATION', entityType: 'User', entityId: targetUser.id, description: `${req.user.email} impersonated ${targetUser.email}`, userId: req.user.id, organizationId: req.organizationId });
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
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    const status = req.query.status ? String(req.query.status) : null;
    const leadSource = req.query.leadSource ? String(req.query.leadSource) : null;
    const industry = req.query.industry ? String(req.query.industry) : null;

    const prismaFilter = { where: { organizationId: req.organizationId } };

    // Apply search filter
    if (search) {
      prismaFilter.where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { company: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Apply status filter
    if (status) {
      prismaFilter.where.status = status;
    }

    // Apply lead source filter
    if (leadSource) {
      prismaFilter.where.leadSource = leadSource;
    }

    // Apply industry filter
    if (industry) {
      prismaFilter.where.industry = { contains: industry, mode: 'insensitive' };
    }

    const total = await prisma.lead.count(prismaFilter);
    const leads = await prisma.lead.findMany({
      ...prismaFilter,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } }
      }
    });

    return res.json({
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

// Accounts routes: CRUD, paginated list
app.get('/accounts', authenticateToken, requireOrganization, authorize(['VIEW_CONTACTS']), async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    const where = { organizationId: req.organizationId };
    const prismaFilter = { where: { organizationId: req.organizationId } };
    if (search) {
      prismaFilter.where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { type: { contains: search, mode: 'insensitive' } },
      ];
    }
    const total = await prisma.account.count(prismaFilter);
    const accounts = await prisma.account.findMany({
      ...prismaFilter,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });
    return res.json({
      accounts,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      }
    });
  } catch (err) {
    console.error('List accounts error:', err);
    res.status(500).json({ message: err.message });
  }
});

app.post('/accounts', authenticateToken, requireOrganization, authorize(['CREATE_CONTACTS']), validateAccount, async (req, res) => {
  try {
    const data = { ...req.body, organizationId: req.organizationId };
    const acc = await prisma.account.create({ data });
    await createActivityLogEntry({ action: 'ACCOUNT_CREATED', entityType: 'Account', entityId: acc.id, description: `Account ${acc.name} created`, userId: req.user.id, organizationId: req.organizationId });
    res.status(201).json(acc);
  } catch (err) {
    console.error('Create account error:', err);
    res.status(500).json({ message: err.message });
  }
});

app.get('/accounts/:id', authenticateToken, requireOrganization, authorize(['VIEW_CONTACTS']), async (req, res) => {
  try {
    const account = await prisma.account.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!account) return res.status(404).json({ message: 'Account not found' });
    res.json(account);
  } catch (err) {
    console.error('Get account error:', err);
    res.status(500).json({ message: err.message });
  }
});

app.put('/accounts/:id', authenticateToken, requireOrganization, authorize(['EDIT_CONTACTS']), async (req, res) => {
  try {
    const existing = await prisma.account.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Account not found' });
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => {
      oldValues[k] = existing[k];
      newValues[k] = req.body[k];
    });
    const updated = await prisma.account.update({ where: { id: req.params.id }, data: req.body });
    await createActivityLogEntry({ action: 'ACCOUNT_UPDATED', entityType: 'Account', entityId: updated.id, description: `Account updated by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    res.json(updated);
  } catch (err) {
    console.error('Update account error:', err);
    res.status(500).json({ message: err.message });
  }
});

app.delete('/accounts/:id', authenticateToken, requireOrganization, authorize(['DELETE_CONTACTS']), async (req, res) => {
  try {
    const del = await prisma.account.deleteMany({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (del.count === 0) return res.status(404).json({ message: 'Account not found' });
    await createActivityLogEntry({ action: 'ACCOUNT_DELETED', entityType: 'Account', entityId: req.params.id, description: `Account deleted by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId });
    res.json({ message: 'Account deleted' });
  } catch (err) {
    console.error('Delete account error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Activity Logs - list with filtering/paging
app.get('/activity_logs', authenticateToken, requireOrganization, authorize(['VIEW_AUDIT_LOGS']), async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const entityType = req.query.entityType ? String(req.query.entityType) : null;
    const entityId = req.query.entityId ? String(req.query.entityId) : null;
    const userId = req.query.userId ? String(req.query.userId) : null;
    const search = req.query.search ? String(req.query.search) : null;
    const where = { organizationId: req.organizationId };
    const filters = { where: { organizationId: req.organizationId } };
    // Build search filters
    const whereClauses = [];
    if (entityType) whereClauses.push({ entityType });
    if (entityId) whereClauses.push({ entityId });
    if (userId) whereClauses.push({ userId });
    if (search) {
      whereClauses.push({ description: { contains: search, mode: 'insensitive' } });
    }
    if (whereClauses.length > 0) filters.where.AND = whereClauses;

    const total = await prisma.activityLog.count(filters);
    const logs = await prisma.activityLog.findMany({
      ...filters,
      include: { user: { select: { id: true, email: true, name: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });
    // Map to friendly response expected by frontend
    const mapped = await Promise.all(logs.map(async (l) => {
      // Attempt to enrich entity name if possible
      let entityName = null;
      if (l.entityType === 'Account') {
        try {
          const acc = await prisma.account.findUnique({ where: { id: l.entityId } });
          entityName = acc ? acc.name : null;
        } catch (e) {
          entityName = null;
        }
      }
      return {
        id: l.id,
        activityType: l.action || 'Other',
        description: l.description,
        userId: l.userId,
        userName: l.user ? l.user.name || l.user.email : null,
        entityId: l.entityId,
        entityType: l.entityType,
        entityName,
        organizationId: l.organizationId,
        metadata: l.metadata || null,
        oldValues: l.metadata && l.metadata.oldValues ? l.metadata.oldValues : null,
        newValues: l.metadata && l.metadata.newValues ? l.metadata.newValues : null,
        createdAt: l.createdAt,
      };
    }));
    return res.json({ logs: mapped, pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasNext: page * limit < total, hasPrev: page > 1 } });
  } catch (err) {
    console.error('List activity logs error:', err);
    res.status(500).json({ message: err.message });
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
    const existing = await prisma.lead.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Lead not found' });
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { oldValues[k] = existing[k]; newValues[k] = req.body[k]; });
    const updated = await prisma.lead.update({ where: { id: req.params.id }, data: req.body });
    await createActivityLogEntry({ action: 'LEAD_UPDATED', entityType: 'Lead', entityId: updated.id, description: `Lead updated by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    res.json(updated);
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
    // Parse query params for filtering & pagination
    const { page, limit, status, priority, ownerId, overdue, q } = req.query;
    const _page = parseInt(page) || 1;
    const _limit = Math.min(parseInt(limit) || 20, 1000);
    const skip = (_page - 1) * _limit;

    const where = { organizationId: req.organizationId };
    
    // Add optional filters
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (ownerId) where.ownerId = ownerId;
    
    // Overdue filter
    if (overdue === 'true') {
      where.AND = [
        { dueDate: { lt: new Date() } },
        { status: { not: 'Completed' } }
      ];
    }
    
    // Search by subject or description
    if (q) {
      const qStr = String(q).toLowerCase();
      where.OR = [
        { subject: { contains: qStr, mode: 'insensitive' } },
        { description: { contains: qStr, mode: 'insensitive' } }
      ];
    }

    // Count total matching records for pagination
    const total = await prisma.task.count({ where });

    const tasks = await prisma.task.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        contact: { select: { id: true, firstName: true, lastName: true } },
        lead: { select: { id: true, firstName: true, lastName: true } }
      },
      skip,
      take: _limit,
      orderBy: { dueDate: 'asc' }
    });

    const pageNum = _page;
    const pagination = {
      page: pageNum,
      limit: _limit,
      total,
      totalPages: Math.ceil(total / _limit),
      hasNext: pageNum * _limit < total,
      hasPrev: pageNum > 1,
    };

    res.json({ tasks, pagination });
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
    const existing = await prisma.task.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Task not found' });
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { oldValues[k] = existing[k]; newValues[k] = req.body[k]; });
    const updated = await prisma.task.update({ where: { id: req.params.id }, data: req.body });
    await createActivityLogEntry({ action: 'TASK_UPDATED', entityType: 'Task', entityId: updated.id, description: `Task updated by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    res.json(updated);
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
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status ? String(req.query.status).toUpperCase() : undefined;
    const priority = req.query.priority ? String(req.query.priority).toUpperCase() : undefined;
    const ownerId = req.query.ownerId ? String(req.query.ownerId) : undefined;
    const search = req.query.search ? String(req.query.search).toLowerCase() : undefined;

    const skip = (page - 1) * limit;

    // Build where clause
    const where = { organizationId: req.organizationId };
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (ownerId) where.ownerId = ownerId;

    // Fetch tickets
    const tickets = await prisma.ticket.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        messages: {
          include: {
            author: { select: { id: true, name: true, email: true } }
          },
          orderBy: { createdAt: 'asc' }
        }
      },
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });

    // Apply search filter locally if provided
    let filteredTickets = tickets;
    if (search) {
      filteredTickets = tickets.filter(t => 
        t.subject.toLowerCase().includes(search) || 
        (t.description && t.description.toLowerCase().includes(search))
      );
    }

    // Count total
    const total = await prisma.ticket.count({ where });

    res.json({
      tickets: filteredTickets,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    });
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
    const existing = await prisma.ticket.findFirst({ where: { id: req.params.id, organizationId: req.organizationId } });
    if (!existing) return res.status(404).json({ message: 'Ticket not found' });
    const oldValues = {};
    const newValues = {};
    Object.keys(req.body).forEach((k) => { oldValues[k] = existing[k]; newValues[k] = req.body[k]; });
    const updated = await prisma.ticket.update({ where: { id: req.params.id }, data: req.body });
    await createActivityLogEntry({ action: 'TICKET_UPDATED', entityType: 'Ticket', entityId: updated.id, description: `Ticket updated by ${req.user.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Assign ticket to agent
app.post('/tickets/:id/assign', authenticateToken, requireOrganization, authorize(['ASSIGN_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const { assignedToId } = req.body;
    if (!assignedToId) return res.status(400).json({ message: 'assignedToId is required' });
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    // Verify agent exists in organization
    const agentOrg = await prisma.userOrganization.findFirst({ where: { userId: assignedToId, organizationId: req.organizationId } });
    if (!agentOrg) return res.status(400).json({ message: 'Assigned user not in organization' });
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { ownerId: assignedToId } });
    await createActivityLogEntry({ action: 'TICKET_ASSIGNED', entityType: 'Ticket', entityId: updated.id, description: `${req.user.email} assigned ticket to ${assignedToId}`, userId: req.user.id, organizationId: req.organizationId });
    // Create a ticket message recording the assignment
    await prisma.ticketMessage.create({ data: { ticketId: updated.id, authorId: req.user.id, content: `Assigned to user ${assignedToId}`, isInternal: true } });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Resolve ticket (add optional resolution message)
app.post('/tickets/:id/resolve', authenticateToken, requireOrganization, authorize(['RESOLVE_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    const { resolution } = req.body;
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'RESOLVED' } });
    if (resolution) {
      await prisma.ticketMessage.create({ data: { ticketId: ticketId, authorId: req.user.id, content: `Resolution: ${String(resolution)}`, isInternal: true } });
    }
    await createActivityLogEntry({ action: 'TICKET_RESOLVED', entityType: 'Ticket', entityId: updated.id, description: `${req.user.email} resolved ticket ${updated.id}`, userId: req.user.id, organizationId: req.organizationId });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Close ticket
app.post('/tickets/:id/close', authenticateToken, requireOrganization, authorize(['RESOLVE_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'CLOSED' } });
    await createActivityLogEntry({ action: 'TICKET_CLOSED', entityType: 'Ticket', entityId: updated.id, description: `${req.user.email} closed ticket ${updated.id}`, userId: req.user.id, organizationId: req.organizationId });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Reopen ticket
app.post('/tickets/:id/reopen', authenticateToken, requireOrganization, authorize(['EDIT_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    const updated = await prisma.ticket.update({ where: { id: ticketId }, data: { status: 'OPEN' } });
    await createActivityLogEntry({ action: 'TICKET_REOPENED', entityType: 'Ticket', entityId: updated.id, description: `${req.user.email} reopened ticket ${updated.id}`, userId: req.user.id, organizationId: req.organizationId });
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add satisfaction rating to ticket
app.post('/tickets/:id/satisfaction', authenticateToken, requireOrganization, authorize(['VIEW_TICKETS']), async (req, res) => {
  try {
    const ticketId = req.params.id;
    const ticket = await prisma.ticket.findUnique({ where: { id: ticketId } });
    if (!ticket || ticket.organizationId !== req.organizationId) return res.status(404).json({ message: 'Ticket not found' });
    const { rating, feedback } = req.body;
    if (rating == null) return res.status(400).json({ message: 'rating is required' });
    const content = `Satisfaction rating: ${rating}${feedback ? ' • ' + String(feedback) : ''}`;
    const msg = await prisma.ticketMessage.create({ data: { ticketId: ticketId, authorId: req.user.id, content, isInternal: false } });
    await createActivityLogEntry({ action: 'TICKET_SATISFACTION', entityType: 'Ticket', entityId: ticketId, description: `${req.user.email} left satisfaction rating ${rating} for ticket ${ticketId}`, userId: req.user.id, organizationId: req.organizationId });
    res.json({ success: true, message: msg });
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
    const organizations = userOrganizations.map(uo => ({ ...uo.organization, role: uo.role }));
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

    // Attach user's role in organization to response for frontend convenience
    res.json({ ...userOrg.organization, role: userOrg.role });
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
    await createActivityLogEntry({ action: 'USER_ROLE_UPDATED', entityType: 'UserOrganization', entityId: userOrg.id, description: `${req.user.email} changed role for user ${targetUserId} to ${role}`, userId: req.user.id, organizationId: orgId });
    res.json({ success: true });
  } catch (err) {
    console.error('Update user role error:', err);
    res.status(500).json({ message: err.message });
  }
});

  // User Role endpoints (organization-scoped)
  app.get('/user_roles', authenticateToken, requireOrganization, async (req, res) => {
    try {
      const page = Math.max(parseInt(req.query.page || '1', 10), 1);
      const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
      const total = await prisma.userRole.count({ where: { organizationId: req.organizationId } });
      let roles = await prisma.userRole.findMany({ where: { organizationId: req.organizationId }, skip: (page - 1) * limit, take: limit, orderBy: { createdAt: 'desc' } });
      roles = roles.map(r => ({ ...r, permissions: (r.permissions || []).map(p => String(p).toLowerCase()) }));
      return res.json({ roles, pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasNext: page * limit < total, hasPrev: page > 1 } });
    } catch (err) {
      console.error('List roles error:', err);
      res.status(500).json({ message: err.message });
    }
  });

  app.post('/user_roles', authenticateToken, requireOrganization, authorize(['MANAGE_ROLES']), async (req, res) => {
    try {
      const { name, description, roleType, permissions, isDefault, isActive } = req.body;
      if (!name) return res.status(400).json({ message: 'Name is required' });
      const normalizedRoleType = normalizeRoleType(roleType);
      if (!normalizedRoleType) return res.status(400).json({ message: 'Invalid roleType' });
      const perms = normalizePermissionsArray(permissions);
      if (perms === null) return res.status(400).json({ message: 'Invalid permissions array' });
      const created = await prisma.userRole.create({ data: { name, description, roleType: normalizedRoleType, permissions: perms, organizationId: req.organizationId, isDefault: !!isDefault, isActive: isActive !== false } });
      await createActivityLogEntry({ action: 'ROLE_CREATED', entityType: 'UserRole', entityId: created.id, description: `${req.user.email} created role ${created.name}`, userId: req.user.id, organizationId: req.organizationId });
      created.permissions = (created.permissions || []).map(p => String(p).toLowerCase());
      res.status(201).json(created);
    } catch (err) {
      console.error('Create role error:', err);
      res.status(500).json({ message: err.message });
    }
  });

  app.put('/user_roles/:id', authenticateToken, requireOrganization, authorize(['MANAGE_ROLES']), async (req, res) => {
    try {
      const id = req.params.id;
      const existing = await prisma.userRole.findUnique({ where: { id } });
      if (!existing || existing.organizationId !== req.organizationId) return res.status(404).json({ message: 'Role not found' });
      const data = {};
      if (req.body.name) data.name = req.body.name;
      if (req.body.description !== undefined) data.description = req.body.description;
      if (req.body.roleType) {
        const normalized = normalizeRoleType(req.body.roleType);
        if (!normalized) return res.status(400).json({ message: 'Invalid roleType' });
        data.roleType = normalized;
      }
      if (req.body.permissions !== undefined) {
        const perms2 = normalizePermissionsArray(req.body.permissions);
        if (perms2 === null) return res.status(400).json({ message: 'Invalid permissions array' });
        data.permissions = perms2;
      }
      if (req.body.isDefault !== undefined) data.isDefault = !!req.body.isDefault;
      if (req.body.isActive !== undefined) data.isActive = !!req.body.isActive;
      const updated = await prisma.userRole.update({ where: { id }, data });
      const oldValues = { name: existing.name, roleType: existing.roleType, permissions: existing.permissions, description: existing.description, isDefault: existing.isDefault, isActive: existing.isActive };
      const newValues = { ...data };
      await createActivityLogEntry({ action: 'ROLE_UPDATED', entityType: 'UserRole', entityId: updated.id, description: `${req.user.email} updated role ${updated.name}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
      res.json(updated);
    } catch (err) {
      console.error('Update role error:', err);
      res.status(500).json({ message: err.message });
    }
  });

  app.delete('/user_roles/:id', authenticateToken, requireOrganization, authorize(['MANAGE_ROLES']), async (req, res) => {
    try {
      const id = req.params.id;
      const existing = await prisma.userRole.findUnique({ where: { id } });
      if (!existing || existing.organizationId !== req.organizationId) return res.status(404).json({ message: 'Role not found' });
      if (existing.isDefault) return res.status(400).json({ message: 'Cannot delete default role' });
      await prisma.userRole.delete({ where: { id } });
      await createActivityLogEntry({ action: 'ROLE_DELETED', entityType: 'UserRole', entityId: id, description: `${req.user.email} deleted role ${existing.name}`, userId: req.user.id, organizationId: req.organizationId });
      res.json({ success: true });
    } catch (err) {
      console.error('Delete role error:', err);
      res.status(500).json({ message: err.message });
    }
  });

// Users endpoints
// List users (paginated) - require organization scope
app.get('/users', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.max(parseInt(req.query.limit || '20', 10), 1);
    const search = req.query.search ? String(req.query.search) : null;
    const where = { organizationId: req.organizationId };
    const filter = { where: { organizationId: req.organizationId } };
    if (search) {
      filter.where.OR = [
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { name: { contains: search, mode: 'insensitive' } } }
      ];
    }
    // join userOrganization to list users within organization
    const total = await prisma.userOrganization.count({ where: filter.where });
    const userOrgs = await prisma.userOrganization.findMany({
      where: filter.where,
      include: { user: true },
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { joinedAt: 'desc' }
    });
    const users = userOrgs.map(uo => ({ ...uo.user, role: uo.role }));
    return res.json({ users, pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasNext: page * limit < total, hasPrev: page > 1 } });
  } catch (err) {
    console.error('List users error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create user
app.post('/users', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const { email, name, role, isActive } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });
    // If user exists, return 409
    let user = await prisma.user.findUnique({ where: { email } });
    if (user) return res.status(409).json({ message: 'User already exists' });
    user = await prisma.user.create({ data: { email, name, isActive: isActive !== false } });
    // Associate user into organization
    await prisma.userOrganization.create({ data: { userId: user.id, organizationId: req.organizationId, role: role || 'VIEWER' } });
    await createActivityLogEntry({ action: 'USER_CREATED', entityType: 'User', entityId: user.id, description: `${req.user.email} created user ${user.email}`, userId: req.user.id, organizationId: req.organizationId });
    // Optionally send a welcome email for newly created users
    try {
      if (process.env.SEND_WELCOME_EMAILS === 'true') {
        await mailer.sendWelcomeEmail(user.email, user.name, (await prisma.organization.findUnique({ where: { id: req.organizationId } })).name);
      }
    } catch (e) {
      console.warn('Failed to send welcome email', e);
      // don't fail the request if sending email fails
    }
    res.status(201).json(user);
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Get user by id (org scoped)
app.get('/users/:id', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const uo = await prisma.userOrganization.findFirst({ where: { userId: req.params.id, organizationId: req.organizationId }, include: { user: true } });
    if (!uo) return res.status(404).json({ message: 'User not found in organization' });
    const user = { ...uo.user, role: uo.role };
    res.json(user);
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Update user info
app.put('/users/:id', authenticateToken, requireOrganization, async (req, res) => {
  try {
    const targetUserId = req.params.id;
    
    // If not the same user, must have MANAGE_USERS
    if (req.user.id !== targetUserId) {
      const perms = await getUserPermissions(req.user.id, req.organizationId);
      if (!perms.includes('MANAGE_USERS')) return res.status(403).json({ message: 'Forbidden' });
    }
    const existing = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!existing) return res.status(404).json({ message: 'User not found' });
    
    // Get current role from UserOrganization
    const existingUserOrg = await prisma.userOrganization.findFirst({ where: { userId: targetUserId, organizationId: req.organizationId } });
    const currentRole = existingUserOrg?.role;
    
    // Filter out read-only fields that shouldn't be updated directly
    const data = { ...req.body };
    delete data.id;
    delete data.createdAt;
    delete data.updatedAt;
    delete data.tokenVersion;
    delete data.googleId;
    delete data.permissions;
    
    // If role is provided AND it's different from current role, update it
    if (data.role && data.role !== currentRole) {
      const role = data.role;
      delete data.role;
      await prisma.userOrganization.updateMany({ where: { userId: targetUserId, organizationId: req.organizationId }, data: { role } });
      await prisma.user.update({ where: { id: targetUserId }, data: { tokenVersion: { increment: 1 } } });
      await createActivityLogEntry({ action: 'USER_ROLE_UPDATED', entityType: 'UserOrganization', entityId: targetUserId, description: `${req.user.email} changed role for user ${targetUserId} to ${role}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues: { role: currentRole }, newValues: { role } } });
    } else {
      // Role wasn't changed, remove it from data
      delete data.role;
    }
    
    // Only set updatedAt if there are actual changes
    if (Object.keys(data).length > 0) {
      data.updatedAt = new Date();
    }
    
    // Update user info (only if there are changes)
    let updated = existing;
    if (Object.keys(data).length > 0) {
      updated = await prisma.user.update({ where: { id: targetUserId }, data });
    }
    
    // Re-fetch with organization role included
    const uo = await prisma.userOrganization.findFirst({ where: { userId: targetUserId, organizationId: req.organizationId }, include: { user: true } });
    const userWithRole = uo ? { ...uo.user, role: uo.role } : { ...updated, role: 'VIEWER' };
    
    // Capture old/new for audit
    const oldValues = { name: existing.name, email: existing.email, isActive: existing.isActive, profileImage: existing.profileImage };
    const newValues = { ...data };
    await createActivityLogEntry({ action: 'USER_UPDATED', entityType: 'User', entityId: updated.id, description: `${req.user.email} updated user ${updated.email}`, userId: req.user.id, organizationId: req.organizationId, metadata: { oldValues, newValues } });
    userWithRole.permissions = (userWithRole.permissions || []).map(p => String(p).toLowerCase());
    res.json(userWithRole);
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Delete user (remove association or delete user)
app.delete('/users/:id', authenticateToken, requireOrganization, authorize(['MANAGE_USERS']), async (req, res) => {
  try {
    const targetUserId = req.params.id;
    // Delete user association for this organization
    const del = await prisma.userOrganization.deleteMany({ where: { userId: targetUserId, organizationId: req.organizationId } });
    if (del.count === 0) return res.status(404).json({ message: 'User not found in organization' });
    await createActivityLogEntry({ action: 'USER_DELETED', entityType: 'User', entityId: targetUserId, description: `${req.user.email} removed user ${targetUserId} from org`, userId: req.user.id, organizationId: req.organizationId });
    res.json({ message: 'User removed from organization' });
  } catch (err) {
    console.error('Delete user error:', err);
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
    const [contactCount, leadCount, taskCount, ticketCount, usersCount, accountCount] = await Promise.all([
      prisma.contact.count({ where: { organizationId: req.organizationId } }),
      prisma.lead.count({ where: { organizationId: req.organizationId } }),
      prisma.task.count({ where: { organizationId: req.organizationId } }),
      prisma.ticket.count({ where: { organizationId: req.organizationId } }),
      prisma.userOrganization.count({ where: { organizationId: req.organizationId } }),
      prisma.account.count({ where: { organizationId: req.organizationId } })
    ]);

    // Get counts for organizations (system-wide metric)
    const organizationsCount = await prisma.organization.count();

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

    // Build a map of ticket status counts for convenient lookup
    const ticketsByStatus = {};
    ticketStats.forEach((s) => { ticketsByStatus[s.status] = s._count.status; });

    // Tickets by priority
    const ticketPriorityStats = await prisma.ticket.groupBy({
      by: ['priority'],
      where: { organizationId: req.organizationId },
      _count: { priority: true }
    });

    // Tickets by agent (owner)
    const ticketsByAgentRaw = await prisma.ticket.groupBy({
      by: ['ownerId'],
      where: { organizationId: req.organizationId },
      _count: { ownerId: true }
    });
    const ticketsByAgent = {};
    ticketsByAgentRaw.forEach(a => { ticketsByAgent[a.ownerId || 'unassigned'] = a._count.ownerId; });

    // Calculate ticket load: open tickets per assigned agent (agents & managers)
    const openTickets = ticketsByStatus['OPEN'] ?? ticketsByStatus['Open'] ?? ticketsByStatus['open'] ?? 0;
    const agentCount = await prisma.userOrganization.count({ where: { organizationId: req.organizationId, role: { in: ['AGENT', 'MANAGER'] } } });
    const ticketLoad = agentCount > 0 ? (openTickets / agentCount) : openTickets;

    // Tasks overdue
    const now = new Date();
    const overdueTasks = await prisma.task.count({ where: { organizationId: req.organizationId, dueDate: { lt: now }, status: { not: 'COMPLETED' } } });

    // Weekly metrics - start of week (UTC)
    const weekStart = new Date();
    weekStart.setUTCHours(0,0,0,0);
    // Move to Monday (ISO week: Monday start)
    const day = weekStart.getUTCDay();
    const diffToMonday = (day + 6) % 7; // 0 (Sunday) -> 6, 1 -> 0, etc
    weekStart.setUTCDate(weekStart.getUTCDate() - diffToMonday);

    const leadsThisWeek = await prisma.lead.count({ where: { organizationId: req.organizationId, createdAt: { gte: weekStart } } });
    const ticketsResolvedThisWeek = await prisma.ticket.count({ where: { organizationId: req.organizationId, status: 'RESOLVED', updatedAt: { gte: weekStart } } });
    const tasksCompletedThisWeekRaw = await prisma.task.groupBy({
      by: ['ownerId'],
      where: { organizationId: req.organizationId, status: 'COMPLETED', updatedAt: { gte: weekStart } },
      _count: { ownerId: true }
    });
    const tasksCompletedByAgent = {};
    tasksCompletedThisWeekRaw.forEach(r => { tasksCompletedByAgent[r.ownerId || 'unassigned'] = r._count.ownerId; });

    // Active users in last 7 days (unique activity log userId count)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 7);
    const activeUsersRaw = await prisma.activityLog.groupBy({ by: ['userId'], where: { organizationId: req.organizationId, createdAt: { gte: sevenDaysAgo }, userId: { not: null } } , _count: { userId: true } });
    const activeUsersThisWeek = activeUsersRaw.length;

    res.json({
      counts: {
        contacts: contactCount,
        leads: leadCount,
        tasks: taskCount,
        tickets: ticketCount,
        users: usersCount,
        accounts: accountCount,
      },
      organizationsCount,
      overdueTasks,
      recentActivities,
      ticketLoad,
      activeUsersThisWeek,
      taskStats,
      leadStats,
      ticketStats,
      ticketPriorityStats,
      ticketsByAgent,
      weeklyMetrics: {
        leadsThisWeek,
        ticketsResolvedThisWeek,
        tasksCompletedByAgent
      }
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