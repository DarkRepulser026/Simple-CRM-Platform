import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

async function main() {
  const orgId = process.env.ORG_ID || '';
  const email = process.env.ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';
  if (!orgId) {
    console.error('Please set ORG_ID environment variable; e.g. ORG_ID=... ADMIN_EMAIL=... node scripts/check-permissions.js');
    process.exit(1);
  }

  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      console.error('User not found:', email);
      process.exit(1);
    }

    const userOrg = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: orgId } });
    console.log('UserOrganization:', userOrg);

    const roleType = userOrg?.role;
    if (!roleType) {
      console.log('User has no role assigned in this organization.');
    } else {
      const userRole = await prisma.userRole.findFirst({ where: { organizationId: orgId, roleType } });
      console.log('UserRole:', userRole);
      console.log('Permissions for role', roleType, '->', userRole?.permissions);
    }

    // Check specific permissions
    const permsToCheck = ['CREATE_CONTACTS','CREATE_TASKS','CREATE_TICKETS','MANAGE_USERS'];
    const role = await prisma.userRole.findFirst({ where: { organizationId: orgId, roleType } });
    const hasPerms = {};
    permsToCheck.forEach((p) => hasPerms[p] = role?.permissions?.includes(p));
    console.log('Has Permissions:', hasPerms);
  } catch (e) {
    console.error('Error checking permissions:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
