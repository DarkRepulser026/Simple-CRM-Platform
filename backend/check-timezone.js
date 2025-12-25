import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function checkTimezoneIssue() {
  try {
    const tasks = await prisma.task.findMany({
      where: { 
        status: { not: 'COMPLETED' },
        dueDate: { not: null }
      },
      select: { 
        id: true, 
        subject: true, 
        dueDate: true, 
        status: true
      },
      orderBy: { dueDate: 'asc' },
      take: 5
    });

    const now = new Date();
    console.log('Server time (UTC):', now.toISOString());
    console.log('Server time (local):', now.toString());
    console.log('\nNext 5 upcoming tasks:');
    
    tasks.forEach(t => {
      const due = new Date(t.dueDate);
      const hoursUntilDue = (due.getTime() - now.getTime()) / (1000 * 60 * 60);
      const isOverdueUTC = due < now;
      
      // Simulate client being in UTC+7 (Vietnam)
      const nowUTC7 = new Date(now.getTime() + 7 * 60 * 60 * 1000);
      const isOverdueUTC7 = due < nowUTC7;
      
      console.log('\n  -', t.subject);
      console.log('    Due (UTC):', due.toISOString());
      console.log('    Hours until due:', hoursUntilDue.toFixed(1));
      console.log('    Overdue (server UTC)?', isOverdueUTC ? 'YES' : 'NO');
      console.log('    Overdue (client UTC+7)?', isOverdueUTC7 ? 'YES' : 'NO');
    });
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkTimezoneIssue();
