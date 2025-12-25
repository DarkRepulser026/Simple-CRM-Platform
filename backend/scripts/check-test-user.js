/**
 * Check if test@acme.com exists and show details
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🔍 Checking for test@acme.com user...\n');

  const user = await prisma.user.findUnique({
    where: { email: 'test@acme.com' },
    include: {
      customerProfile: {
        include: {
          organization: true,
        },
      },
    },
  });

  if (!user) {
    console.log('✅ No user with email test@acme.com exists');
    console.log('You can register with this email.');
    return;
  }

  console.log('❌ User already exists with this email:\n');
  console.log('User Details:');
  console.log(`  ID: ${user.id}`);
  console.log(`  Email: ${user.email}`);
  console.log(`  Name: ${user.name}`);
  console.log(`  Type: ${user.type}`);
  console.log(`  Active: ${user.isActive}`);
  console.log(`  Created: ${user.createdAt}`);

  if (user.customerProfile) {
    console.log('\nCustomer Profile:');
    console.log(`  ID: ${user.customerProfile.id}`);
    console.log(`  Company: ${user.customerProfile.companyName || 'N/A'}`);
    console.log(`  Phone: ${user.customerProfile.phone || 'N/A'}`);
    console.log(`  Organization ID: ${user.customerProfile.organizationId || 'N/A'}`);
    console.log(`  Organization Name: ${user.customerProfile.organization?.name || 'N/A'}`);
  }

  console.log('\n💡 Options:');
  console.log('  1. Login with this email instead of registering');
  console.log('  2. Delete this user: node backend/scripts/delete-test-user.js');
  console.log('  3. Use a different email for testing');
}

main()
  .catch((e) => {
    console.error('Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
