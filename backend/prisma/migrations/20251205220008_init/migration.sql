/*
  Warnings:

  - The values [MEDIUM,CRITICAL] on the enum `TicketPriority` will be removed. If these variants are still used in the database, this will fail.
  - The values [PENDING,CANCELLED] on the enum `TicketStatus` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `channel` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the column `dueDate` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the column `resolutionNote` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the column `satisfactionFeedback` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the column `satisfactionRating` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the column `slaExpiresAt` on the `tickets` table. All the data in the column will be lost.
  - You are about to drop the `agent_queues` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `agent_skills` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "TicketPriority_new" AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');
ALTER TABLE "public"."tickets" ALTER COLUMN "priority" DROP DEFAULT;
ALTER TABLE "tickets" ALTER COLUMN "priority" TYPE "TicketPriority_new" USING ("priority"::text::"TicketPriority_new");
ALTER TYPE "TicketPriority" RENAME TO "TicketPriority_old";
ALTER TYPE "TicketPriority_new" RENAME TO "TicketPriority";
DROP TYPE "public"."TicketPriority_old";
ALTER TABLE "tickets" ALTER COLUMN "priority" SET DEFAULT 'NORMAL';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "TicketStatus_new" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');
ALTER TABLE "public"."tickets" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "tickets" ALTER COLUMN "status" TYPE "TicketStatus_new" USING ("status"::text::"TicketStatus_new");
ALTER TYPE "TicketStatus" RENAME TO "TicketStatus_old";
ALTER TYPE "TicketStatus_new" RENAME TO "TicketStatus";
DROP TYPE "public"."TicketStatus_old";
ALTER TABLE "tickets" ALTER COLUMN "status" SET DEFAULT 'OPEN';
COMMIT;

-- DropForeignKey
ALTER TABLE "public"."agent_queues" DROP CONSTRAINT "agent_queues_organizationId_fkey";

-- DropForeignKey
ALTER TABLE "public"."agent_queues" DROP CONSTRAINT "agent_queues_userId_fkey";

-- DropForeignKey
ALTER TABLE "public"."agent_skills" DROP CONSTRAINT "agent_skills_organizationId_fkey";

-- DropForeignKey
ALTER TABLE "public"."agent_skills" DROP CONSTRAINT "agent_skills_userId_fkey";

-- AlterTable
ALTER TABLE "tickets" DROP COLUMN "channel",
DROP COLUMN "dueDate",
DROP COLUMN "resolutionNote",
DROP COLUMN "satisfactionFeedback",
DROP COLUMN "satisfactionRating",
DROP COLUMN "slaExpiresAt";

-- DropTable
DROP TABLE "public"."agent_queues";

-- DropTable
DROP TABLE "public"."agent_skills";

-- DropEnum
DROP TYPE "public"."TicketChannel";
