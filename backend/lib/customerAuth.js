import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from './prismaClient.js';

const JWT_SECRET = process.env.JWT_SECRET;
const ACCESS_TOKEN_EXPIRY = '15m'; // 15 minutes
const REFRESH_TOKEN_EXPIRY = '7d'; // 7 days

if (!JWT_SECRET) {
  console.warn('JWT_SECRET not set in environment variables. Using default (INSECURE)');
}

/**
 * Hash a password using bcrypt
 * @param {string} password - Plain text password
 * @returns {Promise<string>} Hashed password
 */
export async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

/**
 * Compare a plain text password with a hashed password
 * @param {string} password - Plain text password
 * @param {string} hashedPassword - Hashed password
 * @returns {Promise<boolean>} True if passwords match
 */
export async function comparePassword(password, hashedPassword) {
  return bcrypt.compare(password, hashedPassword);
}

/**
 * Generate JWT access token
 * @param {object} user - User object
 * @returns {string} JWT token
 */
export function generateAccessToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      type: user.type,
      tokenVersion: user.tokenVersion
    },
    JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );
}

/**
 * Generate JWT refresh token
 * @param {object} user - User object
 * @returns {string} JWT refresh token
 */
export function generateRefreshToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      type: user.type,
      tokenVersion: user.tokenVersion
    },
    JWT_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );
}

/**
 * Verify JWT token
 * @param {string} token - JWT token
 * @returns {object|null} Decoded token or null if invalid
 */
export function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

/**
 * Register a new customer
 * @param {object} data - Registration data
 * @returns {Promise<object>} Created user and tokens
 */
export async function registerCustomer({ email, password, name, companyName, phone }) {
  // Validate required fields
  if (!email || !password || !name) {
    throw new Error('Email, password, and name are required');
  }

  // Normalize email to lowercase
  const normalizedEmail = email.toLowerCase().trim();

  // Check if user already exists
  const existingUser = await prisma.user.findUnique({
    where: { email: normalizedEmail }
  });

  if (existingUser) {
    throw new Error('User with this email already exists');
  }

  // Hash password
  const passwordHash = await hashPassword(password);

  // Create user and customer profile in a transaction
  const user = await prisma.user.create({
    data: {
      email: normalizedEmail,
      name,
      passwordHash,
      type: 'CUSTOMER',
      customerProfile: {
        create: {
          companyName: companyName || null,
          phone: phone || null
        }
      }
    },
    include: {
      customerProfile: true
    }
  });

  // Generate tokens
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  return {
    userId: user.id,
    token: accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      companyName: user.customerProfile?.companyName || null,
      phone: user.customerProfile?.phone || null,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString()
    }
  };
}

/**
 * Login a customer
 * @param {object} credentials - Login credentials
 * @returns {Promise<object>} User and tokens
 */
export async function loginCustomer({ email, password }) {
  // Validate required fields
  if (!email || !password) {
    throw new Error('Email and password are required');
  }

  // Normalize email to lowercase
  const normalizedEmail = email.toLowerCase().trim();

  // Find user by email
  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    include: {
      customerProfile: true
    }
  });

  if (!user) {
    throw new Error('Invalid email or password');
  }

  // Check if user is a customer
  if (user.type !== 'CUSTOMER') {
    throw new Error('Invalid email or password');
  }

  // Check if user is active
  if (!user.isActive) {
    throw new Error('Account is inactive. Please contact support.');
  }

  // Verify password
  if (!user.passwordHash) {
    throw new Error('Invalid email or password');
  }

  const isPasswordValid = await comparePassword(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new Error('Invalid email or password');
  }

  // Generate tokens
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  return {
    token: accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      companyName: user.customerProfile?.companyName || null,
      phone: user.customerProfile?.phone || null,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString()
    }
  };
}

/**
 * Refresh access token using refresh token
 * @param {string} refreshToken - Refresh token
 * @returns {Promise<object>} New access token
 */
export async function refreshAccessToken(refreshToken) {
  // Verify refresh token
  const decoded = verifyToken(refreshToken);
  
  if (!decoded) {
    throw new Error('Invalid or expired refresh token');
  }

  // Find user
  const user = await prisma.user.findUnique({
    where: { id: decoded.userId }
  });

  if (!user) {
    throw new Error('User not found');
  }

  // Check if user is active
  if (!user.isActive) {
    throw new Error('Account is inactive');
  }

  // Check token version (for token invalidation)
  if (user.tokenVersion !== decoded.tokenVersion) {
    throw new Error('Token has been invalidated');
  }

  // Generate new access token
  const newAccessToken = generateAccessToken(user);

  return {
    token: newAccessToken
  };
}

/**
 * Verify if a user exists and is a valid customer
 * @param {string} userId - User ID
 * @returns {Promise<object>} User data
 */
export async function verifyCustomerUser(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      customerProfile: true
    }
  });

  if (!user) {
    throw new Error('User not found');
  }

  if (user.type !== 'CUSTOMER') {
    throw new Error('User is not a customer');
  }

  if (!user.isActive) {
    throw new Error('Account is inactive');
  }

  return {
    id: user.id,
    email: user.email,
    name: user.name,
    companyName: user.customerProfile?.companyName || null,
    phone: user.customerProfile?.phone || null,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString()
  };
}

/**
 * Invalidate all tokens for a user (logout all sessions)
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 */
export async function invalidateUserTokens(userId) {
  await prisma.user.update({
    where: { id: userId },
    data: {
      tokenVersion: {
        increment: 1
      }
    }
  });
}
