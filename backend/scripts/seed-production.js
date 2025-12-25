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
      'VIEW_ACCOUNTS', 'CREATE_ACCOUNTS', 'EDIT_ACCOUNTS', 'DELETE_ACCOUNTS',
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
      'VIEW_ACCOUNTS', 'CREATE_ACCOUNTS', 'EDIT_ACCOUNTS', 'DELETE_ACCOUNTS',
      'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'DELETE_LEADS', 'CONVERT_LEADS',
      'VIEW_TICKETS', 'CREATE_TICKETS', 'EDIT_TICKETS', 'DELETE_TICKETS', 'ASSIGN_TICKETS', 'RESOLVE_TICKETS',
      'VIEW_TASKS', 'CREATE_TASKS', 'EDIT_TASKS', 'DELETE_TASKS', 'ASSIGN_TASKS',
      'VIEW_DASHBOARD', 'VIEW_REPORTS', 'MANAGE_USERS'
    ]
  },
  {
    name: 'Sales Agent',
    roleType: 'AGENT',
    description: 'Can handle contacts, leads, and tickets',
    permissions: [
      'VIEW_CONTACTS', 'CREATE_CONTACTS', 'EDIT_CONTACTS',
      'VIEW_ACCOUNTS', 'CREATE_ACCOUNTS', 'EDIT_ACCOUNTS',
      'VIEW_LEADS', 'CREATE_LEADS', 'EDIT_LEADS', 'CONVERT_LEADS',
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
      'VIEW_CONTACTS', 'VIEW_ACCOUNTS', 'VIEW_LEADS', 'VIEW_TICKETS', 'VIEW_TASKS', 'VIEW_DASHBOARD'
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
    await prisma.activityLog.deleteMany({});
    await prisma.invitation.deleteMany({});
    await prisma.organizationDomain.deleteMany({});
    await prisma.userRole.deleteMany({});
    await prisma.userOrganization.deleteMany({});
    await prisma.user.deleteMany({});
    await prisma.organization.deleteMany({});
    
    console.log('✅ Database reset completed.\n');

    console.log('🌱 Starting B2B CRM PRODUCTION database seeding...\n');

    // 1. Create Organization
    const org = await prisma.organization.create({
      data: { 
        name: 'TechVision Solutions', 
        domain: 'techvision.com',
        logo: 'https://via.placeholder.com/200',
        website: 'https://techvision.com',
        industry: 'Software & Consulting',
        description: 'Leading B2B CRM and business solutions provider',
        isActive: true,
      },
    });
    console.log('✓ Organization: TechVision Solutions');

    // 2. Create Roles
    const rolesByType = {};
    for (const roleDef of ROLES) {
      const role = await prisma.userRole.create({
        data: {
          ...roleDef,
          organizationId: org.id,
          isDefault: roleDef.roleType === 'VIEWER',
        },
      });
      rolesByType[roleDef.roleType] = role;
    }
    console.log('✓ Roles created: Admin, Manager, Sales Agent, Viewer\n');

    // 3. Create Staff Users (7 team members)
    const passwordHash = await bcrypt.hash('password123', 10);
    const staffUsers = [
      { email: 'admin@example.com', name: 'John Mitchell', roleType: 'ADMIN' },
      { email: 'minecraftthanhloi@gmail.com', name: 'Root Admin', roleType: 'ADMIN' },
      { email: 'manager@example.com', name: 'Sarah Chen', roleType: 'MANAGER' },
      { email: 'agent@example.com', name: 'Michael Johnson', roleType: 'AGENT' },
      { email: 'agent2@example.com', name: 'Emma Williams', roleType: 'AGENT' },
      { email: 'agent3@example.com', name: 'David Martinez', roleType: 'AGENT' },
      { email: 'viewer@example.com', name: 'Lisa Anderson', roleType: 'VIEWER' },
    ];

    const createdStaff = {};
    for (const u of staffUsers) {
      const user = await prisma.user.create({
        data: { 
          email: u.email, 
          name: u.name, 
          passwordHash, 
          type: 'STAFF', 
          isActive: true 
        },
      });
      await prisma.userOrganization.create({
        data: {
          userId: user.id,
          organizationId: org.id,
          role: u.roleType,
          userRoleId: rolesByType[u.roleType].id,
        },
      });
      createdStaff[u.email] = user;
      console.log(`  ✓ ${u.roleType}: ${u.email}`);
    }
    console.log(`✓ Staff Users: ${staffUsers.length} team members created\n`);

    // 4. Create Agent references for account assignment
    const agents = [
      createdStaff['agent@example.com'],
      createdStaff['agent2@example.com'],
      createdStaff['agent3@example.com']
    ].filter(agent => agent !== undefined);
    
    if (agents.length === 0) {
      throw new Error('No agents were created. Check staff user creation.');
    }

    // 5. Create 12 B2B Accounts (Customer Companies)
    const accountsData = [
      { name: 'CloudScale Technologies', domain: 'cloudscale.io', industry: 'Cloud Computing', size: '200-500', type: 'CUSTOMER', phone: '+1-415-555-0101' },
      { name: 'DataVault Analytics', domain: 'datavault.com', industry: 'Data Analytics', size: '50-100', type: 'CUSTOMER', phone: '+1-212-555-0102' },
      { name: 'SecureNet Systems', domain: 'securenet.io', industry: 'Cybersecurity', size: '100-200', type: 'CUSTOMER', phone: '+1-650-555-0103' },
      { name: 'FastFlow Logistics', domain: 'fastflow.com', industry: 'Logistics', size: '500-1000', type: 'CUSTOMER', phone: '+1-713-555-0104' },
      { name: 'Innovate Pharma Inc', domain: 'innovatepharma.com', industry: 'Pharmaceuticals', size: '1000+', type: 'CUSTOMER', phone: '+1-201-555-0105' },
      { name: 'GreenTech Energy', domain: 'greentech.io', industry: 'Renewable Energy', size: '200-500', type: 'PROSPECT', phone: '+1-510-555-0106' },
      { name: 'RetailPro Systems', domain: 'retailpro.com', industry: 'Retail Technology', size: '100-200', type: 'CUSTOMER', phone: '+1-312-555-0107' },
      { name: 'FinTech Innovations', domain: 'fintechinno.com', industry: 'Financial Services', size: '50-100', type: 'PROSPECT', phone: '+1-617-555-0108' },
      { name: 'MediaStream Global', domain: 'mediastream.io', industry: 'Media & Broadcasting', size: '200-500', type: 'CUSTOMER', phone: '+1-424-555-0109' },
      { name: 'AutoDrive Solutions', domain: 'autodrive.com', industry: 'Automotive', size: '500-1000', type: 'PROSPECT', phone: '+1-248-555-0110' },
      { name: 'HealthConnect Pro', domain: 'healthconnect.io', industry: 'Healthcare IT', size: '100-200', type: 'CUSTOMER', phone: '+1-617-555-0111' },
      { name: 'BuildRight Construction', domain: 'buildright.com', industry: 'Construction', size: '50-100', type: 'PROSPECT', phone: '+1-303-555-0112' },
    ];

    const createdAccounts = [];
    
    for (let i = 0; i < accountsData.length; i++) {
      const acc = accountsData[i];
      const account = await prisma.account.create({
        data: {
          name: acc.name,
          domain: acc.domain,
          industry: acc.industry,
          size: acc.size,
          type: acc.type,
          phone: acc.phone,
          website: `https://www.${acc.domain}`,
          organizationId: org.id,
          ownerId: agents[i % agents.length].id, // Distribute among agents
        }
      });
      createdAccounts.push(account);

      await prisma.activityLog.create({
        data: {
          action: 'CREATE',
          entityType: 'ACCOUNT',
          entityId: account.id,
          description: `Created account: ${account.name} (${account.type})`,
          userId: createdStaff['admin@example.com'].id,
          organizationId: org.id,
          metadata: { name: account.name, industry: account.industry, type: account.type }
        }
      });
    }
    console.log(`✓ B2B Accounts: ${createdAccounts.length} accounts created\n`);

    // 5. Create 15+ Contacts (Decision makers and stakeholders)
    const contactsData = [
      { firstName: 'James', lastName: 'Wilson', email: 'j.wilson@cloudscale.io', title: 'VP of Sales', phone: '+1-415-555-1001', accountIdx: 0, city: 'San Francisco', state: 'CA' },
      { firstName: 'Rebecca', lastName: 'Thompson', email: 'r.thompson@cloudscale.io', title: 'CTO', phone: '+1-415-555-1002', accountIdx: 0, city: 'San Francisco', state: 'CA' },
      { firstName: 'Michael', lastName: 'Garcia', email: 'm.garcia@datavault.com', title: 'CEO', phone: '+1-212-555-1003', accountIdx: 1, city: 'New York', state: 'NY' },
      { firstName: 'Angela', lastName: 'Martinez', email: 'a.martinez@datavault.com', title: 'Operations Manager', phone: '+1-212-555-1004', accountIdx: 1, city: 'New York', state: 'NY' },
      { firstName: 'Christopher', lastName: 'Lee', email: 'c.lee@securenet.io', title: 'Security Director', phone: '+1-650-555-1005', accountIdx: 2, city: 'Palo Alto', state: 'CA' },
      { firstName: 'Patricia', lastName: 'Brown', email: 'p.brown@securenet.io', title: 'Project Manager', phone: '+1-650-555-1006', accountIdx: 2, city: 'Palo Alto', state: 'CA' },
      { firstName: 'Robert', lastName: 'Taylor', email: 'r.taylor@fastflow.com', title: 'Logistics Manager', phone: '+1-713-555-1007', accountIdx: 3, city: 'Houston', state: 'TX' },
      { firstName: 'Jennifer', lastName: 'Anderson', email: 'j.anderson@fastflow.com', title: 'Business Development', phone: '+1-713-555-1008', accountIdx: 3, city: 'Houston', state: 'TX' },
      { firstName: 'David', lastName: 'Jones', email: 'd.jones@innovatepharma.com', title: 'R&D Director', phone: '+1-201-555-1009', accountIdx: 4, city: 'Princeton', state: 'NJ' },
      { firstName: 'Laura', lastName: 'Davis', email: 'l.davis@innovatepharma.com', title: 'Compliance Officer', phone: '+1-201-555-1010', accountIdx: 4, city: 'Princeton', state: 'NJ' },
      { firstName: 'William', lastName: 'Harris', email: 'w.harris@greentech.io', title: 'CEO', phone: '+1-510-555-1011', accountIdx: 5, city: 'Oakland', state: 'CA' },
      { firstName: 'Maria', lastName: 'Lopez', email: 'm.lopez@retailpro.com', title: 'VP Operations', phone: '+1-312-555-1012', accountIdx: 6, city: 'Chicago', state: 'IL' },
      { firstName: 'Kevin', lastName: 'White', email: 'k.white@fintechinno.com', title: 'Chief Product Officer', phone: '+1-617-555-1013', accountIdx: 7, city: 'Boston', state: 'MA' },
      { firstName: 'Susan', lastName: 'Miller', email: 's.miller@mediastream.io', title: 'Executive Producer', phone: '+1-424-555-1014', accountIdx: 8, city: 'Los Angeles', state: 'CA' },
      { firstName: 'Thomas', lastName: 'Robinson', email: 't.robinson@autodrive.com', title: 'Engineering Manager', phone: '+1-248-555-1015', accountIdx: 9, city: 'Detroit', state: 'MI' },
    ];

    const createdContacts = [];
    for (const con of contactsData) {
      const contact = await prisma.contact.create({
        data: {
          firstName: con.firstName,
          lastName: con.lastName,
          email: con.email,
          title: con.title,
          phone: con.phone,
          city: con.city,
          state: con.state,
          country: 'USA',
          accountId: createdAccounts[con.accountIdx].id,
          organizationId: org.id,
          ownerId: agents[con.accountIdx % agents.length].id,
        }
      });
      createdContacts.push(contact);

      await prisma.activityLog.create({
        data: {
          action: 'CREATE',
          entityType: 'CONTACT',
          entityId: contact.id,
          description: `Created contact: ${contact.firstName} ${contact.lastName} (${contact.title}) at ${createdAccounts[con.accountIdx].name}`,
          userId: agents[con.accountIdx % agents.length].id,
          organizationId: org.id,
          metadata: { name: `${contact.firstName} ${contact.lastName}`, title: contact.title, account: createdAccounts[con.accountIdx].name }
        }
      });
    }
    console.log(`✓ Contacts: ${createdContacts.length} decision makers/stakeholders created\n`);

    // 6. Create 12+ Leads (Sales pipeline)
    const leadsData = [
      { firstName: 'Vincent', lastName: 'Chen', email: 'v.chen@verticaltech.com', company: 'Vertical Tech Solutions', title: 'IT Director', status: 'NEW', source: 'WEB', industry: 'Technology', rating: 'Warm' },
      { firstName: 'Sophie', lastName: 'Fontaine', email: 's.fontaine@innovators.fr', company: 'Innovators France', title: 'CEO', status: 'CONTACTED', source: 'COLD_CALL', industry: 'Consulting', rating: 'Hot' },
      { firstName: 'Marcus', lastName: 'Johnson', email: 'm.johnson@globalmfg.com', company: 'Global Manufacturing', title: 'Operations VP', status: 'QUALIFIED', source: 'PARTNER_REFERRAL', industry: 'Manufacturing', rating: 'Hot' },
      { firstName: 'Elena', lastName: 'Rodriguez', email: 'e.rodriguez@smartcity.es', company: 'Smart City Technologies', title: 'Project Lead', status: 'NEW', source: 'TRADE_SHOW', industry: 'IoT', rating: 'Warm' },
      { firstName: 'Raj', lastName: 'Patel', email: 'r.patel@indiasoft.in', company: 'India Software Services', title: 'Business Manager', status: 'PENDING', source: 'EMPLOYEE_REFERRAL', industry: 'Software', rating: 'Warm' },
      { firstName: 'Amanda', lastName: 'Stevens', email: 'a.stevens@enterprisesys.com', company: 'Enterprise Systems Inc', title: 'Procurement Manager', status: 'QUALIFIED', source: 'ADVERTISEMENT', industry: 'Enterprise Software', rating: 'Hot' },
      { firstName: 'Klaus', lastName: 'Mueller', email: 'k.mueller@deutschetech.de', company: 'Deutsche Technologies', title: 'Managing Director', status: 'CONTACTED', source: 'PHONE_INQUIRY', industry: 'Automotive Tech', rating: 'Warm' },
      { firstName: 'Yuki', lastName: 'Tanaka', email: 'y.tanaka@japantech.jp', company: 'Japan Tech Innovations', title: 'Sales Director', status: 'NEW', source: 'WEB', industry: 'Electronics', rating: 'Cold' },
      { firstName: 'Paulo', lastName: 'Silva', email: 'p.silva@brasilesolutions.br', company: 'Brasil Solutions', title: 'Technical Director', status: 'PENDING', source: 'OTHER', industry: 'Consulting', rating: 'Warm' },
      { firstName: 'Hannah', lastName: 'Schmidt', email: 'h.schmidt@australiaservices.com.au', company: 'Australia Services Group', title: 'Account Manager', status: 'QUALIFIED', source: 'PARTNER_REFERRAL', industry: 'Business Services', rating: 'Hot' },
      { firstName: 'Ahmed', lastName: 'Hassan', email: 'a.hassan@middleeastsys.ae', company: 'Middle East Systems', title: 'VP Technology', status: 'NEW', source: 'WEB', industry: 'IT Solutions', rating: 'Warm' },
      { firstName: 'Natasha', lastName: 'Volkov', email: 'n.volkov@russiainnovate.ru', company: 'Russia Innovations Ltd', title: 'Executive Director', status: 'CONTACTED', source: 'COLD_CALL', industry: 'Software Development', rating: 'Warm' },
    ];

    const createdLeads = [];
    for (const l of leadsData) {
      const lead = await prisma.lead.create({
        data: {
          firstName: l.firstName,
          lastName: l.lastName,
          email: l.email,
          company: l.company,
          title: l.title,
          status: l.status,
          leadSource: l.source,
          industry: l.industry,
          rating: l.rating,
          organizationId: org.id,
          ownerId: agents[Math.floor(Math.random() * agents.length)].id,
        }
      });
      createdLeads.push(lead);

      await prisma.activityLog.create({
        data: {
          action: 'CREATE',
          entityType: 'LEAD',
          entityId: lead.id,
          description: `New lead: ${lead.firstName} ${lead.lastName} from ${lead.company} (${lead.status})`,
          userId: lead.ownerId,
          organizationId: org.id,
          metadata: { name: `${lead.firstName} ${lead.lastName}`, company: lead.company, status: lead.status, rating: lead.rating }
        }
      });
    }
    console.log(`✓ Leads: ${createdLeads.length} sales opportunities created\n`);

    // 7. Create 15+ Tasks (Sales activities)
    const tasksData = [
      { subject: 'Initial discovery call with James Wilson', priority: 'HIGH', status: 'COMPLETED', contactIdx: 0, daysFromNow: -2 },
      { subject: 'Send proposal to CloudScale Technologies', priority: 'HIGH', status: 'IN_PROGRESS', accountIdx: 0, daysFromNow: 2 },
      { subject: 'Follow up on DataVault quote', priority: 'NORMAL', status: 'NOT_STARTED', accountIdx: 1, daysFromNow: 3 },
      { subject: 'Schedule demo with SecureNet team', priority: 'HIGH', status: 'IN_PROGRESS', accountIdx: 2, daysFromNow: 1 },
      { subject: 'Prepare contract for FastFlow Logistics', priority: 'NORMAL', status: 'NOT_STARTED', accountIdx: 3, daysFromNow: 5 },
      { subject: 'Executive briefing with Innovate Pharma', priority: 'HIGH', status: 'COMPLETED', accountIdx: 4, daysFromNow: -1 },
      { subject: 'Quarterly business review - GreenTech', priority: 'NORMAL', status: 'NOT_STARTED', accountIdx: 5, daysFromNow: 7 },
      { subject: 'Requirements gathering - RetailPro Systems', priority: 'NORMAL', status: 'IN_PROGRESS', accountIdx: 6, daysFromNow: 2 },
      { subject: 'Follow up with Sophie Fontaine lead', priority: 'HIGH', status: 'NOT_STARTED', leadIdx: 1, daysFromNow: 1 },
      { subject: 'Prepare contract negotiation for Marcus Johnson', priority: 'HIGH', status: 'IN_PROGRESS', leadIdx: 2, daysFromNow: 3 },
      { subject: 'Product training session scheduling', priority: 'NORMAL', status: 'NOT_STARTED', contactIdx: 4, daysFromNow: 4 },
      { subject: 'Follow up quote - Elena Rodriguez', priority: 'NORMAL', status: 'NOT_STARTED', leadIdx: 3, daysFromNow: 2 },
      { subject: 'Technical evaluation with Amanda Stevens', priority: 'HIGH', status: 'IN_PROGRESS', leadIdx: 5, daysFromNow: 1 },
      { subject: 'Review service agreement - HealthConnect Pro', priority: 'NORMAL', status: 'COMPLETED', accountIdx: 10, daysFromNow: -3 },
      { subject: 'Negotiate terms with BuildRight Construction', priority: 'NORMAL', status: 'NOT_STARTED', accountIdx: 11, daysFromNow: 6 },
    ];

    for (const t of tasksData) {
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + t.daysFromNow);

      await prisma.task.create({
        data: {
          subject: t.subject,
          priority: t.priority,
          status: t.status,
          dueDate: dueDate,
          organizationId: org.id,
          ownerId: agents[Math.floor(Math.random() * agents.length)].id,
          createdById: createdStaff['manager@example.com'].id,
          ...(t.contactIdx !== undefined && { contactId: createdContacts[t.contactIdx].id }),
          ...(t.accountIdx !== undefined && { accountId: createdAccounts[t.accountIdx].id }),
          ...(t.leadIdx !== undefined && { leadId: createdLeads[t.leadIdx].id }),
        }
      });
    }
    console.log(`✓ Tasks: ${tasksData.length} sales activities created\n`);

    // 8. Create 10+ Support Tickets (Customer issues and requests)
    const ticketsData = [
      { subject: 'Dashboard performance issues', priority: 'HIGH', status: 'IN_PROGRESS', accountIdx: 0, category: 'Technical' },
      { subject: 'User license renewal inquiry', priority: 'NORMAL', status: 'OPEN', accountIdx: 1, category: 'Billing' },
      { subject: 'API integration assistance needed', priority: 'HIGH', status: 'IN_PROGRESS', accountIdx: 2, category: 'Technical' },
      { subject: 'Custom report configuration', priority: 'NORMAL', status: 'OPEN', accountIdx: 3, category: 'Feature Request' },
      { subject: 'Data migration from legacy system', priority: 'HIGH', status: 'IN_PROGRESS', accountIdx: 4, category: 'Implementation' },
      { subject: 'SSO/SAML authentication setup', priority: 'HIGH', status: 'OPEN', accountIdx: 6, category: 'Technical' },
      { subject: 'Bulk user import functionality', priority: 'NORMAL', status: 'RESOLVED', accountIdx: 7, category: 'Feature Request' },
      { subject: 'Export data in multiple formats', priority: 'LOW', status: 'OPEN', accountIdx: 8, category: 'Feature Request' },
      { subject: 'Performance optimization consultation', priority: 'NORMAL', status: 'IN_PROGRESS', accountIdx: 9, category: 'Consulting' },
      { subject: 'Training session for admin team', priority: 'NORMAL', status: 'OPEN', accountIdx: 10, category: 'Training' },
    ];

    for (const t of ticketsData) {
      const ticket = await prisma.ticket.create({
        data: {
          subject: t.subject,
          priority: t.priority,
          status: t.status,
          category: t.category,
          organizationId: org.id,
          accountId: createdAccounts[t.accountIdx].id,
          ownerId: agents[Math.floor(Math.random() * agents.length)].id,
        }
      });

      // Add ticket messages
      const messages = [
        `Customer reported: ${t.subject}`,
        t.priority === 'HIGH' ? 'Escalated due to high priority' : 'Initial assessment completed',
      ];

      for (const msg of messages) {
        await prisma.ticketMessage.create({
          data: {
            content: msg,
            ticketId: ticket.id,
            authorId: agents[Math.floor(Math.random() * agents.length)].id,
            isInternal: Math.random() > 0.7,
          }
        });
      }
    }
    console.log(`✓ Support Tickets: ${ticketsData.length} customer tickets created\n`);

    // 9. Simulate Lead Conversions (2-3 successful conversions)
    const leadsToConvert = [createdLeads[2], createdLeads[5], createdLeads[9]]; // Marcus, Amanda, Hannah
    
    for (const lead of leadsToConvert) {
      const newAccount = await prisma.account.create({
        data: {
          name: lead.company,
          domain: lead.company.toLowerCase().replace(/\s+/g, ''),
          industry: lead.industry,
          type: 'CUSTOMER',
          organizationId: org.id,
          ownerId: lead.ownerId,
        }
      });

      const newContact = await prisma.contact.create({
        data: {
          firstName: lead.firstName,
          lastName: lead.lastName,
          email: lead.email,
          title: lead.title,
          accountId: newAccount.id,
          organizationId: org.id,
          ownerId: lead.ownerId,
        }
      });

      await prisma.lead.update({
        where: { id: lead.id },
        data: {
          status: 'CONVERTED',
          isConverted: true,
          convertedAt: new Date(),
          convertedAccountId: newAccount.id,
          convertedContactId: newContact.id,
        }
      });

      await prisma.activityLog.create({
        data: {
          action: 'CONVERT',
          entityType: 'LEAD',
          entityId: lead.id,
          description: `Lead CONVERTED: ${lead.firstName} ${lead.lastName} from ${lead.company} → New Account & Contact Created`,
          userId: lead.ownerId,
          organizationId: org.id,
          metadata: { 
            leadId: lead.id, 
            accountId: newAccount.id, 
            contactId: newContact.id,
            company: lead.company
          }
        }
      });
    }
    console.log(`✓ Lead Conversions: ${leadsToConvert.length} leads converted to customers\n`);

    // 10. Organization Domains for account mapping
    // Link domains to specific accounts for lead conversion
    const domainMappings = [
      { domain: 'cloudscale.io', accountName: 'CloudScale Systems' },
      { domain: 'datavault.com', accountName: 'DataVault Inc' },
      { domain: 'securenet.io', accountName: 'SecureNet Solutions' },
      { domain: 'fastflow.com', accountName: 'FastFlow Logistics' },
    ];
    
    let domainsCreated = 0;
    for (const mapping of domainMappings) {
      // Find the account by name
      const account = await prisma.account.findFirst({
        where: {
          organizationId: org.id,
          name: mapping.accountName,
        },
      });

      await prisma.organizationDomain.create({
        data: {
          organizationId: org.id,
          accountId: account?.id, // Link to account if found
          domain: mapping.domain,
          verified: true,
          createdBy: createdStaff['admin@example.com'].id,
        }
      });
      domainsCreated++;
    }
    console.log(`✓ Organization Domains: ${domainsCreated} domains configured for account mapping\n`);

    // Summary
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('🎉 B2B CRM PRODUCTION SEEDING COMPLETED SUCCESSFULLY!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('\n📊 DATA SUMMARY:');
    console.log(`  • Organizations: 1`);
    console.log(`  • Staff Users: ${staffUsers.length}`);
    console.log(`  • B2B Accounts: ${createdAccounts.length}`);
    console.log(`  • Contacts (Stakeholders): ${createdContacts.length}`);
    console.log(`  • Leads (Sales Pipeline): ${createdLeads.length}`);
    console.log(`  • Tasks (Activities): ${tasksData.length}`);
    console.log(`  • Support Tickets: ${ticketsData.length}`);
    console.log(`  • Lead Conversions: ${leadsToConvert.length}`);
    console.log(`  • Activity Logs: ${1 + staffUsers.length + createdAccounts.length + createdContacts.length + createdLeads.length + leadsToConvert.length}`);
    console.log('═══════════════════════════════════════════════════════════════\n');

  } catch (err) {
    console.error('\n❌ Seeding failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
