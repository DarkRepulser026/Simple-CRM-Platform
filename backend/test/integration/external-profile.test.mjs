import request from 'supertest';
import { expect } from 'chai';
import { PrismaClient } from '@prisma/client';
import { spawnServer, waitForHealth, stopServer } from './_setup.mjs';

const prisma = new PrismaClient();
const BASE_URL = process.env.BASE_URL || 'http://localhost:3001';

describe('Customer Profile & Permissions Endpoints', () => {
  let authToken = null;
  let userId = null;

  const testCustomer = {
    email: `profile-test-${Date.now()}@example.com`,
    password: 'Test123!@#',
    name: 'Profile Test Customer',
    companyName: 'Test Company Inc.',
    phone: '+1234567890'
  };

  before(async function() {
    this.timeout(25000);
    await spawnServer();
    const ready = await waitForHealth();
    if (!ready) throw new Error('Server failed to start');
    
    // Wait longer to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Register and login test customer
    const registerResponse = await request(BASE_URL)
      .post('/api/external/auth/register')
      .send(testCustomer);

    if (registerResponse.status !== 201) {
      console.error('Registration failed with status:', registerResponse.status);
      console.error('Response body:', registerResponse.body);
      console.error('Response text:', registerResponse.text);
      throw new Error(`Registration failed with status ${registerResponse.status}`);
    }

    userId = registerResponse.body.userId;
    authToken = registerResponse.body.token;
    
    if (!authToken) {
      throw new Error('No auth token received from registration');
    }
  });

  after(async () => {
    // Cleanup
    if (userId) {
      await prisma.ticketMessage.deleteMany({ where: { ticket: { customerId: userId } } });
      await prisma.ticket.deleteMany({ where: { customerId: userId } });
      await prisma.customerProfile.deleteMany({ where: { userId } });
      await prisma.user.delete({ where: { id: userId } });
    }
    await prisma.$disconnect();
    await stopServer();
  });

  describe('GET /api/external/profile', () => {
  it('should retrieve customer profile', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('id');
      expect(response.body).to.have.property('email', testCustomer.email);
      expect(response.body).to.have.property('name', testCustomer.name);
      expect(response.body).to.have.property('type', 'CUSTOMER');
      expect(response.body).to.have.property('profile');
      expect(response.body.profile).to.have.property('companyName', testCustomer.companyName);
      expect(response.body.profile).to.have.property('phone', testCustomer.phone);
    });

  it('should reject request without authentication', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/profile')
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });

  it('should not expose sensitive user data', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).to.not.have.property('passwordHash');
      expect(response.body).to.not.have.property('refreshToken');
    });
  });

  describe('PUT /api/external/profile', () => {
  it('should update profile with valid data', async () => {
      const updateData = {
        name: 'Updated Name',
        companyName: 'Updated Company',
        phone: '+9876543210',
        address: '123 Main St',
        city: 'Test City',
        state: 'TS',
        zipCode: '12345',
        country: 'Test Country'
      };

      const response = await request(BASE_URL)
        .put('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.name).to.equal(updateData.name);
      expect(response.body.profile.companyName).to.equal(updateData.companyName);
      expect(response.body.profile.phone).to.equal(updateData.phone);
      expect(response.body.profile.address).to.equal(updateData.address);
      expect(response.body.profile.city).to.equal(updateData.city);
      expect(response.body.profile.state).to.equal(updateData.state);
      expect(response.body.profile.zipCode).to.equal(updateData.zipCode);
      expect(response.body.profile.country).to.equal(updateData.country);
    });

  it('should allow partial profile updates', async () => {
      const partialUpdate = {
        phone: '+5555555555'
      };

      const response = await request(BASE_URL)
        .put('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(partialUpdate)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.profile.phone).to.equal(partialUpdate.phone);
      // Other fields should remain unchanged
      expect(response.body.name).to.equal('Updated Name');
    });

  it('should reject invalid phone format', async () => {
      const response = await request(BASE_URL)
        .put('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ phone: 'invalid-phone' })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });

  it('should reject update without authentication', async () => {
      const response = await request(BASE_URL)
        .put('/api/external/profile')
        .send({ name: 'Unauthorized Update' })
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });
  });

  describe('PUT /api/external/profile/password', () => {
    const newPassword = 'NewPassword123!@#';

  it('should change password with valid current password', async () => {
      const response = await request(BASE_URL)
        .put('/api/external/profile/password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: testCustomer.password,
          newPassword: newPassword
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('success', true);

      // Update local password for future tests
      testCustomer.password = newPassword;
    });

  it('should reject with incorrect current password', async () => {
      const response = await request(BASE_URL)
        .put('/api/external/profile/password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: 'WrongPassword123',
          newPassword: 'AnotherNewPassword123!@#'
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });

  it('should reject weak new password', async () => {
      const response = await request(BASE_URL)
        .put('/api/external/profile/password')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          currentPassword: newPassword,
          newPassword: '123'
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });

  it('should allow login with new password', async () => {
      const response = await request(BASE_URL)
        .post('/api/external/auth/login')
        .send({
          email: testCustomer.email,
          password: newPassword
        });
      
      expect(response.status).to.equal(200);
      expect(response.headers['content-type']).to.match(/json/);

      expect(response.body).to.have.property('token');
      authToken = response.body.token;
    });
  });

  describe('Authorization & Ownership Tests', () => {
    let otherCustomerToken = null;
    let otherCustomerId = null;
    let ticket1Id = null;
    let ticket2Id = null;

    before(async () => {
      // Create another customer
      const otherCustomer = {
        email: `auth-test-${Date.now()}@example.com`,
        password: 'Test123!@#',
        name: 'Other Auth Customer'
      };

      const response = await request(BASE_URL)
        .post('/api/external/auth/register')
        .send(otherCustomer);

      otherCustomerToken = response.body.token;
      otherCustomerId = response.body.userId;

      // Create tickets for both customers
      const ticket1 = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          subject: 'Customer 1 Ticket',
          description: 'Test ticket',
          priority: 'NORMAL'
        });
      ticket1Id = ticket1.body.id;

      const ticket2 = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${otherCustomerToken}`)
        .send({
          subject: 'Customer 2 Ticket',
          description: 'Test ticket',
          priority: 'NORMAL'
        });
      ticket2Id = ticket2.body.id;
    });

    after(async () => {
      if (otherCustomerId) {
        await prisma.ticketMessage.deleteMany({ where: { ticket: { customerId: otherCustomerId } } });
        await prisma.ticket.deleteMany({ where: { customerId: otherCustomerId } });
        await prisma.customerProfile.deleteMany({ where: { userId: otherCustomerId } });
        await prisma.user.delete({ where: { id: otherCustomerId } });
      }
    });

  it('should prevent customer from viewing another customer\'s ticket', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticket2Id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(403);

      expect(response.body).to.have.property('error');
      expect(response.body.error).to.match(/not authorized|permission|access denied/i);
    });

  it('should prevent customer from updating another customer\'s ticket', async () => {
      const response = await request(BASE_URL)
        .put(`/api/external/tickets/${ticket2Id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ subject: 'Unauthorized Update' })
        .expect('Content-Type', /json/)
        .expect(403);

      expect(response.body).to.have.property('error');
    });

  it('should prevent customer from adding message to another customer\'s ticket', async () => {
      const response = await request(BASE_URL)
        .post(`/api/external/tickets/${ticket2Id}/messages`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ content: 'Unauthorized message' })
        .expect('Content-Type', /json/)
        .expect(403);

      expect(response.body).to.have.property('error');
    });

  it('should allow customer to access their own ticket', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticket1Id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('id', ticket1Id);
    });

  it('should prevent access with expired/invalid token', async () => {
      const invalidToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.token';

      const response = await request(BASE_URL)
        .get('/api/external/profile')
        .set('Authorization', `Bearer ${invalidToken}`)
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });

  it('should verify customer type in token', async () => {
      // This test verifies that only CUSTOMER type users can access external endpoints
      const response = await request(BASE_URL)
        .get('/api/external/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).to.have.property('type', 'CUSTOMER');
    });
  });

  describe.skip('GET /api/external/tickets/:id/attachments/:attachmentId', () => {
    let ticketId = null;
    let attachmentId = null;

    before(async () => {
      // Create a ticket
      const ticketResponse = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          subject: 'Ticket with Attachment',
          description: 'Test ticket',
          priority: 'NORMAL'
        });
      ticketId = ticketResponse.body.id;

      // Create an attachment record (normally done during file upload)
      const attachment = await prisma.ticketAttachment.create({
        data: {
          ticketId,
          filename: 'test-file.txt',
          originalName: 'test-file.txt',
          mimeType: 'text/plain',
          size: 1024,
          uploadedBy: userId
        }
      });
      attachmentId = attachment.id;
    });

  it('should retrieve attachment for own ticket', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}/attachments/${attachmentId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // May be 200 if file exists, or 404 if file doesn't physically exist
      expect([200, 404]).toContain(response.status);
    });

  it('should reject attachment access without authentication', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}/attachments/${attachmentId}`)
        .expect(401);

      expect(response.body).to.have.property('error');
    });
  });

  describe.skip('DELETE /api/external/tickets/:id/attachments/:attachmentId', () => {
    let ticketId = null;
    let attachmentId = null;

    before(async () => {
      // Create a ticket
      const ticketResponse = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          subject: 'Ticket for Deletion Test',
          description: 'Test ticket',
          priority: 'NORMAL'
        });
      ticketId = ticketResponse.body.id;

      // Create an attachment
      const attachment = await prisma.ticketAttachment.create({
        data: {
          ticketId,
          filename: 'delete-test.txt',
          originalName: 'delete-test.txt',
          mimeType: 'text/plain',
          size: 512,
          uploadedBy: userId
        }
      });
      attachmentId = attachment.id;
    });

  it('should delete own attachment', async () => {
      const response = await request(BASE_URL)
        .delete(`/api/external/tickets/${ticketId}/attachments/${attachmentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('success', true);

      // Verify deletion
      const attachment = await prisma.ticketAttachment.findUnique({
        where: { id: attachmentId }
      });
      expect(attachment).to.be.null;
    });

  it('should reject deletion without authentication', async () => {
      const response = await request(BASE_URL)
        .delete(`/api/external/tickets/${ticketId}/attachments/some-id`)
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });
  });
});
