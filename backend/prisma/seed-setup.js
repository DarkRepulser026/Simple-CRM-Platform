import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';
import { findOrCreateDefaultOrgAndUser } from '../lib/db.js';

dotenv.config();

async function main() {
  try {
    console.log('Seeding database...');
    const { org, user } = await findOrCreateDefaultOrgAndUser();
    console.log('Seeding completed: ', { orgId: org.id, userId: user.id });
  } catch (e) {
    console.error('Seeding failed:', e);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
