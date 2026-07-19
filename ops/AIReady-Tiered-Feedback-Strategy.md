# AIReady Australia — Tiered Feedback Strategy

Date: 2026-04-23 AWST (aligned to prompt kit 2026-07-14)
Mission: AIReady Australia

## Authority

This strategy is governed by the AIReady Audit Prompt Kit.

- Tier parameters: `02_TIER_PARAMETERS.md` in the kit (authority)
- Scoring model: `06_SCORING_MODEL.md` in the kit (authority)
- Report blueprints: `08_REPORT_BLUEPRINTS.md` in the kit (authority)
- Audit rules: `15_AUDIT_RULES.yaml` in the kit (authority)

If this file conflicts with the kit, the kit wins.

See `ops/AIREADY-SYSTEM-INTEGRATION.md` for the full bridge.

## Scoring Dimensions

> Authoritative: `06_SCORING_MODEL.md` in the kit.

Each opportunity is scored 1–5 across six dimensions:

1. **Business Value** — minor convenience → major strategic/revenue/cost/capacity improvement
2. **Implementation Ease** — complex/multi-system change → easy, low-cost, fast
3. **Evidence Strength** — weak/speculative → strong evidence from official sources
4. **Data and Compliance Safety** — high-risk/sensitive data → low-risk/no sensitive data
5. **Team Readiness** — likely resistance/poor ownership → clear owner and acceptance
6. **90-Day Suitability** — not realistic in 90 days → realistic quick win

### Weighted Score

`Priority Score = (Business Value × 30%) + (Implementation Ease × 20%) + (Evidence Strength × 15%) + (Data Safety × 15%) + (Team Readiness × 10%) + (90-Day Suitability × 10%)`

### Classification Bands

- 4.25–5.00 = **Priority 1: implement first**
- 3.50–4.24 = **Priority 2: strong candidate**
- 2.75–3.49 = **Priority 3: plan or pilot later**
- 2.00–2.74 = **Watchlist**
- <2.00 = **Do not recommend now**

### Mandatory Fields Per Opportunity

- opportunity title
- problem solved
- client evidence from intake
- proposed AI/tool/process solution
- recommended owner
- estimated effort
- estimated cost band
- expected benefit
- risk flags
- required data
- human-review requirement
- implementation steps
- 90-day milestone
- evidence links
- priority score

## Feedback Tiers

### Starter Tier — $497

> Authoritative: `02_TIER_PARAMETERS.md` and `10_STARTER_REPORT_PROMPT.md` in the kit.

**Best for**: Sole traders and small teams (1–10 staff) needing a clear starting point.

**Research depth**: 10–15 sources, 6–10 tool checks, intake-led only.

**Deliverables**:
- Executive summary
- AI readiness score
- Top 3 opportunities
- Operations pain-point map
- Up to 8 prioritised opportunities
- Named tool recommendations with indicative pricing
- 90-day starter action plan
- Basic risk/readiness flags
- What not to do yet
- Sources and assumptions appendix

**No walkthrough call. No follow-up support unless separately sold.**

**Report prompt**: `10_STARTER_REPORT_PROMPT.md`

### Business Tier — $997

> Authoritative: `02_TIER_PARAMETERS.md` and `11_BUSINESS_REPORT_PROMPT.md` in the kit.

**Best for**: Growing businesses (10–50 staff) with operational complexity and multiple functions.

**Research depth**: 20–35 sources, 12–20 tool checks, expanded workflow research across sales/admin/customer service/reporting/finance/operations.

**Deliverables**:
- Executive summary
- AI readiness score
- Operations map
- Top 5 opportunities
- Up to 15 prioritised opportunities
- Effort vs impact matrix
- Tool recommendations with integration notes
- Cost-benefit estimates
- 90-day implementation plan
- Team readiness assessment
- Risk and privacy flags
- 1-hour walkthrough call agenda
- 30-day follow-up Q&A tracking notes
- Sources, assumptions, and scoring appendix

**Report prompt**: `11_BUSINESS_REPORT_PROMPT.md`

### Enterprise Tier — from $1,997

> Authoritative: `02_TIER_PARAMETERS.md` and `12_ENTERPRISE_REPORT_PROMPT.md` in the kit.

**Best for**: Larger, multi-location, compliance-sensitive, or integration-heavy businesses (50–200 staff).

**Research depth**: 40–75 sources, 20–35 vendor/tool checks, stakeholder interviews (up to 3), custom integration mapping, compliance review, vendor shortlisting.

**Deliverables**:
- Board/leadership one-page executive brief
- Comprehensive AI readiness report
- Complete opportunity register (no cap)
- Custom integration map
- Compliance and data privacy risk review
- Vendor shortlist with procurement scoring
- Governance and human-review recommendations
- Effort, value, risk, dependency, and sequencing model
- 90-day implementation roadmap plus 6–12 month strategic direction
- Stakeholder interview findings
- 2-hour walkthrough call agenda
- 60-day follow-up Q&A tracking notes
- Scoping call before audit begins
- Evidence vault, assumptions, risk register, and scoring appendix

**Report prompt**: `12_ENTERPRISE_REPORT_PROMPT.md`
**Stakeholder interview prompt**: `13_ENTERPRISE_STAKEHOLDER_INTERVIEW_PROMPT.md`

## Delivery emails

> Authoritative: `14_CLIENT_DELIVERY_EMAIL_PROMPTS.md` in the kit.

Each tier has a specific delivery email template. See the kit file for the exact prompts.

## Quality gate

> Authoritative: `09_QUALITY_GATE_CHECKLIST.md` in the kit.

Every report must pass the QA gate before delivery. This includes intake alignment, specificity, evidence, privacy/risk, and tier-specific delivery checks.
