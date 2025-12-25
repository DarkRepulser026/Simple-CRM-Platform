import express from 'express';
import staffAuthRoutes from './staffAuth.js';
import inviteRoutes from './invites.js';

const router = express.Router();

router.use('/staff', staffAuthRoutes);
router.use('/invites', inviteRoutes);

export default router;
