import express from 'express';
import staffRoutes from './staff.js';
import customerRoutes from './customer.js';

const router = express.Router();

router.use('/staff', staffRoutes);
router.use('/customer', customerRoutes);

export default router;
