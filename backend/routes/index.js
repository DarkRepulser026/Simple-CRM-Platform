import express from 'express';
import authRoutes from './auth/index.js';
import crmRoutes from './crm/index.js';
import ticketRoutes from './tickets/index.js';
import adminRoutes from './admin/index.js';
import commonRoutes from './common/index.js';

const router = express.Router();

// Auth routes
router.use('/auth', authRoutes);

// CRM routes
router.use('/crm', crmRoutes);

// Ticket routes
router.use('/tickets', ticketRoutes);

// Admin routes
router.use('/admin', adminRoutes);

// Legacy Auth aliases for tests
router.post('/auth/google', (req, res, next) => {
  req.url = '/staff/google';
  authRoutes(req, res, next);
});
router.post('/auth/login', (req, res, next) => {
  req.url = '/staff/login';
  authRoutes(req, res, next);
});
router.post('/auth/register', (req, res, next) => {
  req.url = '/staff/register';
  authRoutes(req, res, next);
});

// Common routes (attachments, activity logs)
router.use('/', commonRoutes);

export default router;
