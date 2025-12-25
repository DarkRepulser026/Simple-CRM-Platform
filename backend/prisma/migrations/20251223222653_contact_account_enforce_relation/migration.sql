/*
  Warnings:

  - Made the column `accountId` on table `contacts` required. This migration will fail if there are existing `NULL` values in that column.
  - A unique constraint covering the columns `[email,accountId]` on the table `contacts` will be added. If there are existing duplicate values, this will fail.

*/

-- Step 1: Handle existing NULL accountIds (if any) - set them to first account in their org
-- Find contacts with NULL accountId and assign them to an existing account
UPDATE "contacts" c 
SET "accountId" = (
  SELECT a.id 
  FROM "accounts" a 
  WHERE a."organizationId" = c."organizationId" 
  LIMIT 1
)
WHERE c."accountId" IS NULL 
  AND EXISTS (
    SELECT 1 FROM "accounts" a 
    WHERE a."organizationId" = c."organizationId"
  );

-- If there are still NULL accountIds without any accounts in the org, we need to handle them
-- Create a default account for each organization that has orphaned contacts
INSERT INTO "accounts" (id, name, "organizationId", type, "createdAt", "updatedAt")
SELECT 
  'default_' || c."organizationId", 
  'Default Account', 
  c."organizationId",
  'Default',
  NOW(),
  NOW()
FROM "contacts" c
WHERE c."accountId" IS NULL
GROUP BY c."organizationId"
ON CONFLICT DO NOTHING;

-- Now assign remaining orphaned contacts to these default accounts
UPDATE "contacts" c 
SET "accountId" = 'default_' || c."organizationId"
WHERE c."accountId" IS NULL;

-- Step 2: Add missing columns to accounts (if they don't exist)
-- These may already exist from previous failed migration, so we use IF NOT EXISTS pattern
DO $$ BEGIN
  ALTER TABLE "accounts" ADD COLUMN "domain" TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "accounts" ADD COLUMN "industry" TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "accounts" ADD COLUMN "size" TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "accounts" ADD COLUMN "ownerId" TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Step 3: Drop existing constraint if it exists with wrong behavior
DO $$ BEGIN
  ALTER TABLE "contacts" DROP CONSTRAINT IF EXISTS "contacts_accountId_fkey";
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- Step 4: Make accountId NOT NULL and add proper foreign key
ALTER TABLE "contacts" ALTER COLUMN "accountId" SET NOT NULL;

-- Add the proper foreign key with CASCADE delete
ALTER TABLE "contacts" 
ADD CONSTRAINT "contacts_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Step 5: Create unique index on email + accountId (drop if exists first)
DROP INDEX IF EXISTS "contacts_email_accountId_key";
CREATE UNIQUE INDEX "contacts_email_accountId_key" ON "contacts"("email", "accountId");

-- Step 6: Handle tickets.accountId column
DO $$ BEGIN
  ALTER TABLE "tickets" ADD COLUMN "accountId" TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Drop and recreate foreign key for tickets.accountId
DO $$ BEGIN
  ALTER TABLE "tickets" DROP CONSTRAINT "tickets_accountId_fkey";
EXCEPTION WHEN OTHERS THEN NULL; END $$;

ALTER TABLE "tickets" 
ADD CONSTRAINT "tickets_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Step 7: Create index for ticket account lookups
DROP INDEX IF EXISTS "tickets_accountId_idx";
CREATE INDEX "tickets_accountId_idx" ON "tickets"("accountId");

-- Step 8: Add foreign key for account owner
DO $$ BEGIN
  ALTER TABLE "accounts" DROP CONSTRAINT "accounts_ownerId_fkey";
EXCEPTION WHEN OTHERS THEN NULL; END $$;

ALTER TABLE "accounts" 
ADD CONSTRAINT "accounts_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
