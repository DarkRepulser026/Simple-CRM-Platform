import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';

const router = express.Router();

// Apply middleware
router.use(authenticateToken);
router.use(requireOrganization);

// GET / - Get dashboard data
router.get('/', async (req, res) => {
  try {
    const [contactCount, leadCount, taskCount, ticketCount, usersCount, accountCount] = await Promise.all([
      prisma.contact.count({ where: { organizationId: req.organizationId } }),
      prisma.lead.count({ where: { organizationId: req.organizationId } }),
      prisma.task.count({ where: { organizationId: req.organizationId } }),
      prisma.ticket.count({ where: { organizationId: req.organizationId } }),
      prisma.userOrganization.count({ where: { organizationId: req.organizationId } }),
      prisma.account.count({ where: { organizationId: req.organizationId } })
    ]);

    const organizationsCount = await prisma.organization.count();

    const recentActivities = await prisma.activityLog.findMany({
      where: { organizationId: req.organizationId },
      include: { user: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10
    });

    const taskStats = await prisma.task.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    const leadStats = await prisma.lead.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    const ticketStats = await prisma.ticket.groupBy({
      by: ['status'],
      where: { organizationId: req.organizationId },
      _count: { status: true }
    });

    const ticketsByStatus = {};
    ticketStats.forEach((s) => { ticketsByStatus[s.status] = s._count.status; });

    const ticketPriorityStats = await prisma.ticket.groupBy({
      by: ['priority'],
      where: { organizationId: req.organizationId },
      _count: { priority: true }
    });

    const ticketsByAgentRaw = await prisma.ticket.groupBy({
      by: ['ownerId'],
      where: { organizationId: req.organizationId },
      _count: { ownerId: true }
    });
    const ticketsByAgent = {};
    ticketsByAgentRaw.forEach(a => { ticketsByAgent[a.ownerId || 'unassigned'] = a._count.ownerId; });

    const openTickets = ticketsByStatus['OPEN'] ?? ticketsByStatus['Open'] ?? ticketsByStatus['open'] ?? 0;
    const agentCount = await prisma.userOrganization.count({ 
      where: { organizationId: req.organizationId, role: { in: ['AGENT', 'MANAGER'] } } 
    });
    const ticketLoad = agentCount > 0 ? (openTickets / agentCount) : openTickets;

    const now = new Date();
    const overdueTasks = await prisma.task.count({ 
      where: { organizationId: req.organizationId, dueDate: { lt: now }, status: { not: 'COMPLETED' } } 
    });

    const weekStart = new Date();
    weekStart.setUTCHours(0,0,0,0);
    const day = weekStart.getUTCDay();
    const diffToMonday = (day + 6) % 7;
    weekStart.setUTCDate(weekStart.getUTCDate() - diffToMonday);

    const leadsThisWeek = await prisma.lead.count({ 
      where: { organizationId: req.organizationId, createdAt: { gte: weekStart } } 
    });
    const ticketsResolvedThisWeek = await prisma.ticket.count({ 
      where: { organizationId: req.organizationId, status: 'RESOLVED', updatedAt: { gte: weekStart } } 
    });
    const tasksCompletedThisWeekRaw = await prisma.task.groupBy({
      by: ['ownerId'],
      where: { organizationId: req.organizationId, status: 'COMPLETED', updatedAt: { gte: weekStart } },
      _count: { ownerId: true }
    });
    const tasksCompletedByAgent = {};
    tasksCompletedThisWeekRaw.forEach(r => { tasksCompletedByAgent[r.ownerId || 'unassigned'] = r._count.ownerId; });

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 7);
    const activeUsersRaw = await prisma.activityLog.groupBy({ 
      by: ['userId'], 
      where: { organizationId: req.organizationId, createdAt: { gte: sevenDaysAgo }, userId: { not: null } } , 
      _count: { userId: true } 
    });
    const activeUsersThisWeek = activeUsersRaw.length;

    res.json({
      counts: {
        contacts: contactCount,
        leads: leadCount,
        tasks: taskCount,
        tickets: ticketCount,
        users: usersCount,
        accounts: accountCount,
      },
      organizationsCount,
      overdueTasks,
      recentActivities,
      ticketLoad,
      activeUsersThisWeek,
      taskStats,
      leadStats,
      ticketStats,
      ticketPriorityStats,
      ticketsByAgent,
      weeklyMetrics: {
        leadsThisWeek,
        ticketsResolvedThisWeek,
        tasksCompletedByAgent
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

export default router;
