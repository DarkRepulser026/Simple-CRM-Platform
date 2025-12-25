import express from 'express';
import staffRoutes from './staff.js';

const router = express.Router();

router.use('/staff', staffRoutes);

export default router;
