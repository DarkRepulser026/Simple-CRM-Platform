import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3001';

// Test authentication
async function testAuth() {
  try {
    console.log('Testing authentication...');
    const response = await fetch(`${BASE_URL}/auth/google`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'test@example.com',
        name: 'Test User',
        googleId: 'test-google-id'
      })
    });

    const data = await response.json();
    console.log('Auth response:', data);

    if (data.token) {
      return data.token;
    }
  } catch (error) {
    console.error('Auth test failed:', error);
  }
  return null;
}

// Test organizations
async function testOrganizations(token) {
  try {
    console.log('Testing organizations...');
    const response = await fetch(`${BASE_URL}/organizations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        name: 'Test Organization',
        description: 'A test organization'
      })
    });

    const data = await response.json();
    console.log('Create organization response:', data);

    if (data.id) {
      return data.id;
    }
  } catch (error) {
    console.error('Organizations test failed:', error);
  }
  return null;
}

// Test dashboard
async function testDashboard(token, orgId) {
  try {
    console.log('Testing dashboard...');
    const response = await fetch(`${BASE_URL}/dashboard`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });

    const data = await response.json();
    console.log('Dashboard response:', data);
  } catch (error) {
    console.error('Dashboard test failed:', error);
  }
}

// Test accounts flow
async function testAccounts(token, orgId) {
  try {
    console.log('Testing accounts flow...');
    // Create account
    const createRes = await fetch(`${BASE_URL}/accounts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      },
      body: JSON.stringify({ name: 'ACME Corp', type: 'Customer' })
    });
    const created = await createRes.json();
    console.log('Created account:', created);
    const accId = created.id;

    // Get account
    const getRes = await fetch(`${BASE_URL}/accounts/${accId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });
    const loaded = await getRes.json();
    console.log('Loaded account:', loaded);

    // Update account
    const updateRes = await fetch(`${BASE_URL}/accounts/${accId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      },
      body: JSON.stringify({ name: 'ACME Corporation', type: 'Customer' })
    });
    const updated = await updateRes.json();
    console.log('Updated account:', updated);

    // List accounts
    const listRes = await fetch(`${BASE_URL}/accounts`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });
    const list = await listRes.json();
    console.log('Accounts list:', list);

    // Delete account
    const delRes = await fetch(`${BASE_URL}/accounts/${accId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });
    const deleted = await delRes.json();
    console.log('Delete response:', deleted);

    // List activity logs
    const logsRes = await fetch(`${BASE_URL}/activity_logs`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });
    const logs = await logsRes.json();
    console.log('Activity logs:', logs);
    // Check logs for old/new values
    const entityLogsRes = await fetch(`${BASE_URL}/activity_logs?entityId=${accId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Organization-ID': orgId
      }
    });
    const entityLogs = await entityLogsRes.json();
    console.log('Entity logs for account:', entityLogs);
  } catch (err) {
    console.error('Accounts flow failed:', err);
  }
}

// Run tests
async function runTests() {
  const token = await testAuth();
  if (!token) return;

  const orgId = await testOrganizations(token);
  if (!orgId) return;

  await testDashboard(token, orgId);
  await testAccounts(token, orgId);

  console.log('Tests completed!');
}

runTests().catch(console.error);