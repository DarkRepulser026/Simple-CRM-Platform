/*
  Warnings:

  - You are about to drop the column `role` on the `user_organizations` table. All the data in the column will be lost.
  - Added the required column `userRoleId` to the `user_organizations` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "user_organizations" DROP COLUMN "role",
ADD COLUMN     "userRoleId" TEXT NOT NULL;

-- AddForeignKey
ALTER TABLE "user_organizations" ADD CONSTRAINT "user_organizations_userRoleId_fkey" FOREIGN KEY ("userRoleId") REFERENCES "user_roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
