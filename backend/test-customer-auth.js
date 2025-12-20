/**
 * Simple test script for customer authentication endpoints
 * Usage: node test-customer-auth.js
 */

const API_BASE = 'http://localhost:3001';

async function testCustomerAuth() {
  console.log('🧪 Testing Customer Authentication Endpoints\n');

  // Test 1: Register a new customer
  console.log('1️⃣ Testing customer registration...');
  try {
    const registerResponse = await fetch(`${API_BASE}/api/external/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'testcustomer@example.com',
        password: 'TestPassword123!',
        name: 'Test Customer',
        companyName: 'Test Company Inc.',
        phone: '+1234567890'
      })
    });

    const registerData = await registerResponse.json();
    
    if (registerResponse.ok) {
      console.log('✅ Registration successful');
      console.log('   User ID:', registerData.userId);
      console.log('   Email:', registerData.user.email);
      console.log('   Token received:', registerData.token ? 'Yes' : 'No');
      console.log('   Refresh token received:', registerData.refreshToken ? 'Yes' : 'No');
      console.log('');
    } else {
      console.log('❌ Registration failed:', registerData.error || registerData.message);
      console.log('');
    }
  } catch (error) {
    console.log('❌ Registration error:', error.message);
    console.log('');
  }

  // Test 2: Login with customer credentials
  console.log('2️⃣ Testing customer login...');
  try {
    const loginResponse = await fetch(`${API_BASE}/api/external/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'testcustomer@example.com',
        password: 'TestPassword123!'
      })
    });

    const loginData = await loginResponse.json();
    
    if (loginResponse.ok) {
      console.log('✅ Login successful');
      console.log('   User ID:', loginData.user.id);
      console.log('   User type:', loginData.user.type);
      console.log('   Token received:', loginData.token ? 'Yes' : 'No');
      console.log('');

      // Save token for subsequent tests
      global.customerToken = loginData.token;
      global.refreshToken = loginData.refreshToken;
    } else {
      console.log('❌ Login failed:', loginData.error || loginData.message);
      console.log('');
      return; // Stop if login fails
    }
  } catch (error) {
    console.log('❌ Login error:', error.message);
    console.log('');
    return;
  }

  // Test 3: Verify token
  console.log('3️⃣ Testing token verification...');
  try {
    const verifyResponse = await fetch(`${API_BASE}/api/external/auth/verify`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${global.customerToken}`
      }
    });

    const verifyData = await verifyResponse.json();
    
    if (verifyResponse.ok) {
      console.log('✅ Token verified successfully');
      console.log('   Is valid:', verifyData.isValid);
      console.log('   User email:', verifyData.user.email);
      console.log('');
    } else {
      console.log('❌ Token verification failed:', verifyData.error || verifyData.message);
      console.log('');
    }
  } catch (error) {
    console.log('❌ Verification error:', error.message);
    console.log('');
  }

  // Test 4: Refresh token
  console.log('4️⃣ Testing token refresh...');
  try {
    const refreshResponse = await fetch(`${API_BASE}/api/external/auth/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        refreshToken: global.refreshToken
      })
    });

    const refreshData = await refreshResponse.json();
    
    if (refreshResponse.ok) {
      console.log('✅ Token refresh successful');
      console.log('   New token received:', refreshData.token ? 'Yes' : 'No');
      console.log('');
    } else {
      console.log('❌ Token refresh failed:', refreshData.error || refreshData.message);
      console.log('');
    }
  } catch (error) {
    console.log('❌ Token refresh error:', error.message);
    console.log('');
  }

  // Test 5: Logout
  console.log('5️⃣ Testing logout...');
  try {
    const logoutResponse = await fetch(`${API_BASE}/api/external/auth/logout`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${global.customerToken}`
      }
    });

    const logoutData = await logoutResponse.json();
    
    if (logoutResponse.ok) {
      console.log('✅ Logout successful');
      console.log('   Success:', logoutData.success);
      console.log('');
    } else {
      console.log('❌ Logout failed:', logoutData.error || logoutData.message);
      console.log('');
    }
  } catch (error) {
    console.log('❌ Logout error:', error.message);
    console.log('');
  }

  // Test 6: Verify token after logout (should fail)
  console.log('6️⃣ Testing token verification after logout (should fail)...');
  try {
    const verifyAfterLogoutResponse = await fetch(`${API_BASE}/api/external/auth/verify`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${global.customerToken}`
      }
    });

    const verifyAfterLogoutData = await verifyAfterLogoutResponse.json();
    
    if (!verifyAfterLogoutResponse.ok) {
      console.log('✅ Token correctly invalidated after logout');
      console.log('   Error:', verifyAfterLogoutData.error || verifyAfterLogoutData.message);
      console.log('');
    } else {
      console.log('❌ Token still valid after logout (this is a problem!)');
      console.log('');
    }
  } catch (error) {
    console.log('❌ Verification error:', error.message);
    console.log('');
  }

  console.log('🎉 Customer authentication tests completed!\n');
  console.log('📝 Note: Make sure the backend server is running on port 3001');
  console.log('📝 You may need to manually clean up the test customer from the database');
}

// Run tests
testCustomerAuth().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
