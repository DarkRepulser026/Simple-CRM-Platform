-- AlterTable
ALTER TABLE "user_organizations" ADD COLUMN     "userRoleId" TEXT;

-- AddForeignKey
ALTER TABLE "user_organizations" ADD CONSTRAINT "user_organizations_userRoleId_fkey" FOREIGN KEY ("userRoleId") REFERENCES "user_roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
