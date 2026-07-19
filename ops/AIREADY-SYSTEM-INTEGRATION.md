# AIReady System Integration — Prompt Kit Authority Bridge

Date: 2026-07-14 AWST
Mission: AIReady Australia reactivation and system upgrade

## Purpose

This file is the bridge between the AIReady Audit Prompt Kit (the authority) and the workspace ops files (the operations layer). It defines what the kit governs, what the workspace ops files govern, and how they connect.

## Authority structure

### Prompt Kit = Authority
Location: `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/`

The kit owns:
- Prime identity when operating as audit orchestrator (`00_PRIME_BOOT_AIREADY_INTAKE.md`)
- Trigger event definition and immediate procedure (`01_TRIGGER_WORKFLOW.md`)
- Tier parameters, research depth, deliverables, and value logic (`02_TIER_PARAMETERS.md`)
- Agent handoff assignments and return specs (`03_AGENT_HANDOFFS.md`)
- Intake extraction prompt and output structure (`04_INTAKE_EXTRACTION_PROMPT.md`)
- Research orchestration prompt and evidence rules (`05_RESEARCH_ORCHESTRATOR_PROMPT.md`)
- Scoring model, weights, classification bands, and mandatory fields (`06_SCORING_MODEL.md`)
- Evidence vault schema and evidence rules (`07_EVIDENCE_VAULT_SCHEMA.md`)
- Report blueprints for Starter, Business, and Enterprise (`08_REPORT_BLUEPRINTS.md`)
- QA gate checklist (`09_QUALITY_GATE_CHECKLIST.md`)
- Tier-specific report generation prompts (`10–12`)
- Enterprise stakeholder interview prompt (`13`)
- Client delivery email prompts (`14`)
- Machine-readable audit rules (`15_AUDIT_RULES.yaml`)
- README with verified public anchors (`README.md`)

### Workspace Ops Files = Operations Layer
Location: `/home/path-finder-prime/.openclaw/workspace-prime/ops/` and root

The workspace owns:
- Zoho CRM workflow spec and trigger routing (`ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md`)
- Delivery workflow and tiered deliverable matrix (`ops/AIREADY-DELIVERY-WORKFLOW-AND-PACKS.md`)
- First live intake operator sequence (`ops/AIREADY-FIRST-INTAKE-RUNBOOK.md`)
  - local readiness preflight lane via `scripts/aiready-preflight-check.sh`
  - direct-invocation guardrail via `scripts/aiready-validate-direct-invocation.sh`
  - sustained gate via `scripts/aiready-sustained-readiness-check.sh`
  - sustained-history audit via `scripts/aiready-validate-sustained-readiness-history.sh`
  - release-history trend audit via `scripts/aiready-validate-release-readiness-history-trend.sh`
  - sustained-history trend audit via `scripts/aiready-validate-sustained-readiness-history-trend.sh`
  - single-command standby gate via `scripts/aiready-standby-readiness-check.sh`
- Tally form structure and intake implementation (`aiready-intake-implementation-pack.md`)
- Tiered feedback strategy alignment (`AIReady-Tiered-Feedback-Strategy.md`)
- Mission register entry (`ops/MISSION-REGISTER.md`)
- Memory state (`MEMORY.md`)

## Integration rules

1. **Conflict resolution**: If any workspace file conflicts with the prompt kit, the kit wins.
2. **Kit is the prompt authority**: When Prime or any agent runs an audit, they load the kit files as the operational prompts. Workspace ops files describe the surrounding workflow (CRM, channels, state tracking) but do not override kit prompts.
3. **Agent handoffs**: The kit defines what each agent researches and returns. The workspace defines how tasks are dispatched (sessions_spawn, Discord routing, etc.).
4. **Tier integrity**: Tier parameters in the kit are the single source of truth for pricing, opportunity caps, research depth, deliverables, and support entitlements. The workspace delivery workflow must align to these.
5. **QA gate**: The kit's QA gate checklist (`09_QUALITY_GATE_CHECKLIST.md`) is mandatory before any report is delivered.
6. **Evidence vault**: The kit's evidence vault schema (`07_EVIDENCE_VAULT_SCHEMA.md`) is mandatory for all source records used in reports.
7. **Scoring**: The kit's scoring model (`06_SCORING_MODEL.md`) is the only scoring system. No ad-hoc scoring.

## Trigger flow (end-to-end)

```
Tally form submitted
  → Zoho CRM record updated (payment + intake confirmed)
  → Zoho trigger fires to Discord #mission-005-aiready-orders
  → Prime receives trigger
  → Prime loads kit: 00_PRIME_BOOT_AIREADY_INTAKE.md (identity)
  → Prime runs 01_TRIGGER_WORKFLOW.md (immediate procedure)
  → Prime runs 04_INTAKE_EXTRACTION_PROMPT.md (parse intake)
  → Prime classifies tier per 02_TIER_PARAMETERS.md
  → Prime dispatches agents per 03_AGENT_HANDOFFS.md
  → Agents research per 05_RESEARCH_ORCHESTRATOR_PROMPT.md
  → Evidence logged per 07_EVIDENCE_VAULT_SCHEMA.md
  → Opportunities scored per 06_SCORING_MODEL.md
  → Report generated per 10/11/12 (tier-specific prompt)
  → QA gate run per 09_QUALITY_GATE_CHECKLIST.md
  → Delivery email drafted per 14_CLIENT_DELIVERY_EMAIL_PROMPTS.md
  → Report delivered
  → Follow-up window opens (30 or 60 days per tier)
  → Archive per Archivist handoff
```

## File reference map

| Kit file | Workspace ops file it governs |
|---|---|
| `00_PRIME_BOOT_AIREADY_INTAKE.md` | Prime identity when in audit mode |
| `01_TRIGGER_WORKFLOW.md` | `ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md` (trigger section) |
| `02_TIER_PARAMETERS.md` | `ops/AIREADY-DELIVERY-WORKFLOW-AND-PACKS.md` (tier model) and `AIReady-Tiered-Feedback-Strategy.md` |
| `03_AGENT_HANDOFFS.md` | Agent dispatch in delivery workflow |
| `04_INTAKE_EXTRACTION_PROMPT.md` | `aiready-intake-implementation-pack.md` (intake parsing) |
| `05_RESEARCH_ORCHESTRATOR_PROMPT.md` | Research dispatch in delivery workflow |
| `06_SCORING_MODEL.md` | Scoring in delivery workflow |
| `07_EVIDENCE_VAULT_SCHEMA.md` | Evidence in delivery workflow |
| `08_REPORT_BLUEPRINTS.md` | Report structure in delivery workflow |
| `09_QUALITY_GATE_CHECKLIST.md` | QC step in delivery workflow |
| `10–12` (report prompts) | Report generation in delivery workflow |
| `13_ENTERPRISE_STAKEHOLDER_INTERVIEW_PROMPT.md` | Enterprise step in delivery workflow |
| `14_CLIENT_DELIVERY_EMAIL_PROMPTS.md` | Delivery step in delivery workflow |
| `15_AUDIT_RULES.yaml` | Machine-readable rules for all workspace ops files |

## Upgrade history

- 2026-04-24: Initial kit installed at `~/.openclaw/knowledge/aiready_audit/`
- 2026-07-14: Kit reconfirmed current (files identical to new download). This integration bridge created. Workspace ops files aligned to kit authority. AIReady reactivated from deferred to active mission state.
