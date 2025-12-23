import express from 'express';
import organizationsRouter from './organizations.js';
import usersRouter from './users.js';
import rolesRouter from './roles.js';
import customersRouter from './customers.js';
import domainMappingsRouter from './domainMappings.js';

const router = express.Router();

router.use('/organizations', organizationsRouter);
router.use('/users', usersRouter);
router.use('/roles', rolesRouter);
router.use('/customers', customersRouter);
router.use('/domain-mappings', domainMappingsRouter);

export default router;
