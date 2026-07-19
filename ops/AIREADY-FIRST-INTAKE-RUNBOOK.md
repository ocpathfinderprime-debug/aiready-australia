# AIReady First Intake Runbook

Date: 2026-07-15 AWST
Mission: AIReady Australia pre-intake execution hardening

## Purpose

This runbook is the operator sequence for the first real AIReady intake.

Use it when a paid client intake is ready to start and Prime needs one clean path
from trigger receipt to report delivery without improvisation.

The AIReady Prompt Kit remains the authority. This file turns the kit plus
workspace workflow docs into one execution lane.

## Authority order

1. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/01_TRIGGER_WORKFLOW.md`
2. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/02_TIER_PARAMETERS.md`
3. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/03_AGENT_HANDOFFS.md`
4. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/06_SCORING_MODEL.md`
5. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/07_EVIDENCE_VAULT_SCHEMA.md`
6. `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/09_QUALITY_GATE_CHECKLIST.md`
7. `ops/AIREADY-SYSTEM-INTEGRATION.md`
8. `ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md`
9. `ops/AIREADY-DELIVERY-WORKFLOW-AND-PACKS.md`

## Trigger acceptance rule

Do not start the audit unless all of these are true:

- `payment_status = paid`
- `intake_status = complete`
- `audit_status = new`
- `prime_trigger_sent = false`
- package is one of `Starter`, `Business`, or `Enterprise`
- client name, business name, and primary email are present
- intake link or raw intake payload is available
- Zoho record id or equivalent order reference is present

If any one of those is missing:

- create `Client Clarification Required`
- record it in `00_Intake/client-clarification-required.md`
- log the exact missing field
- stop the audit start only for the missing blocking field

## Required inbound payload

Minimum live trigger payload:

- `client_name`
- `business_name`
- `email`
- `package_type`
- `payment_status`
- `stripe_payment_id`
- `intake_status`
- `tally_response_id`
- `intake_link`
- `zoho_record_id`
- `report_due_date`

Optional trigger payload fields:

- `notes`

## Client workspace layout

Create the client audit workspace at:

- `/Clients/{business_slug}/00_Intake/`
- `/Clients/{business_slug}/01_Evidence_Vault/`
- `/Clients/{business_slug}/02_Research/`
- `/Clients/{business_slug}/03_Scoring/`
- `/Clients/{business_slug}/04_Report_Draft/`
- `/Clients/{business_slug}/05_QA/`
- `/Clients/{business_slug}/06_Delivery/`

Minimum files to create on the first pass:

- `00_Intake/raw-intake.json`
- `00_Intake/redacted-working-intake.md`
- `00_Intake/intake-completeness-check.md`
- `00_Intake/client-clarification-required.md`
- `00_Intake/risk-flags.md`
- `00_Intake/trigger-and-activation-record.md`
- `02_Research/dispatch-log.md`
- `03_Scoring/opportunity-register.md`
- `05_QA/qa-gate-checklist.md`
- `06_Delivery/delivery-package-checklist.md`

Reusable starter pack:

- `templates/aiready-client-workspace/`
- `ops/AIREADY-ARTIFACT-NAMING-CONVENTION.md`
- `scripts/aiready-bootstrap-client-workspace.sh`
- `scripts/aiready-validate-trigger-contract.sh`
- `scripts/aiready-validate-readiness-snapshot.sh`
- `scripts/aiready-validate-order-trigger.sh`
- `scripts/aiready-validate-raw-intake.sh`
- `scripts/aiready-validate-client-workspace.sh`
- `scripts/aiready-validate-intake-activation-record.sh`
- `scripts/aiready-validate-research-dispatch.sh`
- `scripts/aiready-validate-evidence-capture.sh`
- `scripts/aiready-validate-scoring-pack.sh`
- `scripts/aiready-validate-report-draft.sh`
- `scripts/aiready-validate-delivery-email-draft.sh`
- `scripts/aiready-validate-delivery-package.sh`
- `scripts/aiready-validate-closeout-records.sh`
- `scripts/aiready-full-dry-run.sh`
- `scripts/aiready-tier-matrix-smoke.sh`
- `scripts/aiready-release-readiness-check.sh`
- `scripts/aiready-fail-closed-smoke.sh`
- `scripts/aiready-preflight-check.sh`
- `scripts/aiready-validate-direct-invocation.sh`
- `scripts/aiready-validate-doc-asset-links.sh`

Bootstrap command:

```bash
scripts/aiready-bootstrap-client-workspace.sh "Business Name"
```

Recommended local preflight command before the first live intake:

```bash
scripts/aiready-preflight-check.sh "Business Name"
```

Tier-matched variant:

```bash
scripts/aiready-preflight-check.sh "Business Name" <Starter|Business|Enterprise>
```

This preflight command validates the trigger contract docs, validates the Zoho
readiness gate snapshot, validates the exact trigger-message shape, creates a
disposable client workspace, validates the saved raw intake payload, validates
the generated workspace, validates the trigger-to-activation receipt, and
confirms duplicate-target protection before a live intake arrives.

Optional local guardrail rehearsal before the first live intake:

```bash
scripts/aiready-fail-closed-smoke.sh
```

This proves the local validators fail closed on blocking readiness, trigger,
and raw-intake problems instead of silently allowing a bad start.

End-to-end local dry run before the first live intake:

```bash
scripts/aiready-full-dry-run.sh "Business Name" <Starter|Business|Enterprise>
```

This runs the disposable rehearsal from trigger/readiness proof through bundle
and closeout validation without touching a live client workspace.

Tier-coverage rehearsal across all paid packages:

```bash
scripts/aiready-tier-matrix-smoke.sh
```

This proves the local first-intake lane works across `Starter`, `Business`, and
`Enterprise`, not just a single sample tier.

Single-command local release-readiness gate:

```bash
scripts/aiready-release-readiness-check.sh
```

This runs the direct-invocation guard, doc-to-script drift check, fail-closed
smoke, and tier-matrix smoke into one disposable evidence root for a human
readiness check.

Single-command sustained-readiness gate:

```bash
scripts/aiready-sustained-readiness-check.sh
```

This runs one fresh release-readiness pass and then validates the latest
release-readiness history window so the operator can prove both current
readiness and recent stability from one disposable evidence root.

Optional sustained-history audit across the latest clean sustained roots:

```bash
scripts/aiready-validate-sustained-readiness-history.sh
```

This validates the latest sustained-readiness roots as a separate stability
window so the operator can prove the sustained gate itself is no longer a
one-off pass.

Optional release-readiness history trend audit:

```bash
scripts/aiready-validate-release-readiness-history-trend.sh
```

This validates the newest release-readiness history audits as a trend packet so
the operator can prove the history-audit lane itself is staying consistent over
time.

Optional sustained-history trend audit:

```bash
scripts/aiready-validate-sustained-readiness-history-trend.sh
```

This validates the newest sustained-readiness history audits as a trend packet
so the operator can prove the sustained-history lane is also remaining stable
over time.

Single-command standby-for-first-intake gate:

```bash
scripts/aiready-standby-readiness-check.sh
```

This runs the sustained-readiness gate plus both history-trend audits into one
disposable evidence root so the operator can prove the full local standby lane
is green before the first real paid intake arrives.

Optional direct-invocation guardrail check before a live intake:

```bash
scripts/aiready-validate-direct-invocation.sh
```

This proves the current AIReady wrapper lane uses direct script invocation
rather than nested `bash ...` hops.

Optional doc-to-script drift check before a live intake:

```bash
scripts/aiready-validate-doc-asset-links.sh
```

This proves the current AIReady operator docs still point at real local
commands instead of stale script references.

## Execution sequence

### 1. Receive and validate trigger

- if the CRM readiness snapshot is copied into a local text file, validate it
  with:

```bash
scripts/aiready-validate-readiness-snapshot.sh /path/to/readiness-snapshot.txt
```

- confirm the trigger matches the Zoho readiness rule
- confirm the Discord trigger matches `ops/AIREADY-DISCORD-TRIGGER-TEMPLATE.md`
- if the trigger is copied into a local text file, validate it with:

```bash
scripts/aiready-validate-order-trigger.sh /path/to/order-trigger.txt
```

- confirm the tier against the paid package
- record the intake timestamp and order reference

### 2. Save source intake exactly as received

- save the raw intake without edits
- create a redacted working copy
- remove unnecessary personal data
- preserve business facts, workflow details, and constraints
- record the trigger and activation decision in
  `00_Intake/trigger-and-activation-record.md`
- validate the saved JSON payload with:

```bash
scripts/aiready-validate-raw-intake.sh /path/to/Clients/business-slug/00_Intake/raw-intake.json
```

- validate the trigger-to-activation receipt with:

```bash
scripts/aiready-validate-intake-activation-record.sh /path/to/Clients/business-slug
```

### 3. Run intake completeness and risk pass

- mark missing-but-non-blocking fields as assumptions
- mark blocking gaps as `Client Clarification Required`
- flag sensitive, regulated, or high-risk use cases for human review

### 4. Dispatch research lanes

Dispatch according to the prompt kit handoffs:

- `Signal` -> market, competitors, tools, vendors
- `Ops-Chief` -> workflow and bottleneck mapping
- `Build` -> systems and integration feasibility
- `Sentinel` -> privacy, risk, compliance, security
- `Strategy` -> scoring and prioritisation
- `Finance` -> ROI and cost-benefit logic
- `Growth` -> customer journey and sales uplift
- `Archivist` -> evidence vault and continuity

Validate the dispatch receipt after all lanes are routed:

```bash
scripts/aiready-validate-research-dispatch.sh /path/to/Clients/business-slug
```

### 5. Build the evidence vault and scoring set

- capture source-backed notes for each major claim
- separate verified evidence from assumptions
- build the ranked opportunity register
- score every candidate using the kit scoring model

Validate the evidence-capture set before drafting:

```bash
scripts/aiready-validate-evidence-capture.sh /path/to/Clients/business-slug
```

Validate the scoring pack before drafting:

```bash
scripts/aiready-validate-scoring-pack.sh /path/to/Clients/business-slug
```

### 6. Draft the report by tier

- `Starter` -> max 8 prioritised opportunities
- `Business` -> max 15 prioritised opportunities plus effort vs impact view
- `Enterprise` -> uncapped register plus integration map, privacy review, and stakeholder layer

Validate that the tier-relevant draft is populated and reflects the current scoring priorities with:

```bash
scripts/aiready-validate-report-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

### 7. Run QA gate before delivery

Use the full kit checklist and record the result in `05_QA/qa-gate-checklist.md`.

Do not deliver until:

- intake alignment is confirmed
- evidence coverage is complete
- privacy and risk flags are addressed
- tier-specific deliverables are present
- delivery email is prepared

Before final send, validate the QA gate and delivery checklist records:

```bash
scripts/aiready-validate-closeout-records.sh /path/to/Clients/business-slug
```

### 8. Prepare final delivery package

Minimum delivery bundle:

- final report
- executive summary or board brief if tier requires it
- delivery email draft
- evidence appendix for source/assumption support

Validate the delivery email draft before send with:

```bash
scripts/aiready-validate-delivery-email-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

Validate the delivery bundle before send with:

```bash
scripts/aiready-validate-delivery-package.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

Then validate the completed QA and delivery records:

```bash
scripts/aiready-validate-closeout-records.sh /path/to/Clients/business-slug
```

## Stop rules

Stop only for:

- unpaid order
- incomplete intake that blocks meaningful analysis
- missing order reference that prevents safe client tracking
- privacy or compliance risk requiring founder or human review
- broken access to the intake payload or required workspace path

Report any real stop as:

`Stopped because: <single exact blocker>`

## Proof of work for the first intake

Before claiming the first intake run is complete, capture:

- exact trigger payload received
- created client workspace path
- saved raw intake path
- dispatched research record
- completed QA record
- final delivery package path
- readback of the delivered artifact names

## Remaining mission gap after this runbook

The system is documentation-ready now.

The next proof target remains the same:

`first real intake -> full pipeline execution with evidence`
