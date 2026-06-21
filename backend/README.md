# AIReady Backend Foundation

This backend is the next operating layer for AIReady Australia. It keeps the public website static while adding secure endpoints for lead capture, purchase-event handling, package data, and MCP-style agent operations.

No secrets are stored in this repository. Configure secrets through the deployment platform.

## Run Locally

```bash
npm run backend:dev
```

Default local URL:

```text
http://127.0.0.1:3001
```

## Environment

Copy `backend/.env.example` into your deployment environment and set:

- `PORT`: backend port.
- `AIREADY_DATA_DIR`: local JSONL storage path for development.
- `AIREADY_STORAGE_DRIVER`: `jsonl` for local file storage or `netlify-blobs` for Netlify production storage.
- `AIREADY_BLOBS_STORE`: Netlify Blobs store name. Defaults to `aiready-records`.
- `AIREADY_SERVE_STATIC`: set `true` to serve the public website from the backend.
- `AIREADY_STATIC_DIR`: static website directory. Defaults to `./website`.
- `AIREADY_ALLOWED_ORIGINS`: comma-separated browser origins allowed to call the API.
- `STRIPE_WEBHOOK_SECRET`: Stripe webhook signing secret. Required before production webhook activation.
- `ADMIN_API_TOKEN`: optional bearer token for admin-only reads.

## Endpoints

- `GET /health`: backend health status.
- `GET /api/catalog`: public package, service, purchase-link, and resource catalogue.
- `POST /api/intake`: captures a lead or intake payload.
- `POST /api/stripe/webhook`: verifies Stripe webhook signatures when `STRIPE_WEBHOOK_SECRET` is configured and records checkout events.
- `GET /mcp/manifest`: private MCP-style tool and resource manifest.
- `POST /mcp/tools/call`: calls supported backend tools.

When `AIREADY_SERVE_STATIC=true`, the same server also serves the static website files from `AIREADY_STATIC_DIR`, including `/`, `/intake.html`, `/llms.txt`, `/mcp-manifest.json`, and `/.well-known/mcp-manifest.json`.

## Netlify Functions

The same backend can run on Netlify through `netlify/functions/backend.js`.

Public routes are mapped in the root `netlify.toml`:

- `/health`
- `/api/*`
- `/mcp/*`

Set production environment variables in Netlify before enabling live intake and webhook workflows. Netlify Functions default to `AIREADY_STORAGE_DRIVER=netlify-blobs`, which persists lead and purchase records in the site-wide `AIREADY_BLOBS_STORE`.

## MCP Tools

- `get_service_catalog`
- `create_lead`
- `get_lead_status`
- `calculate_readiness_score`
- `verify_purchase_links`

The MCP endpoint is designed as the backend contract for Prime/OpenClaw integration. Keep write tools behind trusted infrastructure before exposing them outside private operations.

## Production Notes

The JSONL adapter is retained for local development and portable smoke tests. Netlify Blobs is suitable for a first production launch with moderate write volume. Before higher-volume operation or complex reporting, add a database or CRM adapter for Supabase, Neon Postgres, Airtable, HubSpot, or another approved system.
