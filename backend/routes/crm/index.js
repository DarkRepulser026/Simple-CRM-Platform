import express from 'express';
import contactsRouter from './contacts.js';
import leadsRouter from './leads.js';
import accountsRouter from './accounts.js';
import tasksRouter from './tasks.js';
import ticketsRouter from './tickets.js';
import dashboardRouter from './dashboard.js';

const router = express.Router();

router.use('/contacts', contactsRouter);
router.use('/leads', leadsRouter);
router.use('/accounts', accountsRouter);
router.use('/tasks', tasksRouter);
router.use('/tickets', ticketsRouter);
router.use('/dashboard', dashboardRouter);

export default router;
