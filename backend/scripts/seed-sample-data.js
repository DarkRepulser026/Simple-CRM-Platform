import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

async function main() {
  const orgId = process.env.ORG_ID || '';
  const seedOwnerEmail = process.env.ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';

  if (!orgId) {
    console.error('Please set ORG_ID environment variable or edit the script to point to the target organization.');
    process.exit(1);
  }

  try {
    // Ensure owner user
    let owner = await prisma.user.findUnique({ where: { email: seedOwnerEmail } });
    if (!owner) {
      owner = await prisma.user.create({ data: { email: seedOwnerEmail, name: 'Seed Admin' } });
    }

    // Create sample accounts
    let account1 = await prisma.account.findFirst({ where: { name: 'Acme Inc', organizationId: orgId } });
    if (!account1) {
      account1 = await prisma.account.create({ data: { name: 'Acme Inc', type: 'Customer', website: 'https://acme.example', organizationId: orgId } });
    }

    let account2 = await prisma.account.findFirst({ where: { name: 'Beta LLC', organizationId: orgId } });
    if (!account2) {
      account2 = await prisma.account.create({ data: { name: 'Beta LLC', type: 'Partner', website: 'https://beta.example', organizationId: orgId } });
    }

    // Create sample contacts
    let contact1 = await prisma.contact.findFirst({ where: { email: 'alice@acme.example', organizationId: orgId } });
    if (!contact1) {
      contact1 = await prisma.contact.create({ data: { firstName: 'Alice', lastName: 'Acme', email: 'alice@acme.example', ownerId: owner.id, organizationId: orgId } });
    }

    let contact2 = await prisma.contact.findFirst({ where: { email: 'bob@beta.example', organizationId: orgId } });
    if (!contact2) {
      contact2 = await prisma.contact.create({ data: { firstName: 'Bob', lastName: 'Beta', email: 'bob@beta.example', ownerId: owner.id, organizationId: orgId } });
    }

    // Create sample leads
    let lead1 = await prisma.lead.findFirst({ where: { email: 'lead@acme.example', organizationId: orgId } });
    if (!lead1) {
      lead1 = await prisma.lead.create({ data: { firstName: 'Lead', lastName: 'Acme', email: 'lead@acme.example', organizationId: orgId, ownerId: owner.id } });
    }

    // Create sample tasks
    let task1 = await prisma.task.findFirst({ where: { subject: 'Follow up with Alice', organizationId: orgId } });
    if (!task1) {
      task1 = await prisma.task.create({ data: { subject: 'Follow up with Alice', description: 'Call Alice to discuss requirements', ownerId: owner.id, organizationId: orgId } });
    }

    // Create sample ticket
    let ticket1 = await prisma.ticket.findFirst({ where: { subject: 'Login issue', organizationId: orgId } });
    if (!ticket1) {
      ticket1 = await prisma.ticket.create({ data: { subject: 'Login issue', description: 'Customer cannot sign in', ownerId: owner.id, organizationId: orgId } });
    }

    // Log activity entries
    await prisma.activityLog.create({
      data: {
        action: 'SEED_DATA_CREATED',
        entityType: 'SeedSample',
        entityId: orgId,
        description: 'Seeded demo accounts, contacts, leads, tasks, tickets',
        userId: owner.id,
        organizationId: orgId
      }
    });

    console.log('Seeded sample data for organization:', orgId);
  } catch (err) {
    console.error('Error seeding sample data:', err);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

main();
