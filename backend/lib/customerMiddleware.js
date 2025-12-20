import { verifyToken, verifyCustomerUser } from './customerAuth.js';
import prisma from './prismaClient.js';

/**
 * Extract token from Authorization header
 * @param {object} req - Express request object
 * @returns {string|null} Token or null
 */
function extractToken(req) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return null;
  }

  // Expected format: "Bearer <token>"
  const parts = authHeader.split(' ');
  
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Middleware to verify customer token and attach user to request
 * @param {object} req - Express request
 * @param {object} res - Express response
 * @param {function} next - Next middleware
 */
export async function verifyCustomerToken(req, res, next) {
  try {
    const token = extractToken(req);

    if (!token) {
      return res.status(401).json({
        error: 'No authorization token provided'
      });
    }

    // Verify token
    const decoded = verifyToken(token);

    if (!decoded) {
      return res.status(401).json({
        error: 'Invalid or expired token'
      });
    }

    // Verify user exists and is a customer
    try {
      const user = await verifyCustomerUser(decoded.userId);
      
      // Attach user to request
      req.user = user;
      req.userId = user.id;
      
      next();
    } catch (error) {
      return res.status(401).json({
        error: error.message
      });
    }
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(500).json({
      error: 'Internal server error during authentication'
    });
  }
}

/**
 * Middleware to ensure authenticated customer
 * This is an alias for verifyCustomerToken for clarity
 */
export const requireCustomer = verifyCustomerToken;

/**
 * Middleware to verify customer owns a ticket
 * Must be used after verifyCustomerToken
 * @param {object} req - Express request
 * @param {object} res - Express response
 * @param {function} next - Next middleware
 */
export async function customerOwnsTicket(req, res, next) {
  try {
    // Ensure user is authenticated
    if (!req.user || !req.userId) {
      return res.status(401).json({
        error: 'Authentication required'
      });
    }

    const ticketId = req.params.id || req.params.ticketId;

    if (!ticketId) {
      return res.status(400).json({
        error: 'Ticket ID is required'
      });
    }

    // Find ticket
    const ticket = await prisma.ticket.findUnique({
      where: { id: ticketId }
    });

    if (!ticket) {
      return res.status(404).json({
        error: 'Ticket not found'
      });
    }

    // Verify customer owns the ticket
    if (ticket.customerId !== req.userId) {
      return res.status(403).json({
        error: 'You do not have permission to access this ticket'
      });
    }

    // Attach ticket to request for convenience
    req.ticket = ticket;

    next();
  } catch (error) {
    console.error('Ticket ownership verification error:', error);
    return res.status(500).json({
      error: 'Internal server error'
    });
  }
}

/**
 * Middleware to verify customer owns their profile
 * Must be used after verifyCustomerToken
 * This is mostly a safety check since customers can only access their own profile
 */
export async function customerOwnsProfile(req, res, next) {
  try {
    // Ensure user is authenticated
    if (!req.user || !req.userId) {
      return res.status(401).json({
        error: 'Authentication required'
      });
    }

    // For profile routes, the user always accesses their own profile
    // This middleware is a safety check
    const profileUserId = req.params.userId;

    // If no userId in params, they're accessing their own profile (default)
    if (!profileUserId || profileUserId === req.userId) {
      return next();
    }

    // If they're trying to access someone else's profile
    return res.status(403).json({
      error: 'You can only access your own profile'
    });
  } catch (error) {
    console.error('Profile ownership verification error:', error);
    return res.status(500).json({
      error: 'Internal server error'
    });
  }
}

/**
 * Middleware to verify customer owns a message
 * Must be used after verifyCustomerToken
 */
export async function customerOwnsMessage(req, res, next) {
  try {
    // Ensure user is authenticated
    if (!req.user || !req.userId) {
      return res.status(401).json({
        error: 'Authentication required'
      });
    }

    const messageId = req.params.msgId || req.params.messageId;

    if (!messageId) {
      return res.status(400).json({
        error: 'Message ID is required'
      });
    }

    // Find message
    const message = await prisma.ticketMessage.findUnique({
      where: { id: messageId },
      include: {
        ticket: true
      }
    });

    if (!message) {
      return res.status(404).json({
        error: 'Message not found'
      });
    }

    // Verify customer owns the message
    if (message.authorId !== req.userId) {
      return res.status(403).json({
        error: 'You do not have permission to modify this message'
      });
    }

    // Verify customer owns the ticket (double check)
    if (message.ticket.customerId !== req.userId) {
      return res.status(403).json({
        error: 'You do not have permission to access this ticket'
      });
    }

    // Check if message was created recently (within 15 minutes)
    const messageAge = Date.now() - new Date(message.createdAt).getTime();
    const fifteenMinutes = 15 * 60 * 1000;

    if (messageAge > fifteenMinutes) {
      return res.status(403).json({
        error: 'Messages can only be edited within 15 minutes of creation'
      });
    }

    // Attach message to request
    req.message = message;

    next();
  } catch (error) {
    console.error('Message ownership verification error:', error);
    return res.status(500).json({
      error: 'Internal server error'
    });
  }
}

/**
 * Optional authentication middleware - attaches user if token is valid, but doesn't require it
 */
export async function optionalCustomerAuth(req, res, next) {
  try {
    const token = extractToken(req);

    if (!token) {
      return next();
    }

    const decoded = verifyToken(token);

    if (!decoded) {
      return next();
    }

    try {
      const user = await verifyCustomerUser(decoded.userId);
      req.user = user;
      req.userId = user.id;
    } catch (error) {
      // Silently fail - user object won't be attached
    }

    next();
  } catch (error) {
    // Silently fail - continue without authentication
    next();
  }
}
