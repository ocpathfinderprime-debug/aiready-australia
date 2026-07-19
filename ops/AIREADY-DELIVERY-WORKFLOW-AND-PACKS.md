# AIReady Australia — Delivery Workflow and Tiered Audit Outputs

Date: 2026-04-23 AWST (aligned to prompt kit 2026-07-14)
Mission: AIReady Australia

## Authority
This delivery workflow is governed by the AIReady Audit Prompt Kit at `~/.openclaw/knowledge/aiready_audit/oc_prime_aiready_audit_prompt_kit/`.

If this file conflicts with the kit, the kit wins.

See `ops/AIREADY-SYSTEM-INTEGRATION.md` for the full bridge.

## Purpose
Define what Prime does once a paid client submits the Tally intake form, and what each package returns in proportion to the price paid.

## Core operating rule
More expensive tiers must deliver materially more value, depth, specificity, and support.

That means the difference between tiers is not only page count.
It includes:
- deeper business analysis
- more opportunities identified
- stronger implementation detail
- more human/strategic support
- more follow-up guidance

## Intake-to-delivery workflow

> The authoritative trigger procedure is `01_TRIGGER_WORKFLOW.md` in the kit.
> The authoritative tier parameters are `02_TIER_PARAMETERS.md` in the kit.
> The authoritative agent handoffs are `03_AGENT_HANDOFFS.md` in the kit.
> The authoritative scoring model is `06_SCORING_MODEL.md` in the kit.
> The authoritative QA gate is `09_QUALITY_GATE_CHECKLIST.md` in the kit.
> The sections below are a summary; the kit files are the operating prompts.

### Step 1 — Confirm readiness
When the Tally form is received, verify:
- payment status = paid
- intake status = complete
- package type is known
- contact details are complete
- record is assigned to Prime

For local rehearsal before the first live intake, use:

```bash
scripts/aiready-preflight-check.sh "Business Name"
```

Tier-matched variant:

```bash
scripts/aiready-preflight-check.sh "Business Name" <Starter|Business|Enterprise>
```

This validates the trigger contract docs, bootstraps a disposable client
workspace, validates the saved raw intake payload, validates the generated
workspace, validates the trigger-to-activation receipt, and confirms
duplicate-target protection before a real intake arrives.

Optional negative-path guardrail rehearsal:

```bash
scripts/aiready-fail-closed-smoke.sh
```

End-to-end local rehearsal before the first live intake:

```bash
scripts/aiready-full-dry-run.sh "Business Name" <Starter|Business|Enterprise>
```

This now proves the research dispatch receipt and evidence-capture set as well
as the trigger, intake, draft, delivery, and closeout lane.

Tier-coverage rehearsal across all paid packages:

```bash
scripts/aiready-tier-matrix-smoke.sh
```

Single-command local release-readiness gate:

```bash
scripts/aiready-release-readiness-check.sh
```

This validates direct invocation across the AIReady wrapper chain, doc-to-script
drift, fail-closed behavior, and disposable tier coverage before a live intake
arrives.

Optional sustained-readiness gate:

```bash
scripts/aiready-sustained-readiness-check.sh
```

This adds a recent-history stability audit on top of the fresh
release-readiness pass so the operator can confirm the latest run is not a
one-off success.

Optional sustained-history audit:

```bash
scripts/aiready-validate-sustained-readiness-history.sh
```

This validates the newest sustained-readiness roots as a second-level stability
window, proving the sustained gate itself has passed across multiple recent
runs.

Optional release-readiness history trend audit:

```bash
scripts/aiready-validate-release-readiness-history-trend.sh
```

This validates the newest release-readiness history audits as a trend packet,
proving the history-audit lane itself is staying consistent over time.

Optional sustained-history trend audit:

```bash
scripts/aiready-validate-sustained-readiness-history-trend.sh
```

This validates the newest sustained-readiness history audits as a trend packet,
proving the sustained-history lane is also remaining stable over time.

Single-command standby-for-first-intake gate:

```bash
scripts/aiready-standby-readiness-check.sh
```

This bundles the sustained gate plus both history-trend audits into one
disposable proof root, so the operator can confirm the full local standby lane
is green before a real paid intake is allowed to trigger Prime.

Optional direct-invocation guardrail check:

```bash
scripts/aiready-validate-direct-invocation.sh
```

Optional doc-to-script drift check:

```bash
scripts/aiready-validate-doc-asset-links.sh
```

Before sending a live package, validate the final bundle:

```bash
scripts/aiready-validate-delivery-email-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

Then validate the final bundle:

```bash
scripts/aiready-validate-delivery-package.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

Then validate the completed QA and delivery records:

```bash
scripts/aiready-validate-closeout-records.sh /path/to/Clients/business-slug
```

Before finalising a tier output, validate that the tier-relevant report draft is populated and aligned to the scored priority summary:

```bash
scripts/aiready-validate-report-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise>
```

If anything is missing:
- hold
- log the missing item
- request correction before audit begins

### Step 2 — Parse the intake
Extract and structure the client’s:
- business model
- industry
- team size
- core services/products
- current tools/software
- major workflows
- biggest bottlenecks
- admin load
- sales/marketing process
- customer service process
- reporting/ops issues
- compliance/privacy concerns
- revenue drivers
- owner priorities

### Step 3 — Build the business operations map
Turn the intake into a working model of:
- front office
- back office
- sales pipeline
- customer journey
- team handoffs
- repetitive work
- decision bottlenecks
- reporting gaps

### Step 4 — Score AI readiness

> Authoritative scoring: `06_SCORING_MODEL.md` in the kit.
> Weighted score = (Business Value × 30%) + (Implementation Ease × 20%) + (Evidence Strength × 15%) + (Data Safety × 15%) + (Team Readiness × 10%) + (90-Day Suitability × 10%)
> Classification bands: 4.25–5.00 = P1, 3.50–4.24 = P2, 2.75–3.49 = P3, 2.00–2.74 = Watchlist, <2.00 = Do not recommend.

Assess the client across:
- workflow standardisation
- data quality
- tool maturity
- team adoption readiness
- automation potential
- ease of implementation
- expected ROI potential
- risk/compliance sensitivity

### Step 5 — Create the opportunity register

> Authoritative: `06_SCORING_MODEL.md` mandatory fields per opportunity.
> Each opportunity must include: title, problem solved, client evidence, proposed solution, recommended owner, estimated effort, estimated cost band, expected benefit, risk flags, required data, human-review requirement, implementation steps, 90-day milestone, evidence links, priority score.

Generate a ranked list of opportunities based on:
- impact
- implementation effort
- cost
- speed to value
- operational fit
- risk

### Step 6 — Tailor the output to the purchased package
The same core method is used across all tiers, but the depth, breadth, and support expand by package.

### Step 7 — Quality control

> Authoritative: `09_QUALITY_GATE_CHECKLIST.md` in the kit.
> Prime must run the full QA gate before delivery. This is non-negotiable.

Before delivery:
- remove weak/generic recommendations
- ensure recommendations match business reality
- check priority ordering
- confirm tool recommendations are relevant
- ensure the 90-day plan is actionable

### Step 8 — Deliver and move into follow-up state
Deliver according to package, then move the record to:
- report_ready
- delivered
- follow_up

## What Prime actually does with the Tally feedback
Prime does not simply summarize the form.
Prime converts the intake into:
1. a business operations model
2. a readiness/risk profile
3. a ranked AI opportunity register
4. a practical implementation sequence
5. package-matched outputs and support

## Tiered delivery model

> Authoritative: `02_TIER_PARAMETERS.md` in the kit.
> Report blueprints: `08_REPORT_BLUEPRINTS.md` in the kit.
> Report generation prompts: `10_STARTER_REPORT_PROMPT.md`, `11_BUSINESS_REPORT_PROMPT.md`, `12_ENTERPRISE_REPORT_PROMPT.md`.
> Delivery emails: `14_CLIENT_DELIVERY_EMAIL_PROMPTS.md`.

---

## 1) Starter Audit — $497

### Best for
Small operators who need a clear starting point fast.

### What Prime does
- parse the intake
- identify the most obvious high-value AI opportunities
- focus on quick wins and practical first moves
- keep complexity low

### What the client receives
- AI Readiness Report (PDF)
- up to 8 prioritised opportunities
- tool recommendations with pricing guidance
- 90-day starter action plan
- one-page executive summary
- basic readiness score / top issues

### Prime action list
- analyse intake
- map 3-5 critical workflows
- identify up to 8 opportunities
- estimate likely effort and value
- build a starter priority order
- produce report draft
- final quality check
- deliver report

### Expected value increase over free/general advice
- tailored to their business
- prioritised action sequence
- specific named tools
- practical starting roadmap

---

## 2) Business Audit — $997

### Best for
Businesses needing a stronger operational roadmap and implementation clarity.

### What Prime does
- analyse more of the business system end-to-end
- include more functions: ops, sales, finance, support, admin, team workflows
- compare quick wins vs larger leverage plays
- add clearer implementation guidance and integration thinking

### What the client receives
- AI Readiness Report (PDF)
- up to 15 prioritised opportunities
- full tool recommendations with integration notes
- effort vs impact matrix
- 90-day implementation plan
- 1-hour walkthrough call
- 30-day follow-up Q&A by email
- stronger prioritisation and sequencing

### Prime action list
- analyse intake in greater operational depth
- map end-to-end workflow structure across key departments
- identify up to 15 opportunities
- rank opportunities by value, effort, speed, and risk
- add integration notes and implementation dependencies
- build effort vs impact matrix
- draft 90-day phased plan
- prepare walkthrough agenda
- deliver report
- support follow-up Q&A window

### Extra value over Starter
- more opportunity depth
- broader business coverage
- clearer integration logic
- implementation sequencing
- walkthrough support
- follow-up support

---

## 3) Enterprise Audit

### Best for
Larger or more complex businesses needing strategic, stakeholder-aware, and risk-aware guidance.

### What Prime does
- assess the business at system level, not just workflow level
- include stakeholder interviews (up to 3)
- examine compliance/privacy and organisational readiness more seriously
- produce broader transformation roadmap and integration picture
- consider department-by-department rollout complexity

### What the client receives
- comprehensive questionnaire + stakeholder interviews
- full AI Readiness Report / opportunity register with no hard cap
- custom integration map
- compliance and data privacy risk review
- vendor shortlist
- 2-hour walkthrough call
- 60-day follow-up Q&A by email
- board / leadership summary
- pre-audit scoping call
- priority delivery within 5 business days

### Prime action list
- complete deep intake review
- plan and incorporate stakeholder interview findings
- build full operations and systems map
- identify full opportunity register
- create department/priority segmentation
- produce custom integration map
- review privacy/compliance and change risks
- produce vendor shortlist
- draft board summary
- prepare leadership walkthrough
- deliver report and follow-up support

### Extra value over Business
- interview-informed analysis
- deeper systems/integration design
- leadership-grade summary
- stronger risk/compliance treatment
- larger transformation view
- longer support window

---

## Internal delivery checklist after Tally submission

### For every client
- confirm package
- confirm payment/intake
- create structured intake summary
- create business operations map
- create readiness score
- create opportunity register
- create package-matched report
- quality check
- deliver
- log follow-up date

### Additional for Business tier
- add effort vs impact matrix
- add integration notes
- add walkthrough prep
- open 30-day follow-up window

### Additional for Enterprise tier
- schedule stakeholder interviews
- create integration architecture layer
- add privacy/compliance review
- create vendor shortlist
- create leadership summary
- open 60-day follow-up window

## What should trigger a hold instead of delivery
- payment not confirmed
- intake incomplete
- contradictory intake answers
- missing contact/business details
- package not clear
- scope suggests Enterprise-level needs but lower tier purchased and would materially limit quality

## Package integrity rule
Prime must not give Enterprise-level effort away for Starter pricing by default.
Each tier must feel clearly more valuable than the one below it.

> Enforced by `15_AUDIT_RULES.yaml` in the kit.

## Output standard
Every audit delivered should be:
- specific
- practical
- prioritised
- commercially relevant
- implementation-aware
- appropriate to the paid tier

## Recommended next system step
This delivery plan should be linked to the Zoho CRM workflow so package type determines:
- report template depth
- deliverable checklist
- follow-up window
- escalation path
