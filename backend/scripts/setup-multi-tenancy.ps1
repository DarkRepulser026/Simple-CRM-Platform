# Organization Multi-Tenancy Setup Script (PowerShell)
# This script sets up the organization-based customer assignment system

Write-Host "🚀 Setting up Organization Multi-Tenancy..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if we're in the right directory
if (-not (Test-Path "backend\prisma\schema.prisma")) {
    Write-Host "❌ Error: Run this script from the project root directory" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Project directory confirmed" -ForegroundColor Green
Write-Host ""

# Step 2: Install dependencies
Write-Host "📦 Checking backend dependencies..." -ForegroundColor Cyan
Set-Location backend

if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

Write-Host "✅ Dependencies ready" -ForegroundColor Green
Write-Host ""

# Step 3: Generate Prisma Client
Write-Host "🔧 Generating Prisma Client..." -ForegroundColor Cyan
npx prisma generate
Write-Host "✅ Prisma Client generated" -ForegroundColor Green
Write-Host ""

# Step 4: Run migration
Write-Host "🗄️ Running database migration..." -ForegroundColor Cyan
$continue = Read-Host "This will modify your database. Continue? (y/N)"

if ($continue -eq 'y' -or $continue -eq 'Y') {
    npx prisma migrate dev --name add_organization_multi_tenancy
    Write-Host "✅ Migration completed" -ForegroundColor Green
} else {
    Write-Host "⏭️ Skipping migration (you can run manually later)" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Set up test organizations
Write-Host "🏢 Setting up test organizations..." -ForegroundColor Cyan
$createOrgs = Read-Host "Create test organizations with email domains? (y/N)"

if ($createOrgs -eq 'y' -or $createOrgs -eq 'Y') {
    $script = @"
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    
    async function setup() {
      console.log('Creating test organizations...');
      
      const orgs = [
        { name: 'Acme Corporation', domain: 'acme.com' },
        { name: 'TechStart Inc', domain: 'techstart.io' },
        { name: 'Global Solutions', domain: 'globalsolutions.com' },
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
          console.log(\`✗ Error: \${e.message}\`);
        }
      }
      
      await prisma.\$disconnect();
    }
    
    setup();
"@
    
    node -e $script
    Write-Host "✅ Test organizations created" -ForegroundColor Green
} else {
    Write-Host "⏭️ Skipping test data" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Verify setup
Write-Host "🔍 Verifying setup..." -ForegroundColor Cyan

$verifyScript = @"
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
"@

node -e $verifyScript
Write-Host ""

# Step 7: Show next steps
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Start the backend: npm run dev"
Write-Host "2. Test customer registration with corporate email"
Write-Host "3. Access admin panel at /admin/customer-organizations"
Write-Host "4. View unassigned customers and assign them"
Write-Host ""
Write-Host "📖 Documentation: docs\ORGANIZATION_MULTI_TENANCY.md"
Write-Host ""
Write-Host "🎉 You're all set!" -ForegroundColor Green

# Return to project root
Set-Location ..
