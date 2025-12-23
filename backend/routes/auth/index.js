import express from 'express';
import staffAuthRoutes from './staffAuth.js';
import customerAuthRoutes from './customerAuth.js';
import customerProfileRoutes from './customerProfile.js';
import inviteRoutes from './invites.js';

const router = express.Router();

router.use('/staff', staffAuthRoutes);
router.use('/customer', customerAuthRoutes);
router.use('/customer/profile', customerProfileRoutes);
router.use('/invites', inviteRoutes);

export default router;
