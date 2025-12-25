import prisma from '../lib/prismaClient.js';

async function main() {
  try {
    console.log('Dropping task_xor_parent_check constraint...');
    await prisma.$executeRawUnsafe(`ALTER TABLE "tasks" DROP CONSTRAINT IF EXISTS "task_xor_parent_check";`);
    console.log('Constraint dropped successfully.');
  } catch (e) {
    console.error('Error dropping constraint:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
