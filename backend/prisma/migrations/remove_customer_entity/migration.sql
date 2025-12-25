-- Migration: Remove Customer Entity and Replace with Account
-- This migration safely transitions from Customer-based to Account-based system

-- Step 1: Create accountId column in tickets if not exists
-- (already exists based on schema)

-- Step 2: Migrate customer tickets to accounts
-- For each customer (type='CUSTOMER' in users), create or link to an account
-- and update their tickets

-- Create accounts for customers who have submitted tickets
INSERT INTO accounts (id, name, type, "organizationId", "createdAt", "updatedAt")
SELECT 
  gen_random_uuid(),
  COALESCE(u.name, 'Customer Account - ' || u.email),
  'CUSTOMER',
  COALESCE(cp."organizationId", (SELECT id FROM organizations WHERE name = 'Customer Portal' LIMIT 1)),
  NOW(),
  NOW()
FROM users u
LEFT JOIN customer_profiles cp ON cp."userId" = u.id
WHERE u.type = 'CUSTOMER'
  AND u.id IN (SELECT DISTINCT "customerId" FROM tickets WHERE "customerId" IS NOT NULL)
  AND NOT EXISTS (
    SELECT 1 FROM accounts a 
    WHERE a.name = COALESCE(u.name, 'Customer Account - ' || u.email)
      AND a."organizationId" = COALESCE(cp."organizationId", (SELECT id FROM organizations WHERE name = 'Customer Portal' LIMIT 1))
  );

-- Step 3: Link tickets to the newly created accounts
-- Update tickets to reference accountId based on customer
UPDATE tickets t
SET "accountId" = (
  SELECT a.id 
  FROM accounts a
  JOIN users u ON u.type = 'CUSTOMER'
  LEFT JOIN customer_profiles cp ON cp."userId" = u.id
  WHERE u.id = t."customerId"
    AND a.name = COALESCE(u.name, 'Customer Account - ' || u.email)
    AND a."organizationId" = COALESCE(cp."organizationId", (SELECT id FROM organizations WHERE name = 'Customer Portal' LIMIT 1))
  LIMIT 1
)
WHERE t."customerId" IS NOT NULL AND t."accountId" IS NULL;

-- Step 4: Remove the customerId foreign key constraint
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS "tickets_customerId_fkey";

-- Step 5: Drop the customerId column from tickets
ALTER TABLE tickets DROP COLUMN IF EXISTS "customerId";

-- Step 6: Drop the customerId index
DROP INDEX IF EXISTS "tickets_customerId_idx";

-- Step 7: Archive customer_profiles table (rename it for safety)
ALTER TABLE customer_profiles RENAME TO customer_profiles_archived;

-- Step 8: Remove customer users (optional - comment out if you want to keep customer users for historical purposes)
-- DELETE FROM users WHERE type = 'CUSTOMER';

-- Note: To fully remove customer_profiles_archived table later, run:
-- DROP TABLE customer_profiles_archived;
