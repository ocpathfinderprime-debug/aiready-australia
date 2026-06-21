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

## MCP Tools

- `get_service_catalog`
- `create_lead`
- `get_lead_status`
- `calculate_readiness_score`
- `verify_purchase_links`

The MCP endpoint is designed as the backend contract for Prime/OpenClaw integration. Keep write tools behind trusted infrastructure before exposing them outside private operations.

## Production Notes

The current storage adapter writes JSONL records for a simple first deployment. Before higher-volume operation, replace `backend/src/store.js` with a database adapter for Supabase, Neon Postgres, Airtable, or another approved system.
