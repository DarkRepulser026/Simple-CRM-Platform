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

// Run tests
async function runTests() {
  const token = await testAuth();
  if (!token) return;

  const orgId = await testOrganizations(token);
  if (!orgId) return;

  await testDashboard(token, orgId);

  console.log('Tests completed!');
}

runTests().catch(console.error);