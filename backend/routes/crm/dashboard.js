/**
 * Dashboard Routes - Read-Only Command Center
 * 
 * Based on ARCHITECTURE_PATTERNS.md:
 * - Must show: KPIs, My assigned items, Recent activity
 * - Must NOT: Create entities, Edit data, Deep navigation
 * - 📌 Rule: No CRUD here
 * 
 * Role-based data:
 * - Agent: My work (tickets/tasks)
 * - Manager: Team overview, SLA, unassigned items
 * - Admin: System health, audit logs
 */

import express from 'express';
import prisma from '../../lib/prismaClient.js';
import { authenticateToken } from '../../middleware/auth.js';
import { requireOrganization } from '../../middleware/requireOrganization.js';

const router = express.Router();

router.use(authenticateToken);
router.use(requireOrganization);

/**
 * GET /summary - KPI Cards
 * Returns summary metrics based on user role
 */
router.get('/summary', async (req, res) => {
  try {
    const userRole = req.user?.role || req.organizationRole || 'AGENT';
    const userId = req.user.id;
    const orgId = req.organizationId;

    let summary = {};

    if (userRole === 'AGENT') {
      // Agent Dashboard: My Work
      const [myOpenTickets, myOverdueTasks, waitingTickets] = await Promise.all([
        prisma.ticket.count({
          where: {
            organizationId: orgId,
            ownerId: userId,
            status: { in: ['OPEN', 'IN_PROGRESS'] }
          }
        }),
        prisma.task.count({
          where: {
            organizationId: orgId,
            ownerId: userId,
            status: { not: 'COMPLETED' },
            dueDate: { lt: new Date() }
          }
        }),
        prisma.ticket.count({
          where: {
            organizationId: orgId,
            ownerId: userId,
            status: 'WAITING_ON_CUSTOMER'
          }
        })
      ]);

      summary = {
        myOpenTickets,
        myOverdueTasks,
        waitingTickets,
        role: 'AGENT'
      };

    } else if (userRole === 'MANAGER') {
      // Manager Dashboard: Team & Organization
      const [
        orgOpenTickets,
        slaBreaches,
        unassignedTickets,
        activeLeads,
        teamTickets
      ] = await Promise.all([
        prisma.ticket.count({
          where: {
            organizationId: orgId,
            status: { in: ['OPEN', 'IN_PROGRESS'] }
          }
        }),
        prisma.ticket.count({
          where: {
            organizationId: orgId,
            slaDeadline: { lt: new Date() },
            status: { notIn: ['CLOSED', 'RESOLVED'] }
          }
        }),
        prisma.ticket.count({
          where: {
            organizationId: orgId,
            ownerId: null,
            status: { not: 'CLOSED' }
          }
        }),
        prisma.lead.count({
          where: {
            organizationId: orgId,
            isConverted: false,
            status: { in: ['NEW', 'CONTACTED', 'QUALIFIED'] }
          }
        }),
        prisma.ticket.groupBy({
          by: ['ownerId'],
          where: {
            organizationId: orgId,
            status: { in: ['OPEN', 'IN_PROGRESS'] }
          },
          _count: { id: true }
        })
      ]);

      summary = {
        orgOpenTickets,
        slaBreaches,
        unassignedTickets,
        activeLeads,
        teamLoad: teamTickets,
        role: 'MANAGER'
      };

    } else if (userRole === 'ADMIN') {
      // Admin Dashboard: System Health
      const [
        activeUsers,
        totalOrganizations,
        recentAuditEvents
      ] = await Promise.all([
        prisma.user.count({
          where: {
            type: 'STAFF',
            isActive: true
          }
        }),
        prisma.organization.count(),
        prisma.activityLog.count({
          where: {
            createdAt: {
              gte: new Date(Date.now() - 24 * 60 * 60 * 1000) // Last 24h
            }
          }
        })
      ]);

      summary = {
        activeUsers,
        totalOrganizations,
        recentAuditEvents,
        role: 'ADMIN'
      };
    }

    res.json(summary);
  } catch (error) {
    console.error('Dashboard summary error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /my-work - Primary Work Queue (Tickets only)
 * Returns tickets assigned to current user
 */
router.get('/my-work', async (req, res) => {
  try {
    const userId = req.user.id;
    const orgId = req.organizationId;
    const limit = Math.min(parseInt(req.query.limit || '15'), 50);

    const tickets = await prisma.ticket.findMany({
      where: {
        organizationId: orgId,
        ownerId: userId,
        status: { notIn: ['CLOSED', 'RESOLVED'] }
      },
      include: {
        account: { select: { id: true, name: true } },
        owner: { select: { id: true, name: true } }
      },
      orderBy: [
        { priority: 'desc' },
        { createdAt: 'desc' }
      ],
      take: limit
    });

    // Transform to WorkQueueItem format expected by frontend
    const workItems = tickets.map(t => ({
      id: t.id,
      type: 'ticket',
      title: t.subject || `Ticket #${t.id.substring(0, 8)}`,
      status: t.status,
      priority: t.priority,
      dueDate: t.slaDeadline || null,
      assignedTo: t.owner?.name || null,
      accountName: t.account?.name || null
    }));

    res.json(workItems);
  } catch (error) {
    console.error('My work error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /team-work - Manager: Team Overview
 * Returns unassigned and at-risk items
 */
router.get('/team-work', async (req, res) => {
  try {
    const userRole = req.user?.role || req.organizationRole;
    
    // Only managers and admins can access
    if (userRole !== 'MANAGER' && userRole !== 'ADMIN') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const orgId = req.organizationId;
    const limit = Math.min(parseInt(req.query.limit || '15'), 50);

    const [unassignedTickets, atRiskTasks, teamLoad] = await Promise.all([
      prisma.ticket.findMany({
        where: {
          organizationId: orgId,
          ownerId: null,
          status: { not: 'CLOSED' }
        },
        include: {
          account: { select: { id: true, name: true } }
        },
        orderBy: { createdAt: 'asc' },
        take: limit
      }),
      prisma.task.findMany({
        where: {
          organizationId: orgId,
          status: { not: 'COMPLETED' },
          dueDate: {
            lt: new Date(Date.now() + 48 * 60 * 60 * 1000) // Due in next 48h or overdue
          }
        },
        include: {
          owner: { select: { id: true, name: true } },
          account: { select: { id: true, name: true } }
        },
        orderBy: { dueDate: 'asc' },
        take: limit
      }),
      prisma.user.findMany({
        where: {
          organizationId: orgId,
          type: 'STAFF',
          isActive: true
        },
        select: {
          id: true,
          name: true,
          email: true,
          _count: {
            select: {
              ownedTickets: {
                where: {
                  status: { in: ['OPEN', 'IN_PROGRESS'] }
                }
              }
            }
          }
        },
        orderBy: {
          name: 'asc'
        }
      })
    ]);

    // Transform unassigned items to WorkQueueItem format
    const unassignedItems = [
      ...unassignedTickets.map(t => ({
        id: t.id,
        type: 'ticket',
        title: t.subject || `Ticket #${t.id.substring(0, 8)}`,
        status: t.status,
        priority: t.priority,
        dueDate: t.slaDeadline || null,
        assignedTo: null,
        accountName: t.account?.name || null
      })),
      ...atRiskTasks.filter(t => !t.ownerId).map(t => ({
        id: t.id,
        type: 'task',
        title: t.subject || `Task #${t.id.substring(0, 8)}`,
        status: t.status,
        priority: t.priority,
        dueDate: t.dueDate || null,
        assignedTo: null,
        accountName: t.account?.name || null
      }))
    ];

    res.json({
      unassigned: unassignedItems,
      atRisk: atRiskTasks.map(t => ({
        id: t.id,
        type: 'task',
        title: t.subject || `Task #${t.id.substring(0, 8)}`,
        status: t.status,
        priority: t.priority,
        dueDate: t.dueDate || null,
        assignedTo: t.owner?.name || null,
        accountName: t.account?.name || null
      })),
      teamLoad: teamLoad.map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        ticketCount: user._count.ownedTickets
      }))
    });
  } catch (error) {
    console.error('Team work error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /activity - Recent Activity Feed
 * Returns recent activity logs
 */
router.get('/activity', async (req, res) => {
  try {
    const orgId = req.organizationId;
    const limit = Math.min(parseInt(req.query.limit || '20'), 100);

    const activities = await prisma.activityLog.findMany({
      where: {
        organizationId: orgId,
        action: {
          in: [
            'TICKET_CREATED', 'TICKET_RESOLVED', 'TICKET_CLOSED',
            'LEAD_CONVERTED',
            'TASK_COMPLETED',
            'ACCOUNT_CREATED',
            'CONTACT_CREATED'
          ]
        }
      },
      include: {
        user: { select: { id: true, name: true, email: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: limit
    });

    res.json(activities);
  } catch (error) {
    console.error('Activity feed error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /upcoming-tasks - Upcoming Tasks Widget
 * Returns next 7 incomplete tasks ordered by due date
 */
router.get('/upcoming-tasks', async (req, res) => {
  try {
    const userId = req.user.id;
    const orgId = req.organizationId;

    console.log('Upcoming tasks query:', { userId, orgId });

    const tasks = await prisma.task.findMany({
      where: {
        organizationId: orgId,
        ownerId: userId,
        status: { not: 'COMPLETED' }
      },
      include: {
        account: { select: { id: true, name: true } },
        contact: { select: { id: true, firstName: true, lastName: true } }
      },
      orderBy: [
        { dueDate: 'asc' },
        { createdAt: 'desc' }
      ],
      take: 7
    });

    console.log(`Found ${tasks.length} upcoming tasks`);

    // Return in expected format for frontend
    res.json({ 
      tasks: tasks.map(t => ({
        id: t.id,
        title: t.subject,
        description: t.description,
        dueDate: t.dueDate,
        status: t.status,
        isCompleted: t.status === 'COMPLETED'
      }))
    });
  } catch (error) {
    console.error('Upcoming tasks error:', error);
    res.status(500).json({ message: error.message });
  }
});

/**
 * GET /system-activity - Admin: System Activity Feed
 * Returns system-level events for admins
 */
router.get('/system-activity', async (req, res) => {
  try {
    const userRole = req.user?.role || req.organizationRole;
    
    // Only admins can access
    if (userRole !== 'ADMIN') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const limit = Math.min(parseInt(req.query.limit || '20'), 100);

    const activities = await prisma.activityLog.findMany({
      where: {
        action: {
          in: [
            'USER_CREATED', 'USER_UPDATED', 'USER_DELETED',
            'ROLE_UPDATED',
            'ORGANIZATION_CREATED',
            'DOMAIN_MAPPED',
            'INVITATION_SENT', 'INVITATION_ACCEPTED'
          ]
        }
      },
      include: {
        user: { select: { id: true, name: true, email: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: limit
    });

    res.json(activities);
  } catch (error) {
    console.error('System activity error:', error);
    res.status(500).json({ message: error.message });
  }
});

export default router;
