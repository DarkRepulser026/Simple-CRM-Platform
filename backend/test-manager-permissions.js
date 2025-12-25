import prisma from './lib/prismaClient.js';
import { getUserPermissions } from './lib/permissions.js';

async function main() {
  const manager = await prisma.user.findUnique({ where: { email: 'manager@example.com' } });
  
  if (!manager) {
    console.log('Manager user not found');
    return;
  }
  
  console.log('\n=== Manager User ===');
  console.log(`Email: ${manager.email}`);
  console.log(`ID: ${manager.id}`);
  
  // Get user organization
  const userOrg = await prisma.userOrganization.findFirst({
    where: { userId: manager.id },
    include: {
      organization: true,
      userRole: true
    }
  });
  
  if (!userOrg) {
    console.log('No organization found for manager');
    return;
  }
  
  console.log(`\nOrganization: ${userOrg.organization.name}`);
  console.log(`Organization ID: ${userOrg.organizationId}`);
  console.log(`Role (enum): ${userOrg.role}`);
  console.log(`UserRole ID: ${userOrg.userRoleId || 'None'}`);
  
  if (userOrg.userRole) {
    console.log(`\nUserRole Details:`);
    console.log(`  Name: ${userOrg.userRole.name}`);
    console.log(`  Type: ${userOrg.userRole.roleType}`);
    console.log(`  Permissions (${userOrg.userRole.permissions.length}):`);
    userOrg.userRole.permissions.forEach(p => console.log(`    - ${p}`));
  }
  
  // Test the getUserPermissions function
  console.log(`\n=== getUserPermissions() Result ===`);
  const permissions = await getUserPermissions(prisma, manager.id, userOrg.organizationId);
  console.log(`Permissions (${permissions.length}):`);
  permissions.forEach(p => console.log(`  - ${p}`));
  
  // Check specific permissions
  console.log(`\n=== Permission Checks ===`);
  const checks = ['VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'VIEW_DASHBOARD'];
  checks.forEach(check => {
    console.log(`${check}: ${permissions.includes(check) ? '✓' : '✗'}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
