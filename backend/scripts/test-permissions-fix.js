import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';
import { getUserPermissions } from '../lib/permissions.js';

dotenv.config();

async function main() {
  const email = process.env.ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';
  const orgId = process.env.ORG_ID || '';

  if (!orgId) {
    console.error('Please set ORG_ID environment variable');
    console.error('Example: ORG_ID=xyz ADMIN_EMAIL=admin@example.com node scripts/test-permissions-fix.js');
    process.exit(1);
  }

  try {
    // 1. Find the user
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      console.error('User not found:', email);
      process.exit(1);
    }
    console.log('\n✓ User found:', { id: user.id, email: user.email });

    // 2. Check UserOrganization entry
    const userOrg = await prisma.userOrganization.findFirst({
      where: { userId: user.id, organizationId: orgId },
      include: { userRole: true }
    });

    if (!userOrg) {
      console.error('UserOrganization not found for this user in org:', orgId);
      process.exit(1);
    }
    console.log('\n✓ UserOrganization found:', {
      id: userOrg.id,
      role: userOrg.role,
      userRoleId: userOrg.userRoleId,
      userRole: userOrg.userRole
    });

    // 3. Get permissions using the new function
    console.log('\n⏳ Fetching permissions via getUserPermissions()...');
    const permissions = await getUserPermissions(prisma, user.id, orgId);
    console.log('\n✓ Permissions retrieved:', permissions);
    console.log('\n✓ Total permissions:', permissions.length);

    // 4. Check if key admin permissions are present
    const expectedAdminPerms = [
      'MANAGE_USERS',
      'MANAGE_ROLES',
      'MANAGE_ORGANIZATION',
      'VIEW_CONTACTS',
      'CREATE_CONTACTS',
      'EDIT_CONTACTS',
      'DELETE_CONTACTS',
      'VIEW_LEADS',
      'CREATE_LEADS',
      'EDIT_LEADS',
      'DELETE_LEADS',
      'VIEW_TICKETS',
      'CREATE_TICKETS',
      'EDIT_TICKETS',
      'DELETE_TICKETS',
      'ASSIGN_TICKETS',
      'RESOLVE_TICKETS',
      'VIEW_TASKS',
      'CREATE_TASKS',
      'EDIT_TASKS',
      'DELETE_TASKS',
      'ASSIGN_TASKS',
      'VIEW_DASHBOARD',
      'VIEW_REPORTS',
      'VIEW_AUDIT_LOGS'
    ];

    console.log('\n⏳ Checking expected admin permissions...');
    const missing = expectedAdminPerms.filter(p => !permissions.includes(p));
    if (missing.length === 0) {
      console.log('\n✅ SUCCESS: All expected admin permissions are present!');
    } else {
      console.log('\n❌ FAILED: Missing permissions:', missing);
    }

  } catch (e) {
    console.error('Error:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
