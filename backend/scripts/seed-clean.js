import dotenv from 'dotenv';
import prisma from '../lib/prismaClient.js';

dotenv.config();

// Safety: require explicit confirmation to prevent accidental data loss
const CONFIRM_TOKEN = process.env.SEED_CLEAN_CONFIRM || 'I_AGREE_TO_CLEAN_SEED_DATA';
if (!process.env.SEED_CLEAN_CONFIRM || process.env.SEED_CLEAN_CONFIRM !== CONFIRM_TOKEN) {
  console.error('To run seed-clean set the environment variable SEED_CLEAN_CONFIRM to the following value BEFORE running the script:');
  console.error(`SEED_CLEAN_CONFIRM=${CONFIRM_TOKEN}`);
  console.error('This is a safety measure to prevent accidental deletion in development environments.');
  process.exit(1);
}

async function main() {
  const orgId = process.env.ORG_ID;
  if (!orgId) {
    console.error('Please set ORG_ID environment variable to target the organization you want to clean.');
    process.exit(1);
  }

  const keepAdminEmail = process.env.KEEP_ADMIN_EMAIL || 'admin@example.com';

  try {
    console.log('Starting seed cleanup for org:', orgId);

    const org = await prisma.organization.findUnique({ where: { id: orgId } });
    if (!org) {
      console.error('Organization not found for id:', orgId);
      process.exit(1);
    }

    // 1. Delete attachments
    console.log('Deleting attachments...');
    await prisma.attachment.deleteMany({ where: { organizationId: orgId } });

    // 2. Delete ticket messages (for tickets in this org)
    console.log('Finding tickets...');
    const tickets = await prisma.ticket.findMany({ where: { organizationId: orgId }, select: { id: true } });
    const ticketIds = tickets.map((t) => t.id);
    if (ticketIds.length > 0) {
      console.log('Deleting ticket messages...');
      await prisma.ticketMessage.deleteMany({ where: { ticketId: { in: ticketIds } } });
    }

    // 3. Delete tickets
    console.log('Deleting tickets...');
    await prisma.ticket.deleteMany({ where: { organizationId: orgId } });

    // 4. Delete tasks
    console.log('Deleting tasks...');
    await prisma.task.deleteMany({ where: { organizationId: orgId } });

    // 5. Delete leads
    console.log('Deleting leads...');
    await prisma.lead.deleteMany({ where: { organizationId: orgId } });

    // 6. Delete contacts
    console.log('Deleting contacts...');
    await prisma.contact.deleteMany({ where: { organizationId: orgId } });

    // 7. Delete accounts
    console.log('Deleting accounts...');
    await prisma.account.deleteMany({ where: { organizationId: orgId } });

    // 8. Delete activity logs
    console.log('Deleting activity logs...');
    await prisma.activityLog.deleteMany({ where: { organizationId: orgId } });

    // 9. Delete invites
    console.log('Deleting invitations...');
    await prisma.invitation.deleteMany({ where: { organizationId: orgId } });

    // 10. Delete roles for the org
    console.log('Deleting user roles for org...');
    await prisma.userRole.deleteMany({ where: { organizationId: orgId } });

    // 11. Find users who belong only to this org so we can delete them later
    console.log('Discovering users who only belong to this org (safe to delete)...');
    const usersWithOrg = await prisma.user.findMany({
      where: { organizations: { some: { organizationId: orgId } } },
      select: { id: true, email: true }
    });

    const usersToDelete = [];
    for (const u of usersWithOrg) {
      // Skip the keepAdminEmail
      if (u.email === keepAdminEmail) continue;
      // Count how many organizations the user is a member of in total
      const totalOrgCount = await prisma.userOrganization.count({ where: { userId: u.id } });
      if (totalOrgCount === 1) {
        // Only member of this org and safe to delete
        usersToDelete.push(u.id);
      }
    }

    // 12. Delete user_organization entries
    console.log('Deleting user-organization links...');
    await prisma.userOrganization.deleteMany({ where: { organizationId: orgId } });

    // 13. Delete users who belonged only to this org
    if (usersToDelete.length > 0) {
      console.log(`Deleting ${usersToDelete.length} user(s) that only belong to this org...`);
      await prisma.user.deleteMany({ where: { id: { in: usersToDelete } } });
    }

    // 13. Optionally drop the organization - controlled by KEEP_ORG env var
    const keepOrg = process.env.KEEP_ORG === 'true';
    if (!keepOrg) {
      console.log('Deleting organization record:', orgId);
      await prisma.organization.delete({ where: { id: orgId } });
    } else {
      console.log('Keeping organization record since KEEP_ORG is set to true');
    }

    console.log('Seed cleanup completed for org:', orgId);
  } catch (err) {
    console.error('Error during seed cleanup:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
