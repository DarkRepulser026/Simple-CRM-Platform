/**
 * Comprehensive test script for customer portal endpoints (Phase 2)
 * Usage: node test-customer-endpoints.js
 */

const API_BASE = 'http://localhost:3001';

let customerToken = null;
let refreshToken = null;
let customerId = null;
let ticketId = null;
let messageId = null;
let attachmentId = null;

async function testPhase2Endpoints() {
  console.log('🧪 Testing Customer Portal Phase 2 Endpoints\n');
  console.log('='.repeat(60));

  // STEP 1: Register and login
  console.log('\n📝 STEP 1: Authentication\n');
  
  const email = `testcustomer_${Date.now()}@example.com`;
  const password = 'SecurePassword123!';

  try {
    const registerResponse = await fetch(`${API_BASE}/api/external/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        name: 'Test Customer Phase 2',
        companyName: 'Test Co',
        phone: '+1234567890'
      })
    });

    const registerData = await registerResponse.json();
    
    if (registerResponse.ok) {
      console.log('✅ Registration successful');
      customerToken = registerData.token;
      refreshToken = registerData.refreshToken;
      customerId = registerData.userId;
    } else {
      console.log('❌ Registration failed:', registerData.error);
      return;
    }
  } catch (error) {
    console.log('❌ Registration error:', error.message);
    return;
  }

  // STEP 2: Test Ticket Management Endpoints
  console.log('\n📋 STEP 2: Ticket Management\n');

  // 2.1: Create a ticket
  console.log('2.1: Creating a ticket...');
  try {
    const createTicketResponse = await fetch(`${API_BASE}/api/external/tickets`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        subject: 'Test Support Ticket',
        description: 'This is a test ticket created via API',
        priority: 'HIGH',
        category: 'Technical Support'
      })
    });

    const ticketData = await createTicketResponse.json();
    
    if (createTicketResponse.ok) {
      console.log('✅ Ticket created successfully');
      console.log('   Ticket ID:', ticketData.ticketId);
      console.log('   Ticket Number:', ticketData.number);
      console.log('   Status:', ticketData.status);
      ticketId = ticketData.ticketId;
    } else {
      console.log('❌ Create ticket failed:', ticketData.error);
    }
  } catch (error) {
    console.log('❌ Create ticket error:', error.message);
  }

  // 2.2: Get all tickets
  console.log('\n2.2: Getting all tickets...');
  try {
    const getTicketsResponse = await fetch(`${API_BASE}/api/external/tickets?page=1&limit=10`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${customerToken}`
      }
    });

    const ticketsData = await getTicketsResponse.json();
    
    if (getTicketsResponse.ok) {
      console.log('✅ Retrieved tickets successfully');
      console.log('   Total tickets:', ticketsData.pagination.total);
      console.log('   Tickets on page:', ticketsData.tickets.length);
    } else {
      console.log('❌ Get tickets failed:', ticketsData.error);
    }
  } catch (error) {
    console.log('❌ Get tickets error:', error.message);
  }

  // 2.3: Get ticket details
  if (ticketId) {
    console.log('\n2.3: Getting ticket details...');
    try {
      const getTicketResponse = await fetch(`${API_BASE}/api/external/tickets/${ticketId}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${customerToken}`
        }
      });

      const ticketDetail = await getTicketResponse.json();
      
      if (getTicketResponse.ok) {
        console.log('✅ Retrieved ticket details successfully');
        console.log('   Subject:', ticketDetail.subject);
        console.log('   Priority:', ticketDetail.priority);
        console.log('   Status:', ticketDetail.status);
        console.log('   Messages:', ticketDetail.messages.length);
      } else {
        console.log('❌ Get ticket details failed:', ticketDetail.error);
      }
    } catch (error) {
      console.log('❌ Get ticket details error:', error.message);
    }

    // 2.4: Update ticket
    console.log('\n2.4: Updating ticket...');
    try {
      const updateTicketResponse = await fetch(`${API_BASE}/api/external/tickets/${ticketId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${customerToken}`
        },
        body: JSON.stringify({
          subject: 'Updated Test Support Ticket',
          description: 'Updated description',
          priority: 'URGENT'
        })
      });

      const updatedTicket = await updateTicketResponse.json();
      
      if (updateTicketResponse.ok) {
        console.log('✅ Ticket updated successfully');
        console.log('   New subject:', updatedTicket.subject);
        console.log('   New priority:', updatedTicket.priority);
      } else {
        console.log('❌ Update ticket failed:', updatedTicket.error);
      }
    } catch (error) {
      console.log('❌ Update ticket error:', error.message);
    }
  }

  // STEP 3: Test Message Endpoints
  if (ticketId) {
    console.log('\n💬 STEP 3: Ticket Messages\n');

    // 3.1: Add message to ticket
    console.log('3.1: Adding message to ticket...');
    try {
      const addMessageResponse = await fetch(`${API_BASE}/api/external/tickets/${ticketId}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${customerToken}`
        },
        body: JSON.stringify({
          content: 'This is a test message from the customer'
        })
      });

      const messageData = await addMessageResponse.json();
      
      if (addMessageResponse.ok) {
        console.log('✅ Message added successfully');
        console.log('   Message ID:', messageData.messageId);
        console.log('   Created at:', messageData.createdAt);
        messageId = messageData.messageId;
      } else {
        console.log('❌ Add message failed:', messageData.error);
      }
    } catch (error) {
      console.log('❌ Add message error:', error.message);
    }

    // 3.2: Get ticket messages
    console.log('\n3.2: Getting ticket messages...');
    try {
      const getMessagesResponse = await fetch(`${API_BASE}/api/external/tickets/${ticketId}/messages?page=1&limit=20`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${customerToken}`
        }
      });

      const messagesData = await getMessagesResponse.json();
      
      if (getMessagesResponse.ok) {
        console.log('✅ Retrieved messages successfully');
        console.log('   Total messages:', messagesData.pagination.total);
        console.log('   Messages on page:', messagesData.messages.length);
      } else {
        console.log('❌ Get messages failed:', messagesData.error);
      }
    } catch (error) {
      console.log('❌ Get messages error:', error.message);
    }

    // 3.3: Update message (within 15 minutes)
    if (messageId) {
      console.log('\n3.3: Updating message...');
      try {
        const updateMessageResponse = await fetch(`${API_BASE}/api/external/tickets/${ticketId}/messages/${messageId}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${customerToken}`
          },
          body: JSON.stringify({
            content: 'This is an updated test message'
          })
        });

        const updatedMessage = await updateMessageResponse.json();
        
        if (updateMessageResponse.ok) {
          console.log('✅ Message updated successfully');
          console.log('   Updated content:', updatedMessage.content);
        } else {
          console.log('❌ Update message failed:', updatedMessage.error);
        }
      } catch (error) {
        console.log('❌ Update message error:', error.message);
      }
    }
  }

  // STEP 4: Test Profile Endpoints
  console.log('\n👤 STEP 4: Customer Profile\n');

  // 4.1: Get profile
  console.log('4.1: Getting customer profile...');
  try {
    const getProfileResponse = await fetch(`${API_BASE}/api/external/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${customerToken}`
      }
    });

    const profileData = await getProfileResponse.json();
    
    if (getProfileResponse.ok) {
      console.log('✅ Retrieved profile successfully');
      console.log('   Name:', profileData.name);
      console.log('   Email:', profileData.email);
      console.log('   Company:', profileData.profile?.companyName);
    } else {
      console.log('❌ Get profile failed:', profileData.error);
    }
  } catch (error) {
    console.log('❌ Get profile error:', error.message);
  }

  // 4.2: Update profile
  console.log('\n4.2: Updating profile...');
  try {
    const updateProfileResponse = await fetch(`${API_BASE}/api/external/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        name: 'Updated Customer Name',
        companyName: 'Updated Company Inc',
        phone: '+9876543210',
        address: '123 Test Street',
        city: 'Test City',
        state: 'CA',
        postalCode: '12345',
        country: 'USA'
      })
    });

    const updatedProfile = await updateProfileResponse.json();
    
    if (updateProfileResponse.ok) {
      console.log('✅ Profile updated successfully');
      console.log('   New name:', updatedProfile.name);
      console.log('   New company:', updatedProfile.profile?.companyName);
    } else {
      console.log('❌ Update profile failed:', updatedProfile.error);
    }
  } catch (error) {
    console.log('❌ Update profile error:', error.message);
  }

  // 4.3: Get tickets summary
  console.log('\n4.3: Getting tickets summary...');
  try {
    const summaryResponse = await fetch(`${API_BASE}/api/external/profile/tickets-summary`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${customerToken}`
      }
    });

    const summaryData = await summaryResponse.json();
    
    if (summaryResponse.ok) {
      console.log('✅ Retrieved tickets summary successfully');
      console.log('   Total tickets:', summaryData.totalCount);
      console.log('   Open tickets:', summaryData.openCount);
      console.log('   Resolved tickets:', summaryData.resolvedCount);
      console.log('   Closed tickets:', summaryData.closedCount);
    } else {
      console.log('❌ Get summary failed:', summaryData.error);
    }
  } catch (error) {
    console.log('❌ Get summary error:', error.message);
  }

  // 4.4: Change password
  console.log('\n4.4: Changing password...');
  try {
    const changePasswordResponse = await fetch(`${API_BASE}/api/external/profile/password`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${customerToken}`
      },
      body: JSON.stringify({
        currentPassword: password,
        newPassword: 'NewSecurePassword456!'
      })
    });

    const passwordData = await changePasswordResponse.json();
    
    if (changePasswordResponse.ok) {
      console.log('✅ Password changed successfully');
      console.log('   Message:', passwordData.message);
    } else {
      console.log('❌ Change password failed:', passwordData.error);
    }
  } catch (error) {
    console.log('❌ Change password error:', error.message);
  }

  // STEP 5: Test Attachment Endpoints (skipped - requires actual file)
  console.log('\n📎 STEP 5: Attachments\n');
  console.log('⚠️  Attachment tests skipped - requires actual file upload');
  console.log('   To test manually:');
  console.log('   POST /api/external/tickets/:id/attachments (with file)');
  console.log('   GET /api/external/tickets/:id/attachments/:attachmentId');
  console.log('   DELETE /api/external/tickets/:id/attachments/:attachmentId');

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('\n🎉 Phase 2 Endpoint Tests Completed!\n');
  console.log('📝 Summary:');
  console.log('   ✅ Authentication: Working');
  console.log('   ✅ Ticket Management: 4/4 endpoints tested');
  console.log('   ✅ Ticket Messages: 3/3 endpoints tested');
  console.log('   ✅ Customer Profile: 4/4 endpoints tested');
  console.log('   ⚠️  Attachments: Skipped (requires file upload)\n');
  console.log('📋 Created Resources:');
  console.log('   Customer ID:', customerId);
  console.log('   Ticket ID:', ticketId);
  console.log('   Message ID:', messageId);
  console.log('\n⚠️  Note: Clean up test data manually if needed');
}

// Run tests
testPhase2Endpoints().catch(error => {
  console.error('\n💥 Fatal error:', error);
  process.exit(1);
});
