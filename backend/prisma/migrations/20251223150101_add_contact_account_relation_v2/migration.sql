/*
  Warnings:

  - A unique constraint covering the columns `[email,accountId]` on the table `contacts` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "accounts" ADD COLUMN     "domain" TEXT,
ADD COLUMN     "industry" TEXT,
ADD COLUMN     "ownerId" TEXT,
ADD COLUMN     "size" TEXT;

-- AlterTable
ALTER TABLE "contacts" ADD COLUMN     "accountId" TEXT;

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "accountId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "contacts_email_accountId_key" ON "contacts"("email", "accountId");

-- CreateIndex
CREATE INDEX "tickets_accountId_idx" ON "tickets"("accountId");

-- AddForeignKey
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
