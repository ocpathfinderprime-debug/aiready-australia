# AIReady Stage 6 Installation Notes

## Installed in this repository

- `website/` contains the live Netlify static website.
- `stage6/AIReadyAudit_Enterprise_Stage6/` contains the full Stage 6 developer, operator, runtime, MCP, OC Prime, security, commercialisation, partner and benchmark build pack.

## Live public website layer

The public Website V6 authority layer has been installed into `website/` and deployed from `main`.

Key live surfaces:

- `website/authority.html`
- service authority pages
- industry authority pages
- location authority pages
- comparison pages
- buyer-question pages
- methodology, benchmark, partner, pricing and knowledgebase pages
- `website/sitemap.xml`
- `website/llms.txt`
- `website/schema-graph.jsonld`

## Staged system layer

The Stage 6 runtime files under `stage6/AIReadyAudit_Enterprise_Stage6/` are source scaffolds and operating assets. They are intentionally not wired into production by this repository commit.

Before production activation, the runtime/API/MCP/database/OC Prime layers need:

- staging environment selection
- credentials and secret management
- database provisioning
- migration review
- auth and tenant model review
- OC Prime dry-run event routing
- MCP read-only tool deployment
- telemetry, approval and rollback gates
- security review

## Current boundary

This repository now preserves both layers:

1. the deployed static website layer in `website/`
2. the complete Stage 6 build pack in `stage6/`

Do not move Stage 6 runtime package files to the repository root until a backend deployment plan has been approved, because the current live deploy target is the static `website/` directory.
