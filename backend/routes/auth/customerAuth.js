import express from 'express';
import { registerCustomer, loginCustomer, refreshAccessToken, invalidateUserTokens } from '../../lib/customerAuth.js';
import { requireCustomer } from '../../lib/customerMiddleware.js';
import { customerAuthLimiter } from '../../middleware/rateLimiter.js';

const router = express.Router();

// POST /register - Register new customer
router.post('/register', customerAuthLimiter, async (req, res) => {
  try {
    const { email, password, name, companyName, phone } = req.body;
    const result = await registerCustomer({ email, password, name, companyName, phone });
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

// POST /login - Login customer
router.post('/login', customerAuthLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await loginCustomer({ email, password });
    res.json(result);
  } catch (error) {
    console.error('Customer login error:', error);
    if (error.message === 'Invalid email or password' || error.message.includes('inactive')) {
      return res.status(401).json({ error: error.message });
    }
    if (error.message.includes('required')) {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// POST /refresh - Refresh access token
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }
    const result = await refreshAccessToken(refreshToken);
    res.json(result);
  } catch (error) {
    console.error('Token refresh error:', error);
    if (error.message.includes('Invalid') || error.message.includes('expired') || error.message.includes('invalidated')) {
      return res.status(401).json({ error: error.message });
    }
    res.status(500).json({ error: 'Token refresh failed. Please try again.' });
  }
});

// POST /logout - Logout customer
router.post('/logout', requireCustomer, async (req, res) => {
  try {
    await invalidateUserTokens(req.userId);
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Logout failed. Please try again.' });
  }
});

// GET /verify - Verify current token
router.get('/verify', requireCustomer, async (req, res) => {
  try {
    res.json({ isValid: true, user: req.user });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

export default router;
