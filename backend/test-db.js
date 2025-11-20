import prisma from './lib/prismaClient.js';

async function testConnection() {
  try {
    await prisma.$connect();
    console.log('Database connected successfully!');
  } catch (error) {
    console.error('Database connection failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();