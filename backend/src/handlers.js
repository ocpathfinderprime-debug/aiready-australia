import { getCatalog, mcpTools, publicResources, purchaseLinks } from './catalog.js';
import { calculateReadinessScore } from './scoring.js';
import { inferPackageFromStripeEvent, verifyStripeSignature } from './stripe.js';
import { serveStaticFile } from './static.js';

export async function readRawBody(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8');
}

export function jsonResponse(response, status, payload, headers = {}) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    ...headers,
  });
  response.end(JSON.stringify(payload, null, 2));
}

export function getCorsHeaders(origin, config) {
  const headers = {
    'vary': 'Origin',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization,stripe-signature',
  };

  if (config.allowedOrigins.includes(origin)) {
    headers['access-control-allow-origin'] = origin;
  }

  return headers;
}

function publicLeadPayload(payload) {
  return {
    type: payload.type || 'intake',
    status: payload.status || 'new',
    sourcePage: payload.sourcePage || payload.page || null,
    packageInterest: payload.packageInterest || payload.package || null,
    contact: {
      name: payload.name || payload.contact?.name || null,
      email: payload.email || payload.contact?.email || null,
      phone: payload.phone || payload.contact?.phone || null,
      business: payload.business || payload.contact?.business || null,
      website: payload.website || payload.contact?.website || null,
    },
    answers: payload.answers || payload,
    consent: Boolean(payload.consent || payload.privacyConsent || payload.allowContact),
    userAgent: payload.userAgent || null,
  };
}

function validateLead(payload) {
  const contact = payload.contact || {};
  if (!contact.email && !contact.website && !contact.business) {
    return 'Lead requires at least an email, business name, or website.';
  }
  return null;
}

async function verifyLinks({ liveCheck = false } = {}) {
  const links = Object.entries(purchaseLinks).map(([id, url]) => ({ id, url }));
  if (!liveCheck) return links.map((link) => ({ ...link, configured: true }));

  const checked = [];
  for (const link of links) {
    try {
      const response = await fetch(link.url, { method: 'HEAD', redirect: 'follow' });
      checked.push({ ...link, status: response.status, ok: response.ok, finalUrl: response.url });
    } catch (error) {
      checked.push({ ...link, status: null, ok: false, error: error.message });
    }
  }
  return checked;
}

export async function handleToolCall({ name, arguments: args = {} }, store) {
  if (name === 'get_service_catalog') {
    return getCatalog();
  }

  if (name === 'create_lead') {
    const payload = publicLeadPayload(args.payload || args);
    const error = validateLead(payload);
    if (error) return { ok: false, error };
    const record = await store.create('leads', payload);
    return { ok: true, id: record.id, status: record.status };
  }

  if (name === 'get_lead_status') {
    const id = args.id || args.leadId;
    if (!id) return { ok: false, error: 'lead id required' };
    const lead = await store.findById('leads', id);
    if (!lead) return { ok: false, error: 'lead not found' };
    return { ok: true, id: lead.id, status: lead.status, createdAt: lead.createdAt, packageInterest: lead.packageInterest };
  }

  if (name === 'calculate_readiness_score') {
    return calculateReadinessScore(args.payload || args);
  }

  if (name === 'verify_purchase_links') {
    return { ok: true, links: await verifyLinks({ liveCheck: Boolean(args.liveCheck) }) };
  }

  return { ok: false, error: `Unknown tool: ${name}` };
}

export async function handleRequest({ request, response, store, config }) {
  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  const origin = request.headers.origin || '';
  const corsHeaders = getCorsHeaders(origin, config);

  if (request.method === 'OPTIONS') {
    response.writeHead(204, corsHeaders);
    response.end();
    return;
  }

  if (origin && !config.allowedOrigins.includes(origin)) {
    jsonResponse(response, 403, { ok: false, error: 'Origin not allowed' }, corsHeaders);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/health') {
    jsonResponse(response, 200, {
      ok: true,
      service: 'aiready-backend',
      version: '1.0.0',
      storage: 'jsonl',
      time: new Date().toISOString(),
    }, corsHeaders);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/catalog') {
    jsonResponse(response, 200, { ok: true, catalog: getCatalog() }, corsHeaders);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/intake') {
    const rawBody = await readRawBody(request);
    const payload = rawBody ? JSON.parse(rawBody) : {};
    const lead = publicLeadPayload(payload);
    const error = validateLead(lead);
    if (error) {
      jsonResponse(response, 400, { ok: false, error }, corsHeaders);
      return;
    }
    const record = await store.create('leads', lead);
    jsonResponse(response, 202, { ok: true, id: record.id, status: record.status }, corsHeaders);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/stripe/webhook') {
    const rawBody = await readRawBody(request);
    const signature = request.headers['stripe-signature'];
    const verification = verifyStripeSignature({
      rawBody,
      signatureHeader: Array.isArray(signature) ? signature[0] : signature,
      secret: config.stripeWebhookSecret,
    });

    if (!verification.ok) {
      jsonResponse(response, 400, { ok: false, error: verification.reason }, corsHeaders);
      return;
    }

    const event = rawBody ? JSON.parse(rawBody) : {};
    const record = await store.create('purchases', {
      status: event.type === 'checkout.session.completed' ? 'paid' : 'received',
      eventType: event.type || 'unknown',
      packageId: inferPackageFromStripeEvent(event),
      stripeObjectId: event?.data?.object?.id || null,
      customerEmail: event?.data?.object?.customer_details?.email || null,
      amountTotal: event?.data?.object?.amount_total || null,
      signatureVerified: !verification.skipped,
      signatureSkipped: verification.skipped,
    });

    jsonResponse(response, 202, { ok: true, id: record.id, eventType: record.eventType, packageId: record.packageId }, corsHeaders);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/mcp/manifest') {
    jsonResponse(response, 200, {
      name: 'AIReady Australia Backend',
      version: '1.0.0',
      website: 'https://aireadyaudit.com.au',
      tools: mcpTools,
      resources: publicResources,
    }, corsHeaders);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/mcp/tools/call') {
    const rawBody = await readRawBody(request);
    const payload = rawBody ? JSON.parse(rawBody) : {};
    const result = await handleToolCall(payload, store);
    jsonResponse(response, result.ok === false ? 400 : 200, result, corsHeaders);
    return;
  }

  if (request.method === 'GET' && config.serveStatic) {
    const served = await serveStaticFile({ requestUrl: request.url, response, staticDir: config.staticDir });
    if (served) return;
  }

  jsonResponse(response, 404, { ok: false, error: 'Not found' }, corsHeaders);
}
