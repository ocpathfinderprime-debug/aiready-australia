import { Readable } from 'node:stream';
import { connectLambda, getStore } from '@netlify/blobs';
import { getConfig } from './config.js';
import { handleRequest, jsonResponse } from './handlers.js';
import { JsonlStore, NetlifyBlobStore } from './store.js';

function normaliseHeaders(headers = {}) {
  return Object.fromEntries(
    Object.entries(headers).map(([key, value]) => [key.toLowerCase(), Array.isArray(value) ? value.join(',') : value]),
  );
}

function buildRequestUrl(event, headers) {
  const host = headers.host || 'aireadyaudit.com.au';
  const protocol = headers['x-forwarded-proto'] || 'https';
  const rawQuery = event.rawQuery || '';
  const query = new URLSearchParams(rawQuery);
  const routedPath = query.get('path') || event.queryStringParameters?.path || event.path || '/';
  query.delete('path');
  const queryString = query.toString();
  return `${protocol}://${host}${routedPath}${queryString ? `?${queryString}` : ''}`;
}

function eventBodyBuffer(event) {
  if (!event.body) return Buffer.alloc(0);
  return Buffer.from(event.body, event.isBase64Encoded ? 'base64' : 'utf8');
}

function createEventRequest(event) {
  const headers = normaliseHeaders(event.headers);
  const body = eventBodyBuffer(event);
  const request = Readable.from(body.length ? [body] : []);
  request.method = event.httpMethod || event.requestContext?.http?.method || 'GET';
  request.headers = headers;
  request.url = buildRequestUrl(event, headers);
  return request;
}

function createResponseCollector() {
  const chunks = [];
  const response = {
    statusCode: 200,
    headers: {},
    writeHead(statusCode, headers = {}) {
      this.statusCode = statusCode;
      this.headers = { ...this.headers, ...headers };
    },
    write(chunk) {
      if (chunk === undefined || chunk === null) return;
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(String(chunk)));
    },
    end(chunk) {
      this.write(chunk);
    },
    toNetlifyResponse() {
      return {
        statusCode: this.statusCode,
        headers: this.headers,
        body: Buffer.concat(chunks).toString('utf8'),
      };
    },
  };
  return response;
}

function getNetlifyConfig() {
  return getConfig({
    ...process.env,
    AIREADY_STORAGE_DRIVER: process.env.AIREADY_STORAGE_DRIVER || 'netlify-blobs',
    AIREADY_DATA_DIR: process.env.AIREADY_DATA_DIR || '/tmp/aiready-data',
    AIREADY_SERVE_STATIC: process.env.AIREADY_SERVE_STATIC || 'false',
  });
}

function createStore(config) {
  if (config.storageDriver === 'netlify-blobs') {
    return new NetlifyBlobStore({
      getStore,
      storeName: config.blobsStore,
      siteID: process.env.NETLIFY_BLOBS_SITE_ID || process.env.SITE_ID || '',
      token: process.env.NETLIFY_BLOBS_TOKEN || '',
    });
  }

  return new JsonlStore({ dataDir: config.dataDir });
}

export async function handleNetlifyEvent(event) {
  if (event.blobs) {
    connectLambda(event);
  }

  const config = getNetlifyConfig();
  const request = createEventRequest(event);
  const response = createResponseCollector();
  const store = createStore(config);

  try {
    await handleRequest({ request, response, store, config });
  } catch (error) {
    jsonResponse(response, 500, {
      ok: false,
      error: 'Internal server error',
      detail: process.env.NODE_ENV === 'production' ? undefined : error.message,
    });
  }

  return response.toNetlifyResponse();
}
