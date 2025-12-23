import dotenv from 'dotenv';
import app from './app.js';
import prisma from './lib/prismaClient.js';

dotenv.config();

const PORT = process.env.PORT || 3001;

// Initialize default roles for organizations that don't have them
async function initializeDefaultRoles() {
  try {
    const orgs = await prisma.organization.findMany();
    
    for (const org of orgs) {
      const adminRole = await prisma.userRole.findFirst({
        where: { organizationId: org.id, roleType: 'ADMIN' }
      });
      
      if (!adminRole) {
        const adminPermissions = [
          'MANAGE_USERS', 'MANAGE_ROLES', 'MANAGE_ORGANIZATION',
          'VIEW_CONTACTS','CREATE_CONTACTS','EDIT_CONTACTS','DELETE_CONTACTS',
          'VIEW_LEADS','CREATE_LEADS','EDIT_LEADS','DELETE_LEADS',
          'VIEW_TICKETS','CREATE_TICKETS','EDIT_TICKETS','DELETE_TICKETS','ASSIGN_TICKETS','RESOLVE_TICKETS',
          'VIEW_TASKS','CREATE_TASKS','EDIT_TASKS','DELETE_TASKS','ASSIGN_TASKS',
          'VIEW_DASHBOARD','VIEW_REPORTS','VIEW_AUDIT_LOGS'
        ];
        
        await prisma.userRole.create({
          data: {
            organizationId: org.id,
            name: 'Admin',
            roleType: 'ADMIN',
            permissions: adminPermissions,
            isDefault: false
          }
        });
        console.log(`Created default ADMIN role for organization: ${org.name} (${org.id})`);
      }
    }
  } catch (e) {
    console.error('Error initializing default roles:', e);
  }
}

async function startServer() {
  try {
    // Check database connection
    await prisma.$connect();
    console.log('Database connected successfully');
    
    // Initialize roles
    await initializeDefaultRoles();
    
    // Start listening
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
