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
    const uo = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: org.id } });
    if (!uo) {
      await prisma.userOrganization.create({ data: { userId: user.id, organizationId: org.id, role: 'ADMIN' } });
      console.log('Assigned ADMIN role for root admin to organization', org.id);
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
      await prisma.userRole.upsert({
        where: { organizationId_name: { organizationId: org.id, name: 'Admin' } },
        create: { organizationId: org.id, name: 'Admin', roleType: 'ADMIN', permissions: adminPermissions, isDefault: false },
        update: { permissions: adminPermissions }
      });
      console.log('Ensured ADMIN role with permissions for org:', org.id);
    console.log('Root admin seeded:', { email: rootAdmin.email, id: rootAdmin.id });
  } catch (e) {
    console.error('Seeding failed:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
