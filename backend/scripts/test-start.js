import { spawn } from 'child_process';
import fetch from 'node-fetch';

const PORT = process.env.PORT || 3001;
const BASE_URL = `http://localhost:${PORT}`;

function spawnServer() {
  const child = spawn('node', ['index.js'], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, NODE_ENV: 'test', PORT: PORT }
  });

  child.stdout.on('data', (d) => process.stdout.write(`[server] ${d}`));
  child.stderr.on('data', (d) => process.stderr.write(`[server:err] ${d}`));

  return child;
}

async function waitForHealth(timeoutMs = 15000, intervalMs = 500) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(`${BASE_URL}/health`);
      if (res.ok) return true;
    } catch (e) {
      // ignore
    }
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

(async function main() {
  console.log('Starting server for health probe...');
  const server = spawnServer();
  const ok = await waitForHealth(20000, 500);
  if (ok) {
    console.log('Server healthy! Stopping server.');
    server.kill();
    process.exit(0);
  } else {
    console.error('Health check failed within timeout.');
    server.kill();
    process.exit(1);
  }
})();
