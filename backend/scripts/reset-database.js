import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

/**
 * Complete database reset script
 * Deletes ALL data in the correct order to respect foreign key constraints
 */
async function main() {
  try {
    console.log('🗑️  Starting COMPLETE database reset...\n');

    // Delete in reverse dependency order
    console.log('Deleting attachments...');
    await prisma.attachment.deleteMany({});

    console.log('Deleting ticket messages...');
    await prisma.ticketMessage.deleteMany({});

    console.log('Deleting tickets...');
    await prisma.ticket.deleteMany({});

    console.log('Deleting tasks...');
    await prisma.task.deleteMany({});

    console.log('Deleting leads...');
    await prisma.lead.deleteMany({});

    console.log('Deleting contacts...');
    await prisma.contact.deleteMany({});

    console.log('Deleting accounts...');
    await prisma.account.deleteMany({});

    console.log('Deleting activity logs...');
    await prisma.activityLog.deleteMany({});

    console.log('Deleting invitations...');
    await prisma.invitation.deleteMany({});

    console.log('Deleting organization domain mappings...');
    await prisma.organizationDomain.deleteMany({});

    console.log('Deleting user roles...');
    await prisma.userRole.deleteMany({});

    console.log('Deleting user-organization links...');
    await prisma.userOrganization.deleteMany({});

    console.log('Deleting users...');
    await prisma.user.deleteMany({});

    console.log('Deleting organizations...');
    await prisma.organization.deleteMany({});

    console.log('\n✅ Database reset completed successfully!');
    console.log('💡 Run: npm run seed -- to populate with fresh data');
  } catch (err) {
    console.error('\n❌ Error during database reset:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
