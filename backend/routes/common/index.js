import express from 'express';
import attachmentRoutes from './attachments.js';
import activityLogRoutes from './activityLogs.js';
import dashboardRoutes from './dashboard.js';

const router = express.Router();

router.use('/attachments', attachmentRoutes);
router.use('/activity_logs', activityLogRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;
