import { spawnServer, waitForHealth, stopServer, createAdminUserAndOrg, createOrganization } from './_setup.js';
import fetch from 'node-fetch';
import { expect } from 'chai';

const BASE_URL = `http://localhost:${process.env.PORT || 3001}`;
let adminToken;
let adminUserId;
let orgId;

describe('Admin actions - Integration tests', function() {
  this.timeout(20000);
  before(async () => {
    await spawnServer();
    const ok = await waitForHealth(20000);
    if (!ok) throw new Error('Server unavailable');
    const auth = await createAdminUserAndOrg();
    adminToken = auth.adminToken; adminUserId = auth.adminUserId;
    const org = await createOrganization(adminToken, `Admin Org ${adminUserId}`);
    orgId = org.id;
  });
  after(async () => {
    try { if (orgId) await fetch(`${BASE_URL}/organizations/${orgId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${adminToken}` } }); } catch (e) {}
    await stopServer();
  });

  it('should impersonate a user (POST /admin/view-as/:userId)', async () => {
    // Create a new user using admin's privileges
    const email = `impuser+${Date.now()}@example.com`;
    const createUserRes = await fetch(`${BASE_URL}/users`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId },
      body: JSON.stringify({ email, name: 'Impersonation Test', role: 'AGENT' })
    });
    expect(createUserRes.ok).to.be.true;
    const created = await createUserRes.json();
    expect(created.id).to.exist;

    const resp = await fetch(`${BASE_URL}/admin/view-as/${created.id}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId }
    });
    expect(resp.ok).to.be.true;
    const json = await resp.json();
    expect(json.token).to.exist;

    // Call auth/me with impersonation token to confirm it represents the target user
    const meResp = await fetch(`${BASE_URL}/auth/me`, { headers: { 'Authorization': `Bearer ${json.token}` } });
    expect(meResp.ok).to.be.true;
    const meJson = await meResp.json();
    expect(meJson.user.id).to.equal(created.id);
  });

  it('should list activity logs (GET /activity_logs)', async () => {
    const res = await fetch(`${BASE_URL}/activity_logs`, { headers: { 'Authorization': `Bearer ${adminToken}`, 'X-Organization-ID': orgId } });
    expect(res.ok).to.be.true;
    const data = await res.json();
    expect(data).to.have.property('logs');
    expect(Array.isArray(data.logs)).to.be.true;
  });
});
