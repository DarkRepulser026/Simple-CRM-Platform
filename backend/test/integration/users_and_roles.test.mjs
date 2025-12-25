import { spawnServer, waitForHealth, stopServer, createAdminUserAndOrg, createOrganization } from './_setup.mjs';
import fetch from 'node-fetch';
import { expect } from 'chai';

const BASE_URL = `http://localhost:${process.env.PORT || 3001}/api`;
let adminToken;
let adminUserId;
let orgId;

describe('Users, Roles, Invitations API - Integration tests', function() {
  this.timeout(20000);
  before(async () => {
    await spawnServer();
    const ok = await waitForHealth(20000);
    if (!ok) throw new Error('Server unavailable');
    const auth = await createAdminUserAndOrg();
    adminToken = auth.adminToken; adminUserId = auth.adminUserId;
    const org = await createOrganization(adminToken, `Roles Org ${adminUserId}`);
    orgId = org.id;
  });

  after(async () => {
    try { if (orgId) await fetch(`${BASE_URL}/admin/organizations/${orgId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${adminToken}` } }); } catch (e) {}
    await stopServer();
  });

  it('should create, list and revoke an invitation', async () => {
    const email = `invitee+${Date.now()}@example.com`;
    const res = await fetch(`${BASE_URL}/auth/invites/organizations/${orgId}/invite`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ email, role: 'AGENT' })
    });
    expect(res.ok).to.be.true;
    const listRes = await fetch(`${BASE_URL}/auth/invites/organizations/${orgId}/invitations`, { headers: { 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId } });
    expect(listRes.ok).to.be.true;
    const invites = await listRes.json();
    const found = invites.find(i => i.email === email);
    expect(found).to.exist;
    // Revoke
    const revokeRes = await fetch(`${BASE_URL}/auth/invites/${found.id}/revoke`, { method: 'POST', headers: { 'Authorization': `Bearer ${adminToken}` } });
    expect(revokeRes.ok).to.be.true;
  });

  it('should create, update and delete a role', async () => {
    // Create role
    const createRes = await fetch(`${BASE_URL}/admin/roles`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ name: 'CustomRole', roleType: 'AGENT', permissions: ['VIEW_TICKETS'], description: 'Test role' })
    });
    expect(createRes.ok).to.be.true;
    const created = await createRes.json();
    expect(created.id).to.exist;

    // Update role
    const updateRes = await fetch(`${BASE_URL}/admin/roles/${created.id}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ name: 'CustomRole2', permissions: ['VIEW_TICKETS','CREATE_TICKETS'] })
    });
    expect(updateRes.ok).to.be.true;
    const updated = await updateRes.json();
    expect(updated.name).to.equal('CustomRole2');

    // Delete role
    const delRes = await fetch(`${BASE_URL}/admin/roles/${created.id}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId } });
    expect(delRes.ok).to.be.true;
  });

  it('should create, update role and delete a user', async () => {
    // Create user
    const email = `usercreate+${Date.now()}@example.com`;
    const createUserRes = await fetch(`${BASE_URL}/admin/users`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ email, name: 'Created User', role: 'AGENT' })
    });
    expect(createUserRes.ok).to.be.true;
    const created = await createUserRes.json();
    expect(created.id).to.exist;

    // Update user role via org role endpoint
    const roleUpdateRes = await fetch(`${BASE_URL}/admin/organizations/${orgId}/users/${created.id}/role`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ role: 'MANAGER' })
    });
    expect(roleUpdateRes.ok).to.be.true;

    // Delete user
    const delRes = await fetch(`${BASE_URL}/admin/users/${created.id}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId } });
    expect(delRes.ok).to.be.true;
  });
});
