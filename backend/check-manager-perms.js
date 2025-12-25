import prisma from './lib/prismaClient.js';

async function main() {
  console.log('=== Checking Manager Permissions ===\n');
  
  // Get all user roles
  const roles = await prisma.userRole.findMany({
    orderBy: { createdAt: 'desc' }
  });
  
  console.log('User Roles:');
  roles.forEach(r => {
    console.log(`\n- Name: ${r.name}`);
    console.log(`  Type: ${r.roleType}`);
    console.log(`  Permissions: ${r.permissions.join(', ')}`);
    console.log(`  Organization: ${r.organizationId}`);
  });
  
  console.log('\n=== Checking UserOrganization records ===\n');
  const userOrgs = await prisma.userOrganization.findMany({
    include: {
      user: true,
      userRole: true
    }
  });
  
  userOrgs.forEach(uo => {
    console.log(`\n- User: ${uo.user.email}`);
    console.log(`  Role (enum): ${uo.role}`);
    console.log(`  UserRole linked: ${uo.userRole ? uo.userRole.name : 'None'}`);
    if (uo.userRole) {
      console.log(`  Permissions: ${uo.userRole.permissions.join(', ')}`);
    }
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
