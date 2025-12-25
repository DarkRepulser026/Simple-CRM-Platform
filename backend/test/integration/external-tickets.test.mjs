import request from 'supertest';
import { expect } from 'chai';
import { PrismaClient } from '@prisma/client';
import { spawnServer, waitForHealth, stopServer } from './_setup.mjs';

const prisma = new PrismaClient();
const BASE_URL = process.env.BASE_URL || 'http://localhost:3001';

describe('Customer Ticket Endpoints', () => {
  let authToken = null;
  let userId = null;
  let ticketId = null;
  let messageId = null;

  const testCustomer = {
    email: `ticket-test-${Date.now()}@example.com`,
    password: 'Test123!@#',
    name: 'Ticket Test Customer',
    companyName: 'Test Tickets Inc.'
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
      console.error('Registration failed:', registerResponse.body);
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

  describe('POST /api/external/tickets', () => {
  it('should create a new ticket with valid data', async () => {
      const ticketData = {
        subject: 'Test Ticket Subject',
        description: 'This is a detailed description of the test ticket.',
        priority: 'NORMAL',
        category: 'TECHNICAL'
      };

      const response = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send(ticketData)
        .expect('Content-Type', /json/)
        .expect(201);

      expect(response.body).to.have.property('id');
      expect(response.body).to.have.property('number');
      expect(response.body.subject).to.equal(ticketData.subject);
      expect(response.body.description).to.equal(ticketData.description);
      expect(response.body.priority).to.equal(ticketData.priority);
      expect(response.body.status).to.equal('OPEN');
      expect(response.body.customerId).to.equal(userId);

      ticketId = response.body.id;
    });

  it('should reject ticket creation without authentication', async () => {
      const response = await request(BASE_URL)
        .post('/api/external/tickets')
        .send({
          subject: 'Unauthorized Ticket',
          description: 'This should fail',
          priority: 'NORMAL'
        })
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });

  it('should reject ticket with missing required fields', async () => {
      const response = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ subject: 'Incomplete Ticket' })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });

  it('should reject ticket with invalid priority', async () => {
      const response = await request(BASE_URL)
        .post('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          subject: 'Invalid Priority',
          description: 'Test description',
          priority: 'INVALID_PRIORITY'
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });
  });

  describe('GET /api/external/tickets', () => {
  it('should retrieve customer tickets', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('tickets');
      expect(response.body).to.have.property('pagination');
      expect(response.body.tickets).to.be.an('array');
      expect(response.body.tickets).to.have.length.greaterThan(0);
      
      // Verify all tickets belong to this customer
      response.body.tickets.forEach(ticket => {
        expect(ticket.customerId).to.equal(userId);
      });
    });

  it('should filter tickets by status', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets?status=OPEN')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.tickets).to.exist;
      response.body.tickets.forEach(ticket => {
        expect(ticket.status).to.equal('OPEN');
      });
    });

  it('should support pagination', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets?page=1&limit=10')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.pagination).to.have.property('page', 1);
      expect(response.body.pagination).to.have.property('limit', 10);
      expect(response.body.tickets.length).to.be.at.most(10);
    });

  it('should reject request without authentication', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets')
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });
  });

  describe('GET /api/external/tickets/:id', () => {
  it('should retrieve ticket details', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('id', ticketId);
      expect(response.body).to.have.property('subject');
      expect(response.body).to.have.property('description');
      expect(response.body).to.have.property('messages');
      expect(response.body.messages).to.be.an('array');
    });

  it('should reject access to non-existent ticket', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets/nonexistent-id')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(404);

      expect(response.body).to.have.property('error');
    });
  });

  describe('PUT /api/external/tickets/:id', () => {
  it('should update ticket with valid data', async () => {
      const updateData = {
        subject: 'Updated Ticket Subject',
        description: 'Updated description',
        priority: 'HIGH'
      };

      const response = await request(BASE_URL)
        .put(`/api/external/tickets/${ticketId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.subject).to.equal(updateData.subject);
      expect(response.body.description).to.equal(updateData.description);
      expect(response.body.priority).to.equal(updateData.priority);
    });

  it('should reject update without authentication', async () => {
      const response = await request(BASE_URL)
        .put(`/api/external/tickets/${ticketId}`)
        .send({ subject: 'Unauthorized Update' })
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body).to.have.property('error');
    });
  });

  describe('POST /api/external/tickets/:id/messages', () => {
  it('should add message to ticket', async () => {
      const messageData = {
        content: 'This is a test message from the customer.'
      };

      const response = await request(BASE_URL)
        .post(`/api/external/tickets/${ticketId}/messages`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(messageData)
        .expect('Content-Type', /json/)
        .expect(201);

      expect(response.body).to.have.property('id');
      expect(response.body.content).to.equal(messageData.content);
      expect(response.body.ticketId).to.equal(ticketId);
      expect(response.body.isFromCustomer).to.equal(true);
      expect(response.body.isInternal).to.equal(false);

      messageId = response.body.id;
    });

  it('should reject message without content', async () => {
      const response = await request(BASE_URL)
        .post(`/api/external/tickets/${ticketId}/messages`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body).to.have.property('error');
    });
  });

  describe('GET /api/external/tickets/:id/messages', () => {
  it('should retrieve ticket messages', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}/messages`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('messages');
      expect(response.body.messages).to.be.an('array');
      expect(response.body.messages).to.have.length.greaterThan(0);
      
      // Verify internal messages are not included
      response.body.messages.forEach(msg => {
        expect(msg.isInternal).to.equal(false);
      });
    });

  it('should support pagination for messages', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}/messages?page=1`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).to.have.property('pagination');
    });
  });

  describe('PUT /api/external/tickets/:id/messages/:msgId', () => {
  it('should update own message within time window', async () => {
      const updateData = {
        content: 'Updated message content'
      };

      const response = await request(BASE_URL)
        .put(`/api/external/tickets/${ticketId}/messages/${messageId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.content).to.equal(updateData.content);
    });
  });

  describe('Data Isolation', () => {
    let otherCustomerToken = null;
    let otherCustomerId = null;

    before(async () => {
      // Create another customer
      const otherCustomer = {
        email: `other-customer-${Date.now()}@example.com`,
        password: 'Test123!@#',
        name: 'Other Customer'
      };

      const response = await request(BASE_URL)
        .post('/api/external/auth/register')
        .send(otherCustomer);

      otherCustomerToken = response.body.token;
      otherCustomerId = response.body.userId;
    });

    after(async () => {
      if (otherCustomerId) {
        await prisma.customerProfile.deleteMany({ where: { userId: otherCustomerId } });
        await prisma.user.delete({ where: { id: otherCustomerId } });
      }
    });

  it('should not allow customer to access another customer\'s ticket', async () => {
      const response = await request(BASE_URL)
        .get(`/api/external/tickets/${ticketId}`)
        .set('Authorization', `Bearer ${otherCustomerToken}`)
        .expect('Content-Type', /json/)
        .expect(403);

      expect(response.body).to.have.property('error');
    });

  it('should not show other customers\' tickets in list', async () => {
      const response = await request(BASE_URL)
        .get('/api/external/tickets')
        .set('Authorization', `Bearer ${otherCustomerToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      const hasOtherTickets = response.body.tickets.some(t => t.id === ticketId);
      expect(hasOtherTickets).to.equal(false);
    });
  });
});
