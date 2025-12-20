/**
 * Customer Authentication Routes
 * Handles customer registration, login, and profile management
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { autoMatchOrganization } = require('../lib/organizationMatcher');

const prisma = new PrismaClient();

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '7d';

/**
 * POST /api/external/auth/register
 * Register a new customer
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, companyName, phone } = req.body;

    // Validation
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Auto-match organization
    const matchedOrganization = await autoMatchOrganization(email, companyName);

    // Create user and customer profile in transaction
    const result = await prisma.$transaction(async (tx) => {
      // Create user
      const user = await tx.user.create({
        data: {
          email: email.toLowerCase(),
          name,
          passwordHash,
          type: 'CUSTOMER',
          isActive: true,
        },
      });

      // Create customer profile
      const customerProfile = await tx.customerProfile.create({
        data: {
          userId: user.id,
          organizationId: matchedOrganization?.id || null,
          companyName: companyName || null,
          phone: phone || null,
        },
      });

      // Log the registration
      if (matchedOrganization) {
        await tx.activityLog.create({
          data: {
            action: 'CUSTOMER_REGISTERED',
            entityType: 'User',
            entityId: user.id,
            description: `Customer ${name} registered and auto-matched to ${matchedOrganization.name}`,
            userId: user.id,
            organizationId: matchedOrganization.id,
            metadata: {
              email: user.email,
              autoMatched: true,
            },
          },
        });
      }

      return { user, customerProfile };
    });

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: result.user.id,
        email: result.user.email,
        type: result.user.type,
        organizationId: matchedOrganization?.id || null,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user: {
        id: result.user.id,
        email: result.user.email,
        name: result.user.name,
        type: result.user.type,
      },
      profile: {
        id: result.customerProfile.id,
        companyName: result.customerProfile.companyName,
        organizationId: result.customerProfile.organizationId,
        organizationName: matchedOrganization?.name || null,
        autoMatched: !!matchedOrganization,
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

/**
 * POST /api/external/auth/login
 * Customer login
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      include: {
        customerProfile: {
          include: {
            organization: true,
          },
        },
      },
    });

    if (!user || user.type !== 'CUSTOMER') {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (!user.isActive) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    if (!user.passwordHash) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user.id,
        email: user.email,
        type: user.type,
        organizationId: user.customerProfile?.organizationId || null,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        type: user.type,
      },
      profile: {
        id: user.customerProfile?.id,
        companyName: user.customerProfile?.companyName,
        organizationId: user.customerProfile?.organizationId,
        organizationName: user.customerProfile?.organization?.name || null,
        phone: user.customerProfile?.phone,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

/**
 * GET /api/external/auth/me
 * Get current customer profile
 */
router.get('/me', async (req, res) => {
  try {
    // Extract token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET);

    // Get user with profile
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: {
        customerProfile: {
          include: {
            organization: true,
          },
        },
      },
    });

    if (!user || user.type !== 'CUSTOMER') {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        type: user.type,
      },
      profile: {
        id: user.customerProfile?.id,
        companyName: user.customerProfile?.companyName,
        organizationId: user.customerProfile?.organizationId,
        organizationName: user.customerProfile?.organization?.name || null,
        phone: user.customerProfile?.phone,
        address: user.customerProfile?.address,
        city: user.customerProfile?.city,
        state: user.customerProfile?.state,
        postalCode: user.customerProfile?.postalCode,
        country: user.customerProfile?.country,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

module.exports = router;
