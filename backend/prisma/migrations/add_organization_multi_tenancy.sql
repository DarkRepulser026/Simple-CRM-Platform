-- AlterTable CustomerProfile - Add organization support
ALTER TABLE "customer_profiles" 
ADD COLUMN "organizationId" TEXT,
ADD COLUMN "assignedAt" TIMESTAMP(3),
ADD COLUMN "assignedBy" TEXT;

-- CreateIndex
CREATE INDEX "customer_profiles_organizationId_idx" ON "customer_profiles"("organizationId");

-- CreateIndex
CREATE INDEX "customer_profiles_companyName_idx" ON "customer_profiles"("companyName");

-- AddForeignKey
ALTER TABLE "customer_profiles" 
ADD CONSTRAINT "customer_profiles_organizationId_fkey" 
FOREIGN KEY ("organizationId") REFERENCES "organizations"("id") 
ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable Ticket - Add SLA and response tracking
ALTER TABLE "tickets" 
ADD COLUMN "slaDeadline" TIMESTAMP(3),
ADD COLUMN "respondedAt" TIMESTAMP(3),
ADD COLUMN "resolvedAt" TIMESTAMP(3);

-- CreateIndex for better query performance
CREATE INDEX "tickets_organizationId_idx" ON "tickets"("organizationId");
CREATE INDEX "tickets_customerId_idx" ON "tickets"("customerId");
CREATE INDEX "tickets_status_idx" ON "tickets"("status");

-- Update existing tickets to set organizationId for staff-owned tickets
-- This assumes tickets belong to the organization of their owner
UPDATE "tickets" t
SET "organizationId" = uo."organizationId"
FROM "users" u
JOIN "user_organizations" uo ON u."id" = uo."userId"
WHERE t."ownerId" = u."id" 
AND t."organizationId" IS NULL
AND u."type" = 'STAFF';

-- For customer tickets without organization, try to match from customer profile
UPDATE "tickets" t
SET "organizationId" = cp."organizationId"
FROM "users" u
JOIN "customer_profiles" cp ON u."id" = cp."userId"
WHERE t."customerId" = u."id"
AND t."organizationId" IS NULL
AND cp."organizationId" IS NOT NULL;
