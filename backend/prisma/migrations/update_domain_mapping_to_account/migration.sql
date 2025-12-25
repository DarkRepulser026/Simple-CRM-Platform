-- Migration: Update OrganizationDomain to use Account-based mapping
-- This aligns domain mapping with B2B CRM architecture

-- Step 1: Add accountId column (nullable)
ALTER TABLE "organization_domains" ADD COLUMN "accountId" TEXT;

-- Step 2: Add verified column (default false)
ALTER TABLE "organization_domains" ADD COLUMN "verified" BOOLEAN NOT NULL DEFAULT false;

-- Step 3: Remove old columns that are no longer needed
ALTER TABLE "organization_domains" DROP COLUMN IF EXISTS "isActive";
ALTER TABLE "organization_domains" DROP COLUMN IF EXISTS "autoAssign";
ALTER TABLE "organization_domains" DROP COLUMN IF EXISTS "priority";

-- Step 4: Drop the old unique constraint on domain
ALTER TABLE "organization_domains" DROP CONSTRAINT IF EXISTS "organization_domains_domain_key";

-- Step 5: Create new unique constraint on domain + organizationId (tenant isolation)
CREATE UNIQUE INDEX "organization_domains_domain_organizationId_key" ON "organization_domains"("domain", "organizationId");

-- Step 6: Create index on accountId for faster lookups
CREATE INDEX "organization_domains_accountId_idx" ON "organization_domains"("accountId");

-- Step 7: Add foreign key constraint for accountId
ALTER TABLE "organization_domains" ADD CONSTRAINT "organization_domains_accountId_fkey" 
  FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Note: Existing domain mappings will have accountId = NULL
-- Admin should manually assign accounts to existing domain mappings
