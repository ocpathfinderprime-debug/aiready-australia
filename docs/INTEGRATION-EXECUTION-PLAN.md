# AIReady Integration Execution Plan

## Current Truth

The public website is strong enough for buyers to understand the offer, but the full operating system is not complete yet. The next stage is to connect the website to backend capture, Stripe events, records, OC Prime routing and governed MCP tools.

## Hosting Decision

Hostinger is acceptable if the plan supports Node.js web apps or VPS hosting. Static-only hosting is not enough for the next stage because AIReady needs API endpoints, Stripe webhooks, intake capture and MCP-style tool calls.

Recommended path:

1. Use Hostinger managed Node.js app hosting if available on the account.
2. Deploy this repository from GitHub.
3. Use `npm start` as the start command.
4. Set the app root to the repository root.
5. Set environment variables from `backend/.env.example`.
6. Point `aireadyaudit.com.au` to the Hostinger app only after staging checks pass.

Fallback path:

1. Keep the static website on the current host.
2. Deploy only the backend on Hostinger or another Node-capable host.
3. Set `window.AIREADY_BACKEND_URL` on the website to the backend base URL.

## Founder Action Required

These steps require account access and should be done by the account owner or with a secure screen-share:

1. Clear the current Netlify credit issue or decide to move hosting.
2. Confirm Hostinger plan has Node.js web app support or VPS access.
3. Add deployment environment variables:
   - `AIREADY_SERVE_STATIC=true`
   - `AIREADY_STATIC_DIR=./website`
   - `AIREADY_DATA_DIR=./data`
   - `AIREADY_ALLOWED_ORIGINS=https://aireadyaudit.com.au`
   - `STRIPE_WEBHOOK_SECRET=<from Stripe>`
4. In Stripe, add webhook endpoint:
   - `https://aireadyaudit.com.au/api/stripe/webhook`
5. Subscribe the webhook to:
   - `checkout.session.completed`
6. Copy the Stripe signing secret into `STRIPE_WEBHOOK_SECRET`.

## Prime Backend Work Already Done

- Node backend foundation.
- Health endpoint.
- Package catalog endpoint.
- Intake endpoint.
- Stripe webhook endpoint with signature verification.
- MCP manifest endpoint.
- MCP tool-call endpoint.
- Static website serving from the same backend when enabled.
- Public integration manifest files.
- Local tests and backend smoke checks.

## Remaining Build Work

### 1. Production Data Store

Replace JSONL local storage with an approved database:

- Supabase/Postgres
- Neon Postgres
- Airtable as a temporary lightweight option

Tables needed first:

- `leads`
- `purchases`
- `audit_jobs`
- `events`
- `mcp_tool_calls`

### 2. Admin Dashboard

Build a private operator view:

- lead list
- paid purchase list
- audit status
- package/tier
- Stripe reference
- notes
- CSV export

### 3. OC Prime Event Routing

Emit structured events for:

- lead created
- purchase completed
- intake submitted
- audit job created
- audit status changed
- report approval requested

### 4. MCP Hardening

Before external use:

- add auth
- add audit logs
- split read-only tools from write tools
- require approval for high-risk actions
- add tool telemetry

### 5. Service Fulfillment

Create delivery workflows for each public offer:

- AI Readiness Audit
- AI Tools Audit
- AI Automation Audit
- AI Website Visibility Audit
- AI Governance Review
- Implementation Sprint
- Enterprise Capability Assessment

Each workflow needs:

- intake requirements
- scoring model
- report template
- QA checklist
- delivery SLA
- refund/issue handling

## Go-Live Gates

Do not mark the full system complete until:

- latest commit is live on the public domain
- backend health returns `200`
- intake creates a backend record
- Stripe webhook records a test purchase
- purchase links still return `200`
- MCP manifest returns expected tools
- no secrets are present in the repo
- one test audit can be processed end to end
