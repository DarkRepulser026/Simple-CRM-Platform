
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const roles = await prisma.userRole.findMany();
  console.log('User Roles:');
  roles.forEach(r => {
    console.log(`Name: ${r.name}, RoleType: ${r.roleType}, ID: ${r.id}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
