/**
 * Delete test@acme.com user and related data
 * CAUTION: This will permanently delete the user and all associated data
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const email = 'test@acme.com';
  
  console.log(`⚠️  WARNING: This will delete user ${email} and ALL associated data!\n`);
  
  const user = await prisma.user.findUnique({
    where: { email },
    include: {
      customerProfile: true,
    },
  });

  if (!user) {
    console.log(`✅ No user with email ${email} exists`);
    return;
  }

  console.log('User to be deleted:');
  console.log(`  ID: ${user.id}`);
  console.log(`  Email: ${user.email}`);
  console.log(`  Name: ${user.name}`);
  console.log(`  Type: ${user.type}`);
  
  if (user.customerProfile) {
    console.log(`  Customer Profile ID: ${user.customerProfile.id}`);
    console.log(`  Company: ${user.customerProfile.companyName || 'N/A'}`);
  }

  console.log('\n🗑️  Deleting user in 3 seconds... (Ctrl+C to cancel)\n');
  
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Delete in transaction
  await prisma.$transaction(async (tx) => {
    // Delete customer profile first (due to foreign key)
    if (user.customerProfile) {
      await tx.customerProfile.delete({
        where: { id: user.customerProfile.id },
      });
      console.log('✓ Deleted customer profile');
    }

    // Delete user
    await tx.user.delete({
      where: { id: user.id },
    });
    console.log('✓ Deleted user');
  });

  console.log('\n✅ User successfully deleted!');
  console.log(`You can now register with ${email}`);
}

main()
  .catch((e) => {
    console.error('Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
