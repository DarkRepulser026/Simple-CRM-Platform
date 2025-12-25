import jwt from 'jsonwebtoken';
import prisma from '../lib/prismaClient.js';

const JWT_SECRET = process.env.JWT_SECRET;

export const authenticateToken = async (req, res, next) => {
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
