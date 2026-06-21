import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createHmac } from 'node:crypto';
import { createServer } from '../src/server.js';
import { JsonlStore, NetlifyBlobStore } from '../src/store.js';
import { verifyStripeSignature } from '../src/stripe.js';
import { handleNetlifyEvent } from '../src/netlify.js';

async function withServer(fn) {
  const dataDir = await mkdtemp(join(tmpdir(), 'aiready-backend-'));
  const config = {
    port: 0,
    dataDir,
    serveStatic: true,
    staticDir: './website',
    allowedOrigins: ['http://127.0.0.1:8802'],
    stripeWebhookSecret: 'whsec_test',
    adminApiToken: '',
  };
  const server = createServer({ config, store: new JsonlStore({ dataDir }) });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  try {
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await rm(dataDir, { recursive: true, force: true });
  }
}

test('health and catalog endpoints respond', async () => {
  await withServer(async (baseUrl) => {
    const health = await fetch(`${baseUrl}/health`);
    assert.equal(health.status, 200);
    assert.equal((await health.json()).ok, true);

    const catalog = await fetch(`${baseUrl}/api/catalog`);
    const body = await catalog.json();
    assert.equal(catalog.status, 200);
    assert.equal(body.catalog.purchaseLinks.starterAudit, 'https://buy.stripe.com/8x200idHAep9bvRejYebu03');
    assert.equal(body.catalog.purchaseLinks.businessAudit, 'https://buy.stripe.com/bJecN4fPI1Cn9nJcbQebu04');
  });
});

test('intake endpoint stores a lead', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/intake`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', origin: 'http://127.0.0.1:8802' },
      body: JSON.stringify({
        name: 'Test Buyer',
        email: 'buyer@example.com',
        business: 'Example Co',
        packageInterest: 'business_audit',
        consent: true,
      }),
    });
    const body = await response.json();
    assert.equal(response.status, 202);
    assert.equal(body.ok, true);
    assert.equal(body.status, 'new');
    assert.match(body.id, /^[0-9a-f-]+$/);
  });
});

test('mcp tool call can calculate readiness score', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/mcp/tools/call`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        name: 'calculate_readiness_score',
        arguments: {
          payload: {
            techComfort: 8,
            dataQuality: 7,
            currentAiUse: 'ChatGPT',
            documentedProcesses: 'Some',
            budget: '500',
          },
        },
      }),
    });
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(typeof body.score, 'number');
    assert.ok(['foundation', 'emerging', 'ready', 'advanced'].includes(body.band));
  });
});

test('backend can serve static website manifests', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/mcp-manifest.json`);
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.name, 'AIReady Australia');
    assert.ok(body.tools.includes('get_service_catalog'));
  });
});

test('stripe signature verification accepts valid signatures', () => {
  const rawBody = JSON.stringify({ type: 'checkout.session.completed' });
  const timestamp = Math.floor(Date.now() / 1000);
  const signature = createHmac('sha256', 'whsec_test').update(`${timestamp}.${rawBody}`).digest('hex');
  const result = verifyStripeSignature({
    rawBody,
    signatureHeader: `t=${timestamp},v1=${signature}`,
    secret: 'whsec_test',
  });
  assert.equal(result.ok, true);
  assert.equal(result.skipped, false);
});

test('stripe webhook rejects invalid signatures', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/stripe/webhook`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'stripe-signature': 't=1,v1=bad',
      },
      body: JSON.stringify({ type: 'checkout.session.completed' }),
    });
    assert.equal(response.status, 400);
  });
});

test('netlify function adapter serves backend routes', async () => {
  const dataDir = await mkdtemp(join(tmpdir(), 'aiready-netlify-'));
  const previousDataDir = process.env.AIREADY_DATA_DIR;
  const previousServeStatic = process.env.AIREADY_SERVE_STATIC;
  process.env.AIREADY_DATA_DIR = dataDir;
  const previousStorageDriver = process.env.AIREADY_STORAGE_DRIVER;
  process.env.AIREADY_STORAGE_DRIVER = 'jsonl';
  process.env.AIREADY_SERVE_STATIC = 'false';

  try {
    const health = await handleNetlifyEvent({
      httpMethod: 'GET',
      path: '/.netlify/functions/backend',
      rawQuery: 'path=%2Fhealth',
      headers: { host: 'aireadyaudit.com.au' },
    });
    assert.equal(health.statusCode, 200);
    assert.equal(JSON.parse(health.body).ok, true);

    const catalog = await handleNetlifyEvent({
      httpMethod: 'GET',
      path: '/.netlify/functions/backend',
      rawQuery: 'path=%2Fapi%2Fcatalog',
      headers: { host: 'aireadyaudit.com.au' },
    });
    assert.equal(catalog.statusCode, 200);
    assert.equal(JSON.parse(catalog.body).catalog.purchaseLinks.starterAudit, 'https://buy.stripe.com/8x200idHAep9bvRejYebu03');

    const intake = await handleNetlifyEvent({
      httpMethod: 'POST',
      path: '/.netlify/functions/backend',
      rawQuery: 'path=%2Fapi%2Fintake',
      headers: {
        host: 'aireadyaudit.com.au',
        origin: 'https://aireadyaudit.com.au',
        'content-type': 'application/json',
      },
      body: JSON.stringify({ email: 'buyer@example.com', business: 'Example Co', consent: true }),
    });
    assert.equal(intake.statusCode, 202);
    assert.equal(JSON.parse(intake.body).ok, true);
  } finally {
    if (previousDataDir === undefined) delete process.env.AIREADY_DATA_DIR;
    else process.env.AIREADY_DATA_DIR = previousDataDir;
    if (previousStorageDriver === undefined) delete process.env.AIREADY_STORAGE_DRIVER;
    else process.env.AIREADY_STORAGE_DRIVER = previousStorageDriver;
    if (previousServeStatic === undefined) delete process.env.AIREADY_SERVE_STATIC;
    else process.env.AIREADY_SERVE_STATIC = previousServeStatic;
    await rm(dataDir, { recursive: true, force: true });
  }
});

test('netlify blob store persists and reads records through injected store API', async () => {
  const blobs = new Map();
  const fakeStore = {
    async setJSON(key, value) {
      blobs.set(key, value);
      return { modified: true, etag: `"${key}"` };
    },
    async get(key) {
      return blobs.get(key) || null;
    },
    async list({ prefix }) {
      return {
        blobs: [...blobs.keys()]
          .filter((key) => key.startsWith(prefix))
          .map((key) => ({ key, etag: `"${key}"` })),
        directories: [],
      };
    },
  };

  const store = new NetlifyBlobStore({ getStore: () => fakeStore, storeName: 'test-records' });
  const lead = await store.create('leads', { status: 'new', contact: { email: 'buyer@example.com' } });
  const found = await store.findById('leads', lead.id);
  const records = await store.list('leads');

  assert.equal(found.id, lead.id);
  assert.equal(records.length, 1);
  assert.equal(records[0].contact.email, 'buyer@example.com');
});
