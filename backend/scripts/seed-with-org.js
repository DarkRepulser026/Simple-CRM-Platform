import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';
import { execSync } from 'child_process';

dotenv.config();

async function main() {
  try {
    // Find first organization
    const org = await prisma.organization.findFirst();
    if (!org) {
      console.error('No organization found in database');
      process.exit(1);
    }

    console.log('Found organization:', org.id);
    
    // Set environment and run seed
    process.env.ORG_ID = org.id;
    
    // Import and run the seed function
    const { default: seedFn } = await import('./seed-sample-data.js');
    
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
