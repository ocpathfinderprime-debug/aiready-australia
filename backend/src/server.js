import { createServer as createHttpServer } from 'node:http';
import { getConfig } from './config.js';
import { handleRequest, jsonResponse } from './handlers.js';
import { JsonlStore } from './store.js';

export function createServer({ config = getConfig(), store = new JsonlStore({ dataDir: config.dataDir }) } = {}) {
  return createHttpServer(async (request, response) => {
    try {
      await handleRequest({ request, response, store, config });
    } catch (error) {
      jsonResponse(response, 500, {
        ok: false,
        error: 'Internal server error',
        detail: process.env.NODE_ENV === 'production' ? undefined : error.message,
      });
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const config = getConfig();
  const server = createServer({ config });
  server.listen(config.port, '0.0.0.0', () => {
    console.log(`AIReady backend listening on http://0.0.0.0:${config.port}`);
  });
}
