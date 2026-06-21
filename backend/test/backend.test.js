import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createHmac } from 'node:crypto';
import { createServer } from '../src/server.js';
import { JsonlStore } from '../src/store.js';
import { verifyStripeSignature } from '../src/stripe.js';

async function withServer(fn) {
  const dataDir = await mkdtemp(join(tmpdir(), 'aiready-backend-'));
  const config = {
    port: 0,
    dataDir,
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
