import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

dotenv.config();

/**
 * Enhanced seed script with:
 * - Organizations with domain mappings
 * - Test customer accounts
 * - Sample CRM data
 * - Admin users with proper permissions
 */
async function main() {
  try {
    console.log('🌱 Starting enhanced database seeding...\n');

    // ===== STEP 1: Create Default Organization & Root Admin =====
    console.log('📦 Creating default organization and root admin...');
    
    const rootAdminEmail = process.env.ROOT_ADMIN_EMAIL || 'minecraftthanhloi@gmail.com';
    const defaultOrgName = process.env.ORG_NAME || 'Default Organization';
    const defaultOrgDomain = process.env.ORG_DOMAIN || 'example.com';

    // Create or get default organization
    let org = await prisma.organization.findFirst({
      where: { domain: defaultOrgDomain },
    });

    if (!org) {
      org = await prisma.organization.create({
        data: {
          name: defaultOrgName,
          domain: defaultOrgDomain,
          isActive: true,
        },
      });
    }

    // Create or get root admin user
    let user = await prisma.user.findUnique({
      where: { email: rootAdminEmail },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email: rootAdminEmail,
          name: 'Root Admin',
          type: 'STAFF',
          isActive: true,
        },
      });
    }

    console.log(`✓ Organization: ${org.name} (${org.id})`);
    console.log(`✓ Root Admin: ${user.email} (${user.id})\n`);

    // ===== STEP 2: Create Additional Organizations =====
    console.log('🏢 Creating additional organizations...');
    
    let acmeOrg = await prisma.organization.findFirst({
      where: { domain: 'acme.com' },
    });
    
    if (!acmeOrg) {
      acmeOrg = await prisma.organization.create({
        data: {
          name: 'Acme Corporation',
          domain: 'acme.com',
          isActive: true,
        },
      });
    }
    console.log(`✓ Acme Corporation (${acmeOrg.id})`);

    let techStartOrg = await prisma.organization.findFirst({
      where: { domain: 'techstart.io' },
    });
    
    if (!techStartOrg) {
      techStartOrg = await prisma.organization.create({
        data: {
          name: 'TechStart Inc',
          domain: 'techstart.io',
          isActive: true,
        },
      });
    }
    console.log(`✓ TechStart Inc (${techStartOrg.id})\n`);

    // ===== STEP 3: Create Organization Domain Mappings =====
    console.log('🌐 Creating domain auto-assignment mappings...');
    
    // Acme Corporation domains
    await prisma.organizationDomain.upsert({
      where: { domain: 'acme.com' },
      create: {
        organizationId: acmeOrg.id,
        domain: 'acme.com',
        isActive: true,
        autoAssign: true,
        priority: 10,
        createdBy: user.id,
      },
      update: { isActive: true, autoAssign: true },
    });
    console.log('✓ acme.com → Acme Corporation (priority: 10)');

    await prisma.organizationDomain.upsert({
      where: { domain: 'acmecorp.com' },
      create: {
        organizationId: acmeOrg.id,
        domain: 'acmecorp.com',
        isActive: true,
        autoAssign: true,
        priority: 5,
        createdBy: user.id,
      },
      update: { isActive: true, autoAssign: true },
    });
    console.log('✓ acmecorp.com → Acme Corporation (priority: 5)');

    // TechStart Inc domains
    await prisma.organizationDomain.upsert({
      where: { domain: 'techstart.io' },
      create: {
        organizationId: techStartOrg.id,
        domain: 'techstart.io',
        isActive: true,
        autoAssign: true,
        priority: 10,
        createdBy: user.id,
      },
      update: { isActive: true, autoAssign: true },
    });
    console.log('✓ techstart.io → TechStart Inc (priority: 10)');

    await prisma.organizationDomain.upsert({
      where: { domain: 'techstart.com' },
      create: {
        organizationId: techStartOrg.id,
        domain: 'techstart.com',
        isActive: true,
        autoAssign: true,
        priority: 8,
        createdBy: user.id,
      },
      update: { isActive: true, autoAssign: true },
    });
    console.log('✓ techstart.com → TechStart Inc (priority: 8)\n');

    // ===== STEP 4: Create UserOrganization Links =====
    console.log('🔗 Linking users to organizations...');
    
    // Link root admin to default organization
    const rootAdminLink = await prisma.userOrganization.findFirst({
      where: { userId: user.id, organizationId: org.id },
    });

    if (!rootAdminLink) {
      await prisma.userOrganization.create({
        data: {
          userId: user.id,
          organizationId: org.id,
          role: 'ADMIN',
        },
      });
      console.log('✓ Root admin linked to default organization\n');
    } else {
      console.log('✓ Root admin already linked\n');
    }

    // ===== STEP 5: Create Debug Admin User =====
    console.log('🧪 Creating debug admin user (admin@example.com)...');
    const passwordHash = await bcrypt.hash('password123', 10);
    
    const debugAdmin = await prisma.user.upsert({
      where: { email: 'admin@example.com' },
      create: {
        email: 'admin@example.com',
        name: 'Admin User',
        passwordHash,
        type: 'STAFF',
        isActive: true,
      },
      update: { passwordHash },
    });
    console.log(`✓ Debug admin created: ${debugAdmin.email}`);

    // Link debug admin to organization with admin role
    const debugAdminOrgLink = await prisma.userOrganization.findFirst({
      where: { userId: debugAdmin.id, organizationId: org.id },
    });

    if (!debugAdminOrgLink) {
      await prisma.userOrganization.create({
        data: {
          userId: debugAdmin.id,
          organizationId: org.id,
          role: 'ADMIN',
        },
      });
      console.log('✓ Debug admin linked to default organization\n');
    }

    // ===== STEP 6: Create Test Customer Users =====
    console.log('👥 Creating test customer accounts...');
    
    // Customer 1: john@acme.com (will auto-match to Acme Corporation)
    const customer1 = await prisma.user.upsert({
      where: { email: 'john@acme.com' },
      create: {
        email: 'john@acme.com',
        name: 'John Doe',
        passwordHash,
        type: 'CUSTOMER',
        isActive: true,
      },
      update: {},
    });

    await prisma.customerProfile.upsert({
      where: { userId: customer1.id },
      create: {
        userId: customer1.id,
        organizationId: acmeOrg.id,
        companyName: 'Acme Corporation',
        phone: '+1-555-0101',
      },
      update: {},
    });
    console.log(`✓ ${customer1.email} → Acme Corporation`);

    // Customer 2: jane@techstart.io (will auto-match to TechStart Inc)
    const customer2 = await prisma.user.upsert({
      where: { email: 'jane@techstart.io' },
      create: {
        email: 'jane@techstart.io',
        name: 'Jane Smith',
        passwordHash,
        type: 'CUSTOMER',
        isActive: true,
      },
      update: {},
    });

    await prisma.customerProfile.upsert({
      where: { userId: customer2.id },
      create: {
        userId: customer2.id,
        organizationId: techStartOrg.id,
        companyName: 'TechStart Inc',
        phone: '+1-555-0202',
      },
      update: {},
    });
    console.log(`✓ ${customer2.email} → TechStart Inc`);

    // Customer 3: unassigned@gmail.com (generic domain, no auto-match)
    const customer3 = await prisma.user.upsert({
      where: { email: 'customer@gmail.com' },
      create: {
        email: 'customer@gmail.com',
        name: 'Unassigned Customer',
        passwordHash,
        type: 'CUSTOMER',
        isActive: true,
      },
      update: {},
    });

    await prisma.customerProfile.upsert({
      where: { userId: customer3.id },
      create: {
        userId: customer3.id,
        organizationId: null, // No auto-match for generic domains
        companyName: null,
        phone: '+1-555-0303',
      },
      update: {},
    });
    console.log(`✓ ${customer3.email} → Unassigned (generic domain)\n`);

    // ===== STEP 7: Create Sample CRM Data =====
    console.log('📊 Creating sample CRM data...');
    
    // Accounts
    let account1 = await prisma.account.findFirst({
      where: { 
        organizationId: org.id,
        name: 'Sample Customer Inc',
      },
    });

    if (!account1) {
      account1 = await prisma.account.create({
        data: {
          name: 'Sample Customer Inc',
          type: 'Customer',
          website: 'https://samplecustomer.example',
          organizationId: org.id,
        },
      });
    }
    console.log(`✓ Account: ${account1.name}`);

    // Contacts
    let contact1 = await prisma.contact.findFirst({
      where: {
        organizationId: org.id,
        email: 'alice@samplecustomer.example',
      },
    });

    if (!contact1) {
      contact1 = await prisma.contact.create({
        data: {
          firstName: 'Alice',
          lastName: 'Johnson',
          email: 'alice@samplecustomer.example',
          phone: '+1-555-0404',
          ownerId: user.id,
          organizationId: org.id,
        },
      });
    }
    console.log(`✓ Contact: ${contact1.firstName} ${contact1.lastName}`);

    // Leads
    let lead1 = await prisma.lead.findFirst({
      where: {
        organizationId: org.id,
        email: 'lead@prospect.example',
      },
    });

    if (!lead1) {
      lead1 = await prisma.lead.create({
        data: {
          firstName: 'Bob',
          lastName: 'Prospect',
          email: 'lead@prospect.example',
          status: 'NEW',
          leadSource: 'WEB',
          organizationId: org.id,
          ownerId: user.id,
        },
      });
    }
    console.log(`✓ Lead: ${lead1.firstName} ${lead1.lastName}`);

    // Tasks (use correct enums: TaskStatus.NOT_STARTED, TaskPriority.HIGH)
    const task1 = await prisma.task.create({
      data: {
        subject: 'Follow up with Alice',
        description: 'Schedule demo call',
        status: 'NOT_STARTED',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        ownerId: user.id,
        organizationId: org.id,
      },
    });
    console.log(`✓ Task: ${task1.subject}`);

    // Tickets (use correct enums: TicketStatus.OPEN, TicketPriority.URGENT)
    const ticket1 = await prisma.ticket.create({
      data: {
        subject: 'Login Issue',
        description: 'Customer cannot access dashboard',
        status: 'OPEN',
        priority: 'URGENT',
        ownerId: user.id,
        organizationId: org.id,
      },
    });
    console.log(`✓ Ticket: ${ticket1.subject}\n`);

    // ===== STEP 8: Log Seeding Activity =====
    await prisma.activityLog.create({
      data: {
        action: 'DATABASE_SEEDED',
        entityType: 'System',
        entityId: org.id,
        description: 'Database seeded with organizations, domain mappings, test customers, and sample CRM data',
        userId: user.id,
        organizationId: org.id,
        metadata: {
          organizations: 3,
          domainMappings: 4,
          testCustomers: 3,
          sampleData: true,
        },
      },
    });

    // ===== Summary =====
    console.log('📋 Seeding Summary:');
    console.log('  ✓ Organizations: 3');
    console.log('  ✓ Domain Mappings: 4');
    console.log('  ✓ Admin Users: 2 (root + debug)');
    console.log('  ✓ Test Customers: 3');
    console.log('  ✓ Sample CRM Data: ✓');
    console.log('\n🎉 Database seeding completed successfully!\n');
    
    console.log('📝 Test Credentials:');
    console.log('  Staff Login:');
    console.log('    Email: admin@example.com');
    console.log('    Password: password123');
    console.log('\n  Customer Logins:');
    console.log('    1. john@acme.com / password123 (Auto-matched: Acme Corp)');
    console.log('    2. jane@techstart.io / password123 (Auto-matched: TechStart)');
    console.log('    3. customer@gmail.com / password123 (Unassigned)');
    console.log('\n  New Registration Test:');
    console.log('    Try: test@acme.com (should auto-match to Acme Corporation)');
    console.log('    Try: demo@techstart.io (should auto-match to TechStart Inc)\n');

  } catch (err) {
    console.error('\n❌ Seeding failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
