-- CreateTable OrganizationDomain - Domain auto-assignment rules
CREATE TABLE "organization_domains" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "autoAssign" BOOLEAN NOT NULL DEFAULT true,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "organization_domains_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "organization_domains_domain_key" ON "organization_domains"("domain");

-- CreateIndex
CREATE INDEX "organization_domains_domain_idx" ON "organization_domains"("domain");

-- CreateIndex
CREATE INDEX "organization_domains_organizationId_idx" ON "organization_domains"("organizationId");

-- AddForeignKey
ALTER TABLE "organization_domains" 
ADD CONSTRAINT "organization_domains_organizationId_fkey" 
FOREIGN KEY ("organizationId") REFERENCES "organizations"("id") 
ON DELETE CASCADE ON UPDATE CASCADE;

-- Migrate existing Organization.domain to OrganizationDomain table
INSERT INTO "organization_domains" ("id", "organizationId", "domain", "isActive", "autoAssign", "priority", "createdAt", "updatedAt")
SELECT 
    gen_random_uuid()::text,
    "id",
    "domain",
    true,
    true,
    0,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "organizations"
WHERE "domain" IS NOT NULL 
AND "domain" != ''
AND "isActive" = true;
