import prisma from './prismaClient.js';

export async function findOrCreateDefaultOrgAndUser() {
  // Find by name (not unique), create if it doesn't exist
  let org = await prisma.organization.findFirst({ where: { name: 'Default Organization' } });
  if (!org) {
    org = await prisma.organization.create({
      data: { name: 'Default Organization', domain: 'example.com', description: 'Auto-generated default organization' }
    });
  }

  // Email is unique so we can use findUnique/create
  let user = await prisma.user.findUnique({ where: { email: 'admin@example.com' } });
  if (!user) {
    user = await prisma.user.create({ data: { email: 'admin@example.com', name: 'Admin User' } });
  }

  // userOrganization has a unique composite constraint [userId, organizationId]
  // We'll use findFirst and create if needed to avoid composite unique upsert complexity
  let userOrg = await prisma.userOrganization.findFirst({ where: { userId: user.id, organizationId: org.id } });
  if (!userOrg) {
    userOrg = await prisma.userOrganization.create({
      data: {
        userId: user.id,
        organizationId: org.id,
        role: 'ADMIN'
      }
    });
  }

  return { org, user };
}

export default prisma;
