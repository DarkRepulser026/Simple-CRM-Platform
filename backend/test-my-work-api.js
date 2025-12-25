import fetch from 'node-fetch';

const TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNtamprbDFjdjAwMGMzenl3bWs4MXJibjAiLCJlbWFpbCI6Im1pbmVjcmFmdHRoYW5obG9pQGdtYWlsLmNvbSIsInJvbGUiOiJBR0VOVCIsIm9yZ2FuaXphdGlvbklkIjoiY21qamtsMTloMDAwMDN6eXd0eWo4b2ZnNyIsInR5cGUiOiJTVEFGRiIsInRva2VuVmVyc2lvbiI6MSwiaWF0IjoxNzY2NTU0ODgwLCJleHAiOjE3NjY2NDEyODB9.rTxG8oZcFdvcs0WYXY_Y2eFws_Uo4qZrc3AsvapNMRU';

async function testMyWork() {
  try {
    const response = await fetch('http://localhost:3001/api/crm/dashboard/my-work', {
      headers: {
        'Authorization': `Bearer ${TOKEN}`,
        'X-Organization-ID': 'cmjjkl19h00003zywtyj8ofg7'
      }
    });

    console.log('Status:', response.status);
    console.log('Status Text:', response.statusText);
    
    const data = await response.json();
    console.log('\nResponse:');
    console.log(JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testMyWork();
