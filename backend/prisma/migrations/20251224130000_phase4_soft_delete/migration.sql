/*
  Phase 4: Soft Delete Migration
  Add deletedAt timestamps to soft-delete entities
  These entities will be archived instead of hard-deleted
*/

-- Add soft delete fields to Lead
ALTER TABLE "leads" 
ADD COLUMN "deletedAt" TIMESTAMP(3);

-- Add soft delete fields to Account  
ALTER TABLE "accounts"
ADD COLUMN "deletedAt" TIMESTAMP(3);

-- Add soft delete fields to Contact
ALTER TABLE "contacts"
ADD COLUMN "deletedAt" TIMESTAMP(3);

-- Add soft delete fields to Task
ALTER TABLE "tasks"
ADD COLUMN "deletedAt" TIMESTAMP(3),
ADD COLUMN "cancelledAt" TIMESTAMP(3),
ADD COLUMN "cancellationReason" TEXT;

-- Create indexes for soft delete queries (WHERE deletedAt IS NULL)
CREATE INDEX "idx_leads_deleted_status" ON "leads"("organizationId", "deletedAt", "status");
CREATE INDEX "idx_accounts_deleted_type" ON "accounts"("organizationId", "deletedAt", "type");
CREATE INDEX "idx_contacts_deleted_account" ON "contacts"("organizationId", "accountId", "deletedAt");
CREATE INDEX "idx_tasks_deleted_status" ON "tasks"("organizationId", "deletedAt", "status");

-- Create index for activity log audit trail
CREATE INDEX "idx_activity_log_entity_created" ON "activity_logs"("entityType", "entityId", "createdAt" DESC);
