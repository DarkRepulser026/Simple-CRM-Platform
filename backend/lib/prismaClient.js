import { PrismaClient } from '@prisma/client';
import "dotenv/config";

// Create a single PrismaClient instance for the whole app. When using development
// mode, attach it to the global object to avoid creating multiple instances
// when the server is hot-reloaded.
let prisma;
if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient();
} else {
  if (!globalThis.__prisma) {
    globalThis.__prisma = new PrismaClient();
  }
  prisma = globalThis.__prisma;
}

export default prisma;
