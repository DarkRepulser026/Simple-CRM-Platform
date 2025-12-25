/*
  Phase 3: Database Constraints
  Add SQL-level constraints to enforce business rules at database layer
*/

-- 1. XOR Constraint on Task Parent (exactly one of contactId, accountId, leadId)
ALTER TABLE "tasks" 
ADD CONSTRAINT "task_xor_parent_check" 
CHECK (
  (CASE WHEN "contactId" IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN "accountId" IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN "leadId" IS NOT NULL THEN 1 ELSE 0 END) = 1
);

-- 2. Unique constraint on (organizationId, domain) for accounts
-- PostgreSQL: Use partial index to handle NULL domains (NULL is not equal to NULL)
CREATE UNIQUE INDEX "account_org_domain_unique" 
ON "accounts"("organizationId", "domain") 
WHERE "domain" IS NOT NULL;

-- 3. Lead status must be CONVERTED if convertedAccountId is set
ALTER TABLE "leads" 
ADD CONSTRAINT "lead_converted_status_check" 
CHECK (
  ("convertedAccountId" IS NULL AND "status" != 'CONVERTED') OR
  ("convertedAccountId" IS NOT NULL AND "status" = 'CONVERTED')
);

-- 4. Indexes for performance (used by soft delete queries in Phase 4)
CREATE INDEX "idx_leads_organization_status" ON "leads"("organizationId", "status");
CREATE INDEX "idx_tasks_organization_status" ON "tasks"("organizationId", "status");
CREATE INDEX "idx_accounts_organization_domain" ON "accounts"("organizationId", "domain");
CREATE INDEX "idx_contacts_organization_account" ON "contacts"("organizationId", "accountId");
CREATE INDEX "idx_tickets_organization_status" ON "tickets"("organizationId", "status");
