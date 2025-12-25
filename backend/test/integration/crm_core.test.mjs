import { expect } from 'chai';
import fetch from 'node-fetch';
import { spawnServer, stopServer, waitForHealth, createAdminUserAndOrg, createOrganization } from './_setup.mjs';

const BASE_URL = `http://localhost:${process.env.PORT || 3001}/api`;

describe('CRM Core Functionality - Contacts, Accounts, Leads', function () {
  let adminToken, adminUserId, orgId, accountId, contactId, leadId;

  before(async function () {
    this.timeout(30000);
    await spawnServer();
    const connected = await waitForHealth();
    expect(connected).to.be.true;

    const { adminToken: token, adminUserId: userId } = await createAdminUserAndOrg();
    adminToken = token;
    adminUserId = userId;

    const orgRes = await createOrganization(adminToken, 'CRM Test Org');
    orgId = orgRes.data?.id || orgRes.id;
  });

  after(async function () {
    await stopServer();
  });

  // ============================================
  // ACCOUNTS TESTS
  // ============================================

  describe('Accounts API', function () {
    it('should create an account with required fields', async function () {
      const res = await fetch(`${BASE_URL}/crm/accounts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          name: 'Acme Corp',
          domain: 'acme.com',
          industry: 'Technology',
          size: '100-500',
          ownerId: adminUserId
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(201);
      expect(json.data).to.exist;
      expect(json.data.name).to.equal('Acme Corp');
      expect(json.data.domain).to.equal('acme.com');
      expect(json.data.industry).to.equal('Technology');
      accountId = json.data.id;
    });

    it('should retrieve account by ID', async function () {
      const res = await fetch(`${BASE_URL}/crm/accounts/${accountId}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data.id).to.equal(accountId);
      expect(json.data.name).to.equal('Acme Corp');
    });

    it('should list accounts with pagination', async function () {
      const res = await fetch(`${BASE_URL}/crm/accounts?page=1&limit=10`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data).to.be.an('array');
      expect(json.total).to.be.a('number');
      expect(json.page).to.equal(1);
    });

    it('should update an account', async function () {
      const res = await fetch(`${BASE_URL}/crm/accounts/${accountId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          name: 'Acme Corporation',
          size: '500-1000'
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data.name).to.equal('Acme Corporation');
      expect(json.data.size).to.equal('500-1000');
    });
  });

  // ============================================
  // CONTACTS TESTS
  // ============================================

  describe('Contacts API', function () {
    it('should create a contact with required accountId', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          firstName: 'John',
          lastName: 'Smith',
          email: 'john.smith@acme.com',
          phone: '555-1234',
          title: 'Sales Director',
          accountId: accountId
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(201);
      expect(json.data).to.exist;
      expect(json.data.firstName).to.equal('John');
      expect(json.data.email).to.equal('john.smith@acme.com');
      expect(json.data.accountId).to.equal(accountId);
      contactId = json.data.id;
    });

    it('should FAIL to create a contact without accountId', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane.doe@test.com',
          phone: '555-5678',
          title: 'Manager'
          // NOTE: NO accountId
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(400);
      expect(json.error || json.message).to.exist;
    });

    it('should retrieve contact by ID with account info', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data.id).to.equal(contactId);
      expect(json.data.accountId).to.equal(accountId);
      expect(json.data.firstName).to.equal('John');
    });

    it('should list contacts by account ID', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts?accountId=${accountId}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data).to.be.an('array');
      expect(json.data.length).to.be.at.least(1);
      expect(json.data[0].accountId).to.equal(accountId);
    });

    it('should update a contact', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          title: 'VP of Sales'
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data.title).to.equal('VP of Sales');
    });

    it('should include activity log in contact detail', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}?include=activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.activities).to.be.an('array');
      // Should have CREATED activity from contact creation
      const createdActivity = json.activities.find(a => a.action === 'CREATED');
      expect(createdActivity).to.exist;
    });
  });

  // ============================================
  // ACTIVITY LOGS TESTS
  // ============================================

  describe('Activity Logs API', function () {
    it('should retrieve contact activities', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}/activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data).to.be.an('array');
      expect(json.data.length).to.be.at.least(2); // CREATED + UPDATE
      
      // Check activity structure
      const activity = json.data[0];
      expect(activity.entityId).to.equal(contactId);
      expect(activity.entityType).to.equal('CONTACT');
      expect(activity.action).to.be.oneOf(['CREATED', 'UPDATED']);
      expect(activity.user).to.exist;
      expect(activity.user.name).to.exist;
      expect(activity.timestamp).to.exist;
    });

    it('should include metadata for UPDATED activities', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}/activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      const updateActivity = json.data.find(a => a.action === 'UPDATED');
      
      if (updateActivity) {
        expect(updateActivity.metadata).to.exist;
        expect(updateActivity.metadata.changes).to.exist;
        // Should show title change: Manager -> VP of Sales
        expect(updateActivity.metadata.changes.title).to.exist;
        expect(updateActivity.metadata.changes.title.oldValue).to.equal('Sales Director');
        expect(updateActivity.metadata.changes.title.newValue).to.equal('VP of Sales');
      }
    });

    it('should retrieve account activities', async function () {
      const res = await fetch(`${BASE_URL}/crm/accounts/${accountId}/activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data).to.be.an('array');
      expect(json.data[0].entityType).to.equal('ACCOUNT');
    });

    it('should support pagination on activity logs', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts/${contactId}/activities?page=1&limit=5`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.page).to.equal(1);
      expect(json.limit).to.equal(5);
      expect(json.total).to.be.a('number');
    });
  });

  // ============================================
  // LEADS TESTS
  // ============================================

  describe('Leads API', function () {
    it('should create a lead', async function () {
      const res = await fetch(`${BASE_URL}/crm/leads`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          name: 'Sarah Johnson',
          email: 'sarah@prospect.com',
          phone: '555-9999',
          company: 'Prospect Inc',
          source: 'Website'
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(201);
      expect(json.data.name).to.equal('Sarah Johnson');
      expect(json.data.isConverted).to.equal(false);
      leadId = json.data.id;
    });

    it('should convert lead to contact and account', async function () {
      const res = await fetch(`${BASE_URL}/crm/leads/${leadId}/convert`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          accountName: 'Prospect Inc',
          accountDomain: 'prospect-inc.com'
        })
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data).to.exist;
      expect(json.data.account).to.exist;
      expect(json.data.contact).to.exist;
      expect(json.data.account.name).to.equal('Prospect Inc');
      expect(json.data.contact.email).to.equal('sarah@prospect.com');
    });

    it('should mark lead as converted after conversion', async function () {
      const res = await fetch(`${BASE_URL}/crm/leads/${leadId}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      expect(json.data.isConverted).to.equal(true);
      expect(json.data.convertedContactId).to.exist;
      expect(json.data.convertedAccountId).to.exist;
    });

    it('should log CONVERTED activity on lead', async function () {
      const res = await fetch(`${BASE_URL}/crm/leads/${leadId}/activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await res.json();
      expect(res.status).to.equal(200);
      const convertedActivity = json.data.find(a => a.action === 'CONVERTED');
      expect(convertedActivity).to.exist;
    });
  });

  // ============================================
  // RULE ENFORCEMENT TESTS
  // ============================================

  describe('CRM Rule Enforcement', function () {
    it('Rule #1: Contact requires Account - enforced at API level', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          firstName: 'Orphan',
          lastName: 'Contact',
          email: 'orphan@test.com'
          // NO accountId
        })
      });

      expect(res.status).to.equal(400);
      const json = await res.json();
      expect(json.error || json.message).to.include('account');
    });

    it('Rule #1: Contact cannot have invalid Account ID', async function () {
      const res = await fetch(`${BASE_URL}/crm/contacts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          firstName: 'Invalid',
          lastName: 'Account',
          email: 'invalid@test.com',
          accountId: 'nonexistent-account-id'
        })
      });

      expect(res.status).to.equal(400);
      const json = await res.json();
      expect(json.error || json.message).to.include('account');
    });

    it('Rule #5: All CRUD operations create Activity Logs', async function () {
      // Create new contact to verify logging
      const createRes = await fetch(`${BASE_URL}/crm/contacts`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminToken}`
        },
        body: JSON.stringify({
          firstName: 'Activity',
          lastName: 'Tracker',
          email: 'activity@test.com',
          accountId: accountId
        })
      });

      const newContact = await createRes.json();
      const newContactId = newContact.data.id;

      // Get activities
      const activitiesRes = await fetch(`${BASE_URL}/crm/contacts/${newContactId}/activities`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });

      const json = await activitiesRes.json();
      expect(json.data.length).to.be.at.least(1);
      expect(json.data[0].action).to.equal('CREATED');
      expect(json.data[0].user).to.exist;
    });
  });
});
