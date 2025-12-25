/*
  Warnings:

  - You are about to drop the column `userRoleId` on the `user_organizations` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."user_organizations" DROP CONSTRAINT "user_organizations_userRoleId_fkey";

-- AlterTable
ALTER TABLE "user_organizations" DROP COLUMN "userRoleId",
ADD COLUMN     "role" "UserRoleType" NOT NULL DEFAULT 'VIEWER';
