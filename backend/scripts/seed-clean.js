import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

async function main() {
  try {
    console.log('Starting database reset...');

    // Delete all data in correct order (respecting foreign key constraints)
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

    console.log('Deleting user roles...');
    await prisma.userRole.deleteMany({});

    console.log('Deleting user-organization links...');
    await prisma.userOrganization.deleteMany({});

    console.log('Deleting users...');
    await prisma.user.deleteMany({});

    console.log('Deleting organizations...');
    await prisma.organization.deleteMany({});

    console.log('✅ Database reset completed successfully!');
  } catch (err) {
    console.error('❌ Error during database reset:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
