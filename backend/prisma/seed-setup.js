import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';
import { findOrCreateDefaultOrgAndUser } from '../lib/db.js';

// Additional seeding for root admin
async function findOrCreateRootAdmin(org) {
  const email = process.env.ROOT_ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    user = await prisma.user.create({ data: { email, name: 'Root Admin' } });
    console.log('Created root admin user:', email);
  } else {
    console.log('Root admin already exists:', email);
  }

  // Ensure user has ADMIN role in organization
  if (org && org.id) {
    // Get or create the Admin role
    const adminRole = await prisma.userRole.findFirst({
      where: { organizationId: org.id, roleType: 'ADMIN' }
    });
    
    const uo = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: org.id } });
    if (!uo) {
      await prisma.userOrganization.create({ 
        data: { 
          userId: user.id, 
          organizationId: org.id, 
          role: 'ADMIN',
          userRoleId: adminRole?.id
        } 
      });
      console.log('Assigned ADMIN role for root admin to organization', org.id);
    } else if (!uo.userRoleId && adminRole) {
      // Update existing entry to link userRoleId
      await prisma.userOrganization.update({
        where: { id: uo.id },
        data: { userRoleId: adminRole.id }
      });
      console.log('Updated root admin with userRoleId link');
    } else {
      console.log('Root admin already assigned in org', org.id);
    }
  }
  return user;
}

dotenv.config();

async function main() {
  try {
    console.log('Seeding database...');
    const { org, user } = await findOrCreateDefaultOrgAndUser();
    console.log('Seeding completed: ', { orgId: org.id, userId: user.id });
    // Seed root admin and assign role to the default org
    const rootAdmin = await findOrCreateRootAdmin(org);
      // Ensure the Admin role exists with full permissions for the namespace
      const adminPermissions = [
        'MANAGE_USERS', 'MANAGE_ROLES', 'MANAGE_ORGANIZATION',
        'VIEW_CONTACTS','CREATE_CONTACTS','EDIT_CONTACTS','DELETE_CONTACTS',
        'VIEW_LEADS','CREATE_LEADS','EDIT_LEADS','DELETE_LEADS',
        'VIEW_TICKETS','CREATE_TICKETS','EDIT_TICKETS','DELETE_TICKETS','ASSIGN_TICKETS','RESOLVE_TICKETS',
        'VIEW_TASKS','CREATE_TASKS','EDIT_TASKS','DELETE_TASKS','ASSIGN_TASKS',
        'VIEW_DASHBOARD','VIEW_REPORTS','VIEW_AUDIT_LOGS'
      ];
      // Upsert the Admin role for the org
      const adminRole = await prisma.userRole.upsert({
        where: { organizationId_name: { organizationId: org.id, name: 'Admin' } },
        create: { organizationId: org.id, name: 'Admin', roleType: 'ADMIN', permissions: adminPermissions, isDefault: false },
        update: { permissions: adminPermissions }
      });
      console.log('Ensured ADMIN role with permissions for org:', org.id);
      
      // Now link the root admin user to this role
      if (rootAdmin.id) {
        const userOrg = await prisma.userOrganization.findFirst({
          where: { userId: rootAdmin.id, organizationId: org.id }
        });
        if (userOrg && !userOrg.userRoleId) {
          await prisma.userOrganization.update({
            where: { id: userOrg.id },
            data: { userRoleId: adminRole.id }
          });
          console.log('Linked root admin to admin role');
        }
      }

    // Also create debug admin@example.com for convenient testing
    console.log('Setting up debug admin account (admin@example.com)...');
    let debugAdmin = await prisma.user.findUnique({ where: { email: 'admin@example.com' } });
    if (!debugAdmin) {
      debugAdmin = await prisma.user.create({ data: { email: 'admin@example.com', name: 'Admin User' } });
      console.log('Created debug admin user: admin@example.com');
    } else {
      console.log('Debug admin already exists: admin@example.com');
    }

    // Ensure debug admin has ADMIN role in organization
    const debugAdminOrgEntry = await prisma.userOrganization.findFirst({
      where: { userId: debugAdmin.id, organizationId: org.id }
    });
    
    if (!debugAdminOrgEntry) {
      await prisma.userOrganization.create({
        data: {
          userId: debugAdmin.id,
          organizationId: org.id,
          role: 'ADMIN',
          userRoleId: adminRole.id
        }
      });
      console.log('Assigned ADMIN role to debug admin (admin@example.com)');
    } else if (!debugAdminOrgEntry.userRoleId) {
      await prisma.userOrganization.update({
        where: { id: debugAdminOrgEntry.id },
        data: { userRoleId: adminRole.id }
      });
      console.log('Linked debug admin to admin role');
    } else {
      console.log('Debug admin already has ADMIN role assigned');
    }

    console.log('Root admin seeded:', { email: rootAdmin.email, id: rootAdmin.id });
    console.log('Debug admin seeded:', { email: debugAdmin.email, id: debugAdmin.id });
  } catch (e) {
    console.error('Seeding failed:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
