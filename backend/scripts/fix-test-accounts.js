import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

async function main() {
  const orgId = process.env.ORG_ID || '';

  if (!orgId) {
    console.error('Please set ORG_ID environment variable');
    console.error('Example: ORG_ID=xyz node scripts/fix-test-accounts.js');
    process.exit(1);
  }

  try {
    // Define proper permissions for each role type
    const rolePermissions = {
      ADMIN: [
        'MANAGE_USERS', 'MANAGE_ROLES', 'MANAGE_ORGANIZATION',
        'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'DELETE_CONTACTS',
        'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS', 'CONVERT_LEADS',
        'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
        'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
        'VIEW_DASHBOARD', 'VIEW_REPORTS', 'VIEW_AUDIT_LOGS'
      ],
      MANAGER: [
        'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'DELETE_CONTACTS',
        'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS', 'CONVERT_LEADS',
        'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
        'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
        'VIEW_DASHBOARD', 'VIEW_REPORTS'
      ],
      AGENT: [
        'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS',
        'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'CONVERT_LEADS',
        'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
        'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'ASSIGN_TASKS',
        'VIEW_DASHBOARD'
      ],
      VIEWER: [
        'VIEW_CONTACTS',
        'VIEW_LEADS',
        'VIEW_TICKETS',
        'VIEW_TASKS',
        'VIEW_DASHBOARD'
      ]
    };

    const testAccounts = [
      { email: 'admin@example.com', roleType: 'ADMIN' },
      { email: 'manager@example.com', roleType: 'MANAGER' },
      { email: 'agent@example.com', roleType: 'AGENT' },
      { email: 'user@example.com', roleType: 'VIEWER' }
    ];
    
    for (const account of testAccounts) {
      console.log(`\nProcessing ${account.email}...`);
      
      // Ensure the role exists with correct permissions
      const role = await prisma.userRole.upsert({
        where: {
          organizationId_name: {
            organizationId: orgId,
            name: account.roleType
          }
        },
        update: { permissions: rolePermissions[account.roleType] },
        create: {
          organizationId: orgId,
          name: account.roleType,
          description: `${account.roleType} role for testing`,
          roleType: account.roleType,
          permissions: rolePermissions[account.roleType],
          isActive: true
        }
      });
      console.log(`  ✓ Ensured role: ${role.name} with ${role.permissions.length} permissions`);

      const user = await prisma.user.findUnique({ where: { email: account.email } });
      if (!user) {
        console.log(`  ⚠️  User not found: ${account.email}`);
        continue;
      }

      const userOrg = await prisma.userOrganization.findFirst({
        where: { userId: user.id, organizationId: orgId }
      });

      if (!userOrg) {
        console.log(`  ⚠️  UserOrganization not found for ${account.email}`);
        continue;
      }

      // Update the userOrganization to link correct role
      await prisma.userOrganization.update({
        where: { id: userOrg.id },
        data: { role: account.roleType, userRoleId: role.id }
      });

      console.log(`  ✓ Linked ${account.email} to ${account.roleType} role`);
    }

    console.log('\n✅ All test accounts updated with correct permissions!');

  } catch (e) {
    console.error('Error:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
