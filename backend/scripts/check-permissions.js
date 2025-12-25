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

    const userOrg = await prisma.userOrganization.findFirst({ 
      where: { userId: user.id, organizationId: orgId },
      include: { userRole: true }
    });
    console.log('UserOrganization:', userOrg);

    let userRole = null;
    
    // Prefer userRoleId relationship if available
    if (userOrg?.userRole) {
      userRole = userOrg.userRole;
      console.log('Using linked UserRole via userRoleId');
    } else {
      // Fallback: lookup by roleType
      const roleType = userOrg?.role;
      if (roleType) {
        userRole = await prisma.userRole.findFirst({ where: { organizationId: orgId, roleType } });
        console.log('Using fallback lookup by roleType:', roleType);
      }
    }
    
    console.log('UserRole:', userRole);
    console.log('Permissions ->', userRole?.permissions);

    // Check specific permissions
    const permsToCheck = ['CREATE_CONTACTS','CREATE_TASKS','CREATE_TICKETS','MANAGE_USERS'];
    const hasPerms = {};
    permsToCheck.forEach((p) => hasPerms[p] = userRole?.permissions?.includes(p));
    console.log('Has Permissions:', hasPerms);
  } catch (e) {
    console.error('Error checking permissions:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
