# Threat Model Stage 6

## Assets

- customer intake data
- uploaded evidence
- report drafts
- AI recommendations
- partner workspaces
- MCP tool tokens
- OC Prime events
- benchmark datasets

## Key threats

- cross-tenant data exposure
- prompt injection from external content
- MCP tool poisoning
- excessive OAuth scopes
- leaked API keys
- report hallucination or unsupported claims
- partner misuse of templates
- benchmark re-identification

## Controls

- tenant isolation and RLS
- scoped tokens
- short-lived approval tokens
- prompt-injection isolation
- report QA and claim register
- audit logs
- data minimisation
- anonymisation and suppression thresholds
- incident response runbooks
