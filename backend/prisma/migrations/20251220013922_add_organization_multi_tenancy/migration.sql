-- AlterTable
ALTER TABLE "customer_profiles" ADD COLUMN     "assignedAt" TIMESTAMP(3),
ADD COLUMN     "assignedBy" TEXT,
ADD COLUMN     "organizationId" TEXT;

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "resolvedAt" TIMESTAMP(3),
ADD COLUMN     "respondedAt" TIMESTAMP(3),
ADD COLUMN     "slaDeadline" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "customer_profiles_organizationId_idx" ON "customer_profiles"("organizationId");

-- CreateIndex
CREATE INDEX "customer_profiles_companyName_idx" ON "customer_profiles"("companyName");

-- CreateIndex
CREATE INDEX "tickets_organizationId_idx" ON "tickets"("organizationId");

-- CreateIndex
CREATE INDEX "tickets_customerId_idx" ON "tickets"("customerId");

-- CreateIndex
CREATE INDEX "tickets_status_idx" ON "tickets"("status");

-- AddForeignKey
ALTER TABLE "tickets" ADD CONSTRAINT "tickets_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_profiles" ADD CONSTRAINT "customer_profiles_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "organizations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
