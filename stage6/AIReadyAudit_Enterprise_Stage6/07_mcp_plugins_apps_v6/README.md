# MCP, Plugin and App Surfaces V6

## Purpose

Expose AIReady Audit capabilities safely to AI clients, ChatGPT app surfaces, internal OC Prime agents and partner workflows.

## Tool classes

- read: retrieve non-sensitive configuration or aggregate status
- draft: generate a draft, score or plan without changing state
- write: create or update records with scoped authorization
- high-risk write: requires approval token and audit log

## Deployment order

1. Read tools only
2. Draft tools
3. Low-risk write tools
4. High-risk write tools after security review
5. Marketplace/app submission
