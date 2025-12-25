/*
  Warnings:

  - You are about to drop the `customer_profiles_archived` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."customer_profiles_archived" DROP CONSTRAINT "customer_profiles_organizationId_fkey";

-- DropForeignKey
ALTER TABLE "public"."customer_profiles_archived" DROP CONSTRAINT "customer_profiles_userId_fkey";

-- DropIndex
DROP INDEX "public"."idx_accounts_deleted_type";

-- DropIndex
DROP INDEX "public"."idx_accounts_organization_domain";

-- DropIndex
DROP INDEX "public"."idx_activity_log_entity_created";

-- DropIndex
DROP INDEX "public"."idx_contacts_deleted_account";

-- DropIndex
DROP INDEX "public"."idx_contacts_organization_account";

-- DropIndex
DROP INDEX "public"."idx_leads_deleted_status";

-- DropIndex
DROP INDEX "public"."idx_leads_organization_status";

-- DropIndex
DROP INDEX "public"."organization_domains_domain_key";

-- DropIndex
DROP INDEX "public"."idx_tasks_deleted_status";

-- DropIndex
DROP INDEX "public"."idx_tasks_organization_status";

-- DropIndex
DROP INDEX "public"."idx_tickets_organization_status";

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "createdById" TEXT;

-- DropTable
DROP TABLE "public"."customer_profiles_archived";

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
