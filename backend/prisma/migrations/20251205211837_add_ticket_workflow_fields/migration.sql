-- CreateEnum
CREATE TYPE "TicketChannel" AS ENUM ('EMAIL', 'WEB', 'PHONE', 'PORTAL');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "TicketPriority" ADD VALUE 'MEDIUM';
ALTER TYPE "TicketPriority" ADD VALUE 'CRITICAL';

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "TicketStatus" ADD VALUE 'PENDING';
ALTER TYPE "TicketStatus" ADD VALUE 'CANCELLED';

-- AlterTable
ALTER TABLE "tickets" ADD COLUMN     "channel" "TicketChannel" NOT NULL DEFAULT 'WEB',
ADD COLUMN     "dueDate" TIMESTAMP(3),
ADD COLUMN     "resolutionNote" TEXT,
ADD COLUMN     "satisfactionFeedback" TEXT,
ADD COLUMN     "satisfactionRating" INTEGER,
ADD COLUMN     "slaExpiresAt" TIMESTAMP(3);
