import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

async function main() {
  const orgId = process.env.ORG_ID || '';
  const email = process.env.ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';

  if (!orgId) {
    console.error('Please set ORG_ID environment variable or edit the script to point to the target organization.');
    process.exit(1);
  }
    console.log('Running grant-admin with ORG_ID', orgId, 'ADMIN_EMAIL', email);

  const roleType = 'ADMIN';
  const permissions = [
    'MANAGE_USERS',
    'MANAGE_ROLES',
    'MANAGE_ORGANIZATION',
    'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'DELETE_CONTACTS',
    'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS',
    'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
    'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
    'VIEW_DASHBOARD', 'VIEW_REPORTS', 'VIEW_AUDIT_LOGS'
  ];

  try {
    // Upsert role for organization
    const role = await prisma.userRole.upsert({
      where: { organizationId_name: { organizationId: orgId, name: 'Admin' } },
      create: {
        organizationId: orgId,
        name: 'Admin',
        roleType,
        permissions,
        isDefault: false,
      },
      update: { permissions },
    });
    console.log('Upserted role:', role.id);

    // Ensure the specified user exists
    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({ data: { email, name: 'Seed Admin' } });
      console.log('Created user', user.id);
    }
      console.log('Found user:', user.id, user.email);

    // Upsert userOrganization to ensure ADMIN role
    const userOrg = await prisma.userOrganization.upsert({
      where: { userId_organizationId: { userId: user.id, organizationId: orgId } },
      create: { userId: user.id, organizationId: orgId, role: 'ADMIN' },
      update: { role: 'ADMIN' },
    });
    console.log('Assigned ADMIN to user org:', userOrg.id);
  } catch (e) {
    console.error('Error granting admin permissions:', e);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

main();
