import prisma from './lib/prismaClient.js';
import jwt from 'jsonwebtoken';

async function generateToken() {
  try {
    const email = 'minecraftthanhloi@gmail.com';
    
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        organizations: {
          include: {
            organization: true
          }
        }
      }
    });

    if (!user) {
      console.log(`User not found: ${email}`);
      return;
    }

    const org = user.organizations[0];
    
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: org.role,
        organizationId: org.organizationId,
        type: user.type,
        tokenVersion: user.tokenVersion
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    console.log('\n=== USER TOKEN ===');
    console.log('User:', user.name);
    console.log('Email:', user.email);
    console.log('Organization:', org.organization.name);
    console.log('Role:', org.role);
    console.log('Token Version:', user.tokenVersion);
    console.log('\nToken:');
    console.log(token);
    console.log('\n=== TEST COMMAND ===');
    console.log(`curl -H "Authorization: Bearer ${token}" http://localhost:3001/api/crm/dashboard/my-work`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

generateToken();
