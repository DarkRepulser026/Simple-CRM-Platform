import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function checkOverdueTasks() {
  try {
    const tasks = await prisma.task.findMany({
      where: { status: { not: 'COMPLETED' } },
      select: { 
        id: true, 
        subject: true, 
        dueDate: true, 
        status: true, 
        organizationId: true 
      }
    });

    const now = new Date();
    const overdue = tasks.filter(t => t.dueDate && new Date(t.dueDate) < now);
    
    console.log('Total non-completed tasks:', tasks.length);
    console.log('Overdue tasks:', overdue.length);
    console.log('Current time:', now.toISOString());
    console.log('\nAll task due dates:');
    tasks.forEach(t => {
      console.log('  -', t.subject || 'No subject');
      console.log('    Due:', t.dueDate ? new Date(t.dueDate).toISOString() : 'No due date');
      console.log('    Status:', t.status);
      console.log('    Is overdue?', t.dueDate && new Date(t.dueDate) < now ? 'YES' : 'NO');
    });
    console.log('\nOverdue task details:');
    overdue.forEach(t => {
      console.log('  -', t.subject);
      console.log('    Due:', t.dueDate);
      console.log('    Status:', t.status);
      console.log('    Org:', t.organizationId);
    });
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkOverdueTasks();
