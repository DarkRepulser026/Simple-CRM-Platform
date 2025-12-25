-- Phase 3: Database Constraints
-- Add SQL-level constraints to enforce business rules at database level
-- This prevents invalid data at the database layer (defense in depth)

-- 1. XOR Constraint on Task Parent (exactly one of contactId, accountId, leadId)
-- Use a CHECK constraint to ensure only one parent is set
ALTER TABLE tasks 
ADD CONSTRAINT task_xor_parent_check 
CHECK (
  (CASE WHEN "contactId" IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN "accountId" IS NOT NULL THEN 1 ELSE 0 END +
   CASE WHEN "leadId" IS NOT NULL THEN 1 ELSE 0 END) = 1
);

-- 2. Unique constraint on (organizationId, domain) for accounts
-- Prevents duplicate domains within an organization
ALTER TABLE accounts 
ADD CONSTRAINT account_org_domain_unique 
UNIQUE ("organizationId", "domain") 
WHERE "domain" IS NOT NULL;

-- 3. Lead status must be CONVERTED if convertedAccountId is set
ALTER TABLE leads 
ADD CONSTRAINT lead_converted_status_check 
CHECK (
  ("convertedAccountId" IS NULL AND "status" != 'CONVERTED') OR
  ("convertedAccountId" IS NOT NULL AND "status" = 'CONVERTED')
);

-- 4. Indexes for performance (used by soft delete queries in future phases)
CREATE INDEX idx_leads_organization_status ON leads("organizationId", "status");
CREATE INDEX idx_tasks_organization_status ON tasks("organizationId", "status");
CREATE INDEX idx_accounts_organization_domain ON accounts("organizationId", "domain");
CREATE INDEX idx_contacts_organization_account ON contacts("organizationId", "accountId");
CREATE INDEX idx_tickets_organization_status ON tickets("organizationId", "status");

-- 5. Prevent modification of converted leads (application-enforced, documented here)
-- Note: This is enforced via middleware in application code
-- Database trigger could be added if needed:
-- CREATE TRIGGER prevent_converted_lead_update
-- BEFORE UPDATE ON leads
-- FOR EACH ROW
-- WHEN (OLD.status = 'CONVERTED' AND NEW.status != 'CONVERTED')
-- EXECUTE FUNCTION raise_converted_lead_error();
