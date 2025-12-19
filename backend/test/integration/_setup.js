import { spawn } from 'child_process';
import fetch from 'node-fetch';

const BASE_URL = `http://localhost:${process.env.PORT || 3001}`;
let serverProc;

export async function spawnServer() {
  serverProc = spawn('node', ['index.js'], { env: { ...process.env, NODE_ENV: 'test', PORT: process.env.PORT || 3001 } });
  serverProc.stdout.on('data', (d) => process.stdout.write(`[server] ${d}`));
  serverProc.stderr.on('data', (d) => process.stderr.write(`[server:err] ${d}`));
}

export async function waitForHealth(timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(`${BASE_URL}/health`);
      if (res.ok) return true;
    } catch (e) {
      // ignore
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  return false;
}

export async function stopServer() {
  if (serverProc) {
    serverProc.kill('SIGTERM');
    
    // Wait for the process to actually exit
    await new Promise((resolve) => {
      const timeout = setTimeout(() => {
        console.log('[test] Server did not exit gracefully, forcing kill...');
        serverProc.kill('SIGKILL');
        resolve();
      }, 5000); // Wait up to 5 seconds
      
      serverProc.on('exit', (code, signal) => {
        clearTimeout(timeout);
        console.log(`[test] Server exited with code ${code}, signal ${signal}`);
        resolve();
      });
      
      serverProc.on('error', (err) => {
        clearTimeout(timeout);
        console.log(`[test] Server error during shutdown: ${err.message}`);
        resolve();
      });
    });
    
    serverProc = null;
  }
}

export async function createAdminUserAndOrg() {
  const random = Math.floor(Math.random() * 1000000);
  const email = `testadmin+${random}@example.com`;
  const authRes = await fetch(`${BASE_URL}/auth/google`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, name: 'Test Admin', googleId: `test-google-${random}@example.com` })
  });
  const authJson = await authRes.json();
  return { adminToken: authJson.token, adminUserId: authJson.user.id };
}

export async function createOrganization(adminToken, name) {
  const orgRes = await fetch(`${BASE_URL}/organizations`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}` },
    body: JSON.stringify({ name: name || 'Test Org', description: 'For integration testing' })
  });
  return await orgRes.json();
}

export default { BASE_URL };
