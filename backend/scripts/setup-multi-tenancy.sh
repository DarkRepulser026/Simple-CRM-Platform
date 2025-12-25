#!/bin/bash

# Organization Multi-Tenancy Setup Script
# This script sets up the organization-based customer assignment system

echo "🚀 Setting up Organization Multi-Tenancy..."
echo ""

# Step 1: Check if we're in the right directory
if [ ! -f "backend/prisma/schema.prisma" ]; then
    echo "❌ Error: Run this script from the project root directory"
    exit 1
fi

echo "✅ Project directory confirmed"
echo ""

# Step 2: Install dependencies (if needed)
echo "📦 Checking backend dependencies..."
cd backend
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
echo "✅ Dependencies ready"
echo ""

# Step 3: Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate
echo "✅ Prisma Client generated"
echo ""

# Step 4: Run migration
echo "🗄️ Running database migration..."
read -p "This will modify your database. Continue? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npx prisma migrate dev --name add_organization_multi_tenancy
    echo "✅ Migration completed"
else
    echo "⏭️ Skipping migration (you can run manually later)"
fi
echo ""

# Step 5: Set up test organizations with domains
echo "🏢 Setting up test organizations..."
read -p "Create test organizations with email domains? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    node -e "
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    
    async function setup() {
      console.log('Creating test organizations...');
      
      // Create sample organizations
      const orgs = [
        { name: 'Acme Corporation', domain: 'acme.com' },
        { name: 'TechStart Inc', domain: 'techstart.io' },
        { name: 'Global Solutions', domain: 'globalsolutions.com' },
        { name: 'Google Inc', domain: 'google.com' },
      ];
      
      for (const org of orgs) {
        try {
          const existing = await prisma.organization.findFirst({
            where: { domain: org.domain }
          });
          
          if (!existing) {
            await prisma.organization.create({ data: org });
            console.log(\`✓ Created: \${org.name} (\${org.domain})\`);
          } else {
            console.log(\`⏭️ Exists: \${org.name}\`);
          }
        } catch (e) {
          console.log(\`✗ Error creating \${org.name}: \${e.message}\`);
        }
      }
      
      await prisma.\$disconnect();
    }
    
    setup();
    "
    echo "✅ Test organizations created"
else
    echo "⏭️ Skipping test data"
fi
echo ""

# Step 6: Verify setup
echo "🔍 Verifying setup..."
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verify() {
  try {
    const [orgs, customers] = await Promise.all([
      prisma.organization.count(),
      prisma.customerProfile.count()
    ]);
    
    console.log(\`Organizations: \${orgs}\`);
    console.log(\`Customer Profiles: \${customers}\`);
    
    const assigned = await prisma.customerProfile.count({
      where: { organizationId: { not: null } }
    });
    
    console.log(\`Assigned Customers: \${assigned}\`);
    console.log(\`Unassigned Customers: \${customers - assigned}\`);
  } catch (e) {
    console.log('⚠️ Could not verify - database may not be ready');
  }
  
  await prisma.\$disconnect();
}

verify();
"
echo ""

# Step 7: Show next steps
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Start the backend: npm run dev"
echo "2. Test customer registration with corporate email"
echo "3. Access admin panel at /admin/customer-organizations"
echo "4. View unassigned customers and assign them"
echo ""
echo "📖 Documentation: docs/ORGANIZATION_MULTI_TENANCY.md"
echo ""
echo "🎉 You're all set!"
