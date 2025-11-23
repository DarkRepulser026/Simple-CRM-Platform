import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const email = "rootadmin@example.com";

  const existing = await prisma.admin.findUnique({ where: { email } });
  if (existing) {
    console.log("Admin already exists.");
    return;
  }

  const admin = await prisma.admin.create({
    data: {
      email,
      name: "Root Admin",
      passwordHash: await bcrypt.hash("TempPassword123!", 12),
      role: "SUPERADMIN",
    },
  });

  console.log("Seed admin created:", admin);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
