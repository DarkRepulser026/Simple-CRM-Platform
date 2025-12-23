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

// Common routes (attachments, activity logs)
router.use('/', commonRoutes);

export default router;
