import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

dotenv.config();

const ROLES = [
  {
    name: 'Admin',
    roleType: 'ADMIN',
    description: 'Full access to all features and settings',
    permissions: [
      'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'DELETE_CONTACTS',
      'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS', 'CONVERT_LEADS',
      'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
      'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
      'VIEW_DASHBOARD', 'VIEW_REPORTS', 'MANAGE_USERS', 'MANAGE_ROLES', 'MANAGE_ORGANIZATION', 'VIEW_AUDIT_LOGS'
    ]
  },
  {
    name: 'Manager',
    roleType: 'MANAGER',
    description: 'Can manage team and most CRM data',
    permissions: [
      'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS', 'DELETE_CONTACTS',
      'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS', 'CONVERT_LEADS',
      'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
      'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
      'VIEW_DASHBOARD', 'VIEW_REPORTS', 'MANAGE_USERS'
    ]
  },
  {
    name: 'Agent',
    roleType: 'AGENT',
    description: 'Can handle contacts, leads, and tickets',
    permissions: [
      'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS',
      'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS',
      'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
      'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'ASSIGN_TASKS',
      'VIEW_DASHBOARD'
    ]
  },
  {
    name: 'Viewer',
    roleType: 'VIEWER',
    description: 'Read-only access to CRM data',
    permissions: [
      'VIEW_CONTACTS', 'VIEW_LEADS', 'VIEW_TICKETS', 'VIEW_TASKS', 'VIEW_DASHBOARD'
    ]
  }
];

async function main() {
  try {
    console.log('🗑️  Starting COMPLETE database reset...');
    
    // Delete in reverse dependency order
    await prisma.attachment.deleteMany({});
    await prisma.ticketMessage.deleteMany({});
    await prisma.ticket.deleteMany({});
    await prisma.task.deleteMany({});
    await prisma.lead.deleteMany({});
    await prisma.contact.deleteMany({});
    await prisma.account.deleteMany({});
    await prisma.customerProfile.deleteMany({});
    await prisma.activityLog.deleteMany({});
    await prisma.invitation.deleteMany({});
    await prisma.organizationDomain.deleteMany({});
    await prisma.userRole.deleteMany({});
    await prisma.userOrganization.deleteMany({});
    await prisma.user.deleteMany({});
    await prisma.organization.deleteMany({});
    
    console.log('✅ Database reset completed.\n');

    console.log('🌱 Starting database seeding...');

    // 1. Create Organizations
    const defaultOrg = await prisma.organization.create({
      data: { name: 'Default Organization', domain: 'example.com', isActive: true },
    });
    const acmeOrg = await prisma.organization.create({
      data: { name: 'Acme Corporation', domain: 'acme.com', isActive: true },
    });
    const techStartOrg = await prisma.organization.create({
      data: { name: 'TechStart Inc', domain: 'techstart.io', isActive: true },
    });
    console.log('✓ Created Organizations: Default, Acme, TechStart');

    // 2. Create Domain Mappings
    await prisma.organizationDomain.createMany({
      data: [
        { organizationId: acmeOrg.id, domain: 'acme.com', priority: 10 },
        { organizationId: acmeOrg.id, domain: 'acmecorp.com', priority: 5 },
        { organizationId: techStartOrg.id, domain: 'techstart.io', priority: 10 },
        { organizationId: techStartOrg.id, domain: 'techstart.com', priority: 8 },
      ]
    });
    console.log('✓ Created Domain Mappings');

    // 3. Create Roles for each Organization
    const orgs = [defaultOrg, acmeOrg, techStartOrg];
    const rolesByOrg = {};

    for (const org of orgs) {
      rolesByOrg[org.id] = {};
      for (const roleDef of ROLES) {
        const role = await prisma.userRole.create({
          data: {
            ...roleDef,
            organizationId: org.id,
            isDefault: roleDef.roleType === 'VIEWER',
          },
        });
        rolesByOrg[org.id][roleDef.roleType] = role;
      }
    }
    console.log('✓ Created 4 Roles for each Organization');

    // 4. Create Staff Users
    const passwordHash = await bcrypt.hash('password123', 10);
    const staffUsers = [
      { email: 'admin@example.com', name: 'Admin User', roleType: 'ADMIN', orgId: defaultOrg.id },
      { email: 'manager@example.com', name: 'Manager User', roleType: 'MANAGER', orgId: defaultOrg.id },
      { email: 'agent@example.com', name: 'Agent User', roleType: 'AGENT', orgId: defaultOrg.id },
      { email: 'viewer@example.com', name: 'Viewer User', roleType: 'VIEWER', orgId: defaultOrg.id },
      { email: 'minecraftthanhloi@gmail.com', name: 'Root Admin', roleType: 'ADMIN', orgId: defaultOrg.id },
    ];

    for (const u of staffUsers) {
      const user = await prisma.user.create({
        data: { email: u.email, name: u.name, passwordHash, type: 'STAFF', isActive: true },
      });
      await prisma.userOrganization.create({
        data: {
          userId: user.id,
          organizationId: u.orgId,
          role: u.roleType,
          userRoleId: rolesByOrg[u.orgId][u.roleType].id,
        },
      });
      console.log(`✓ Created Staff User: ${user.email} (${u.roleType})`);
    }

    // 5. Create Customer Users
    const customers = [
      { email: 'john@acme.com', name: 'John Doe', orgId: acmeOrg.id, company: 'Acme Corporation' },
      { email: 'jane@techstart.io', name: 'Jane Smith', orgId: techStartOrg.id, company: 'TechStart Inc' },
      { email: 'customer@gmail.com', name: 'Unassigned Customer', orgId: null, company: null },
    ];

    for (const c of customers) {
      const user = await prisma.user.create({
        data: { email: c.email, name: c.name, passwordHash, type: 'CUSTOMER', isActive: true },
      });
      await prisma.customerProfile.create({
        data: {
          userId: user.id,
          organizationId: c.orgId,
          companyName: c.company,
        }
      });
      console.log(`✓ Created Customer: ${user.email}`);
    }

    // 6. Create Sample CRM Data
    await prisma.contact.create({
      data: { firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com', organizationId: defaultOrg.id },
    });
    await prisma.lead.create({
      data: { firstName: 'Alice', lastName: 'Smith', email: 'alice@acme.com', company: 'Acme Corp', status: 'NEW', leadSource: 'WEB', organizationId: defaultOrg.id },
    });
    console.log('✓ Created Sample CRM Data');

    console.log('\n🎉 Database seeding completed successfully!');
  } catch (err) {
    console.error('\n❌ Seeding failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
