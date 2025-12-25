import prisma from './lib/prismaClient.js';

async function checkUserWork() {
  try {
    const email = 'minecraftthanhloi@gmail.com';
    
    // Find user
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        organizations: {
          include: {
            organization: true
          }
        }
      }
    });

    if (!user) {
      console.log(`User not found: ${email}`);
      return;
    }

    console.log('\n=== USER INFO ===');
    console.log('ID:', user.id);
    console.log('Name:', user.name);
    console.log('Email:', user.email);
    console.log('Type:', user.type);
    console.log('Organizations:', user.organizations.map(o => ({
      orgId: o.organizationId,
      orgName: o.organization.name,
      role: o.role
    })));

    // Check tickets for each organization
    for (const org of user.organizations) {
      console.log(`\n=== TICKETS IN ${org.organization.name} ===`);
      
      const tickets = await prisma.ticket.findMany({
        where: {
          organizationId: org.organizationId,
          ownerId: user.id,
          status: { notIn: ['CLOSED', 'RESOLVED'] }
        },
        include: {
          account: { select: { id: true, name: true } },
          owner: { select: { id: true, name: true } }
        }
      });

      console.log(`Found ${tickets.length} open tickets`);
      tickets.forEach(t => {
        console.log(`- Ticket #${t.id.substring(0, 8)}: ${t.subject}`);
        console.log(`  Status: ${t.status}, Priority: ${t.priority}`);
        console.log(`  Account: ${t.account?.name || 'N/A'}`);
        console.log(`  Owner: ${t.owner?.name || 'Unassigned'}`);
      });

      console.log(`\n=== TASKS IN ${org.organization.name} ===`);
      
      const tasks = await prisma.task.findMany({
        where: {
          organizationId: org.organizationId,
          ownerId: user.id,
          status: { not: 'COMPLETED' }
        },
        include: {
          account: { select: { id: true, name: true } },
          owner: { select: { id: true, name: true } }
        }
      });

      console.log(`Found ${tasks.length} active tasks`);
      tasks.forEach(t => {
        console.log(`- Task #${t.id.substring(0, 8)}: ${t.subject}`);
        console.log(`  Status: ${t.status}, Priority: ${t.priority}`);
        console.log(`  Due: ${t.dueDate || 'No due date'}`);
        console.log(`  Account: ${t.account?.name || 'N/A'}`);
        console.log(`  Owner: ${t.owner?.name || 'Unassigned'}`);
      });
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUserWork();
