import Fastify from 'fastify';
import cors from '@fastify/cors';
import { calculateReadinessScore, scoreCitationPresence } from '../../../packages/core/src/index';

const app = Fastify({ logger: true });
await app.register(cors, { origin: true });

app.get('/health', async () => ({ ok: true, service: 'aiready-stage6-api' }));

app.post('/v6/readiness-score', async (request) => {
  const body = request.body as any;
  return calculateReadinessScore(body);
});

app.post('/v6/citation-score', async (request) => {
  const body = request.body as any;
  return scoreCitationPresence(body.observations ?? []);
});

app.post('/v6/oc-prime/events', async (request) => {
  const body = request.body as any;
  // TODO: forward to OC Prime endpoint with signed request.
  return { accepted: true, dryRun: process.env.OC_PRIME_DRY_RUN !== 'false', eventType: body.type };
});

app.listen({ port: Number(process.env.PORT ?? 3001), host: '0.0.0.0' });
