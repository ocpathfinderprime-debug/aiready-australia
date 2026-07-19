#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-full-dry-run.sh "Business Name" <Starter|Business|Enterprise> [report_root]

Runs a disposable local AIReady dry run from trigger/readiness rehearsal through
delivery bundle and closeout-record validation.
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

business_name="$1"
tier="$2"
report_root="${3:-}"
workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$tier" in
  Starter|Business|Enterprise) ;;
  *)
    echo "Invalid tier: $tier" >&2
    exit 1
    ;;
esac

slug="$(
  printf '%s' "$business_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
)"

if [[ -z "$slug" ]]; then
  echo "Could not derive a valid business slug from: $business_name" >&2
  exit 1
fi

if [[ -z "$report_root" ]]; then
  report_root="$workspace_root/reports/aiready-full-dry-run-$(date +%Y-%m-%d-%H%M-AWST)"
fi

preflight_script="$workspace_root/scripts/aiready-preflight-check.sh"
delivery_validator="$workspace_root/scripts/aiready-validate-delivery-package.sh"
delivery_email_validator="$workspace_root/scripts/aiready-validate-delivery-email-draft.sh"
closeout_validator="$workspace_root/scripts/aiready-validate-closeout-records.sh"
report_draft_validator="$workspace_root/scripts/aiready-validate-report-draft.sh"
activation_record_validator="$workspace_root/scripts/aiready-validate-intake-activation-record.sh"
research_dispatch_validator="$workspace_root/scripts/aiready-validate-research-dispatch.sh"
evidence_capture_validator="$workspace_root/scripts/aiready-validate-evidence-capture.sh"
scoring_pack_validator="$workspace_root/scripts/aiready-validate-scoring-pack.sh"
full_dry_run_report_validator="$workspace_root/scripts/aiready-validate-full-dry-run-report.sh"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

write_placeholder_pdf() {
  local path="$1"
  cat >"$path" <<'EOF'
%PDF-1.1
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Count 1 /Kids [3 0 R] >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF
EOF
}

require_file "$preflight_script"
require_file "$delivery_validator"
require_file "$delivery_email_validator"
require_file "$closeout_validator"
require_file "$report_draft_validator"
require_file "$activation_record_validator"
require_file "$research_dispatch_validator"
require_file "$evidence_capture_validator"
require_file "$scoring_pack_validator"
require_file "$full_dry_run_report_validator"

if [[ -e "$report_root" ]]; then
  echo "Report root already exists: $report_root" >&2
  exit 1
fi

mkdir -p "$report_root"

preflight_root="$report_root/preflight"
preflight_output="$report_root/preflight-output.txt"
delivery_validation_output="$report_root/delivery-package-validation.txt"
delivery_email_validation_output="$report_root/delivery-email-validation.txt"
closeout_validation_output="$report_root/closeout-record-validation.txt"
report_draft_validation_output="$report_root/report-draft-validation.txt"
activation_record_validation_output="$report_root/intake-activation-record-validation.txt"
research_dispatch_validation_output="$report_root/research-dispatch-validation.txt"
evidence_capture_validation_output="$report_root/evidence-capture-validation.txt"
scoring_pack_validation_output="$report_root/scoring-pack-validation.txt"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
full_dry_run_report_validation_output="$report_root/full-dry-run-report-validation.txt"

"$preflight_script" "$business_name" "$tier" "$preflight_root" | tee "$preflight_output"

workspace_path="$preflight_root/Clients/$slug"
dispatch_file="$workspace_path/02_Research/dispatch-log.md"
evidence_index_file="$workspace_path/01_Evidence_Vault/evidence-index.md"
sources_log_file="$workspace_path/01_Evidence_Vault/sources-log.md"
assumptions_register_file="$workspace_path/01_Evidence_Vault/assumptions-register.md"
opportunity_register_file="$workspace_path/03_Scoring/opportunity-register.md"
priority_summary_file="$workspace_path/03_Scoring/priority-summary.md"
draft_root="$workspace_path/04_Report_Draft"
delivery_root="$workspace_path/06_Delivery"
qa_file="$workspace_path/05_QA/qa-gate-checklist.md"
delivery_file="$delivery_root/delivery-package-checklist.md"
delivery_email_file="$delivery_root/${slug}-delivery-email-draft.md"
starter_draft_file="$draft_root/${slug}-aiready-starter-report-draft.md"
business_draft_file="$draft_root/${slug}-aiready-business-report-draft.md"
enterprise_draft_file="$draft_root/${slug}-aiready-enterprise-report-draft.md"

priority_1="Intake activation and routing"
priority_2="Workflow reporting visibility"
priority_3="Guardrailed delivery checklist"
watchlist_item="deeper integrations after live evidence"
sample_client_name="Sample Client"
sample_client_email="sample.client@example.com"
sample_delivery_date="2026-07-16"
sample_delivery_owner="Prime"

write_placeholder_pdf "$delivery_root/${slug}-aiready-report-final.pdf"

supporting_files="$delivery_root/${slug}-evidence-appendix.pdf"
write_placeholder_pdf "$delivery_root/${slug}-evidence-appendix.pdf"

deliverable_1="$priority_1"
deliverable_2="$priority_2"
deliverable_3="90-day implementation plan"
top_next_step="Start with $priority_1 and confirm owners against the 90-day plan."
risk_or_assumption_note="Validate live intake and routing evidence before scaling deeper integrations."
email_follow_up_note="Reply if you want implementation help after reviewing the report."
attachment_3=""
attachment_4=""
follow_up_window="No included follow-up support"
follow_up_due="not scheduled - starter tier has no included follow-up"

case "$tier" in
  Starter)
    write_placeholder_pdf "$delivery_root/${slug}-executive-summary.pdf"
    supporting_files="$supporting_files, $delivery_root/${slug}-executive-summary.pdf"
    deliverable_1="Top 3 AI opportunities"
    deliverable_2="Executive summary"
    deliverable_3="90-day starter action plan"
    email_follow_up_note="No walkthrough call or follow-up support is included unless separately purchased."
    attachment_3="$delivery_root/${slug}-executive-summary.pdf"
    ;;
  Business)
    deliverable_1="Top 5 opportunity themes"
    deliverable_2="Effort vs impact view"
    deliverable_3="90-day implementation plan"
    email_follow_up_note="A 30-day Q&A by email is included after delivery."
    follow_up_window="30-day Q&A by email"
    follow_up_due="2026-08-15"
    ;;
  Enterprise)
    write_placeholder_pdf "$delivery_root/${slug}-board-brief.pdf"
    write_placeholder_pdf "$delivery_root/${slug}-integration-map.pdf"
    supporting_files="$supporting_files, $delivery_root/${slug}-board-brief.pdf, $delivery_root/${slug}-integration-map.pdf"
    deliverable_1="Leadership summary and board brief"
    deliverable_2="Custom integration map"
    deliverable_3="Priority governance and privacy flags"
    email_follow_up_note="A 60-day follow-up Q&A is included after delivery."
    follow_up_window="60-day Q&A by email"
    follow_up_due="2026-09-14"
    attachment_3="$delivery_root/${slug}-board-brief.pdf"
    attachment_4="$delivery_root/${slug}-integration-map.pdf"
    ;;
esac

cat >"$qa_file" <<EOF
# QA Gate Checklist

## QA metadata

- Business: $business_name
- Tier: $tier
- Reviewer: Prime
- Review date: 2026-07-16

## Intake alignment

- [x] Paid tier confirmed
- [x] Client metadata correct
- [x] All form answers reviewed
- [x] Weak or missing inputs handled
- [x] Report matches tier promise

## Specificity

- [x] No generic AI advice
- [x] Every recommendation ties to intake evidence
- [x] Every opportunity has owner, effort, value, risk, and next action
- [x] Tools are named and relevant

## Evidence

- [x] Evidence vault completed
- [x] Top recommendations supported by evidence or labelled as assumptions
- [x] Pricing checked where included
- [x] No unsupported ROI guarantee
- [x] Claims not overstated

## Privacy and risk

- [x] Sensitive data flagged
- [x] Public AI tool risks considered
- [x] Human review requirements included
- [x] Data retention and sharing risks noted
- [x] High-risk automations not recommended without controls

## Tier-specific delivery

- [x] Tier-specific deliverables present
- [x] Tier cap or tier scope respected

## Final human review

- [x] Reads like a paid professional audit
- [x] No internal prompt text leaked
- [x] No private notes leaked
- [x] File naming correct
- [x] Delivery email prepared

## QA result

- Status: pass
- Reviewer: Prime
- Timestamp: 2026-07-16-1824-AWST
- Rework required: none
- Release decision: approved for delivery
EOF

cat >"$dispatch_file" <<EOF
# Dispatch Log

## Intake context

- Business: $business_name
- Tier: $tier
- Zoho record id: zoho_$slug
- Tally response id: tally_$slug
- Dispatch started at: 2026-07-16-0005-AWST
- Dispatch owner: Prime

## Research lanes

- [x] Signal dispatched
- [x] Ops-Chief dispatched
- [x] Build dispatched
- [x] Sentinel dispatched
- [x] Strategy dispatched
- [x] Finance dispatched
- [x] Growth dispatched
- [x] Archivist dispatched

## Dispatch receipts

| Lane | Dispatched at | Route/session | Scope sent | Return due | Status |
|---|---|---|---|---|---|
| Signal | 2026-07-16-0006-AWST | local-sample-signal | market, competitors, tools | 2026-07-16-0036-AWST | returned |
| Ops-Chief | 2026-07-16-0007-AWST | local-sample-ops-chief | workflows, bottlenecks, sequencing | 2026-07-16-0037-AWST | returned |
| Build | 2026-07-16-0008-AWST | local-sample-build | systems, integrations, feasibility | 2026-07-16-0038-AWST | returned |
| Sentinel | 2026-07-16-0009-AWST | local-sample-sentinel | privacy, compliance, risk | 2026-07-16-0039-AWST | returned |
| Strategy | 2026-07-16-0010-AWST | local-sample-strategy | scoring, prioritisation | 2026-07-16-0040-AWST | returned |
| Finance | 2026-07-16-0011-AWST | local-sample-finance | roi, cost-benefit | 2026-07-16-0041-AWST | returned |
| Growth | 2026-07-16-0012-AWST | local-sample-growth | customer journey, sales uplift | 2026-07-16-0042-AWST | returned |
| Archivist | 2026-07-16-0013-AWST | local-sample-archivist | evidence vault, continuity | 2026-07-16-0043-AWST | returned |

## Return status

- Signal: received and logged
- Ops-Chief: received and logged
- Build: received and logged
- Sentinel: received and logged
- Strategy: received and logged
- Finance: received and logged
- Growth: received and logged
- Archivist: received and logged

## Notes

- Sample dry-run dispatch receipt.

## Verification

- All required lanes dispatched: yes
- Missing lanes: none
- Next coordination step: consolidate returns into evidence vault and scoring set
EOF

cat >"$workspace_path/02_Research/signal-return.md" <<EOF
# Signal Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Signal
- Returned at: 2026-07-16-0020-AWST

## Scope

- Market context: demand favors practical automation wins
- Competitor context: peers promote faster response and better reporting
- Tool and vendor findings: mainstream scheduling, crm, and automation tools fit

## Evidence-backed findings

- Finding 1: response-time improvement is a visible market expectation
- Finding 2: comparable operators market workflow automation as a differentiator
- Finding 3: the current tier can support an incremental tool rollout

## Market signal summary

- Market pattern: buyers expect faster admin turnaround
- Competitive benchmark: peers highlight reduced manual follow-up
- Best-fit tools/vendors: crm, form automation, reporting stack

## Sources

- Source 1: SRC-001
- Source 2: SRC-002

## Recommendations

- Recommendation 1: prioritise lead-response automation
- Recommendation 2: add lightweight reporting visibility first
EOF

cat >"$workspace_path/02_Research/ops-chief-return.md" <<EOF
# Ops-Chief Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Ops-Chief
- Returned at: 2026-07-16-0021-AWST

## Scope

- Workflow map: intake to delivery handoffs
- Bottlenecks: manual triage and status chasing
- Sequencing notes: automate intake before deeper system changes

## Findings

- Finding 1: repeated handoff checks create avoidable delay
- Finding 2: intake validation should happen before downstream routing

## Workflow detail

- Highest-friction workflow: intake to dispatch
- Main handoff failures: missing status checkpoints
- Fastest operational win: standardise intake activation

## Automation candidates

- Candidate 1: intake activation receipt
- Candidate 2: dispatch visibility summary
EOF

cat >"$workspace_path/02_Research/build-return.md" <<EOF
# Build Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Build
- Returned at: 2026-07-16-0022-AWST

## Scope

- Software stack: current AIReady workspace lane
- Integration paths: trigger -> intake -> research -> report -> delivery
- Feasibility notes: staged validation is locally feasible

## Findings

- Finding 1: current scripts cover the major intake and delivery boundaries
- Finding 2: evidence capture is manageable with lightweight markdown receipts

## Feasibility detail

- Recommended integration path: keep local file-backed proof lane
- Dependencies: existing shell validators
- Change effort: low to moderate

## Risks

- Risk 1: stale operator files can reintroduce drift
- Risk 2: missing live payload remains an external dependency
EOF

cat >"$workspace_path/02_Research/sentinel-return.md" <<EOF
# Sentinel Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Sentinel
- Returned at: 2026-07-16-0023-AWST

## Scope

- Privacy: only minimum sample data used locally
- Compliance: human review remains required for sensitive cases
- Security: local rehearsal lane only
- Human review: required before live regulated recommendations

## Risk flags

- Risk 1: overclaiming evidence without source refs
- Risk 2: live customer data requires stricter handling than samples

## Review boundaries

- Human review required for: regulated or sensitive automations
- Data sensitivity notes: keep personal data minimized
- Tool restrictions: do not treat local readiness as approval for external writes

## Guardrails

- Guardrail 1: mark assumptions explicitly
- Guardrail 2: keep evidence linked to sources
EOF

cat >"$workspace_path/02_Research/strategy-return.md" <<EOF
# Strategy Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Strategy
- Returned at: 2026-07-16-0024-AWST

## Scope

- Prioritisation: quick wins first
- Dependency mapping: intake proof before delivery polish
- 90-day suitability: near-term operational wins are strongest

## Ranked conclusions

- Conclusion 1: automate intake validation first
- Conclusion 2: expose research and evidence checkpoints early

## Strategic sequencing

- Implement first: intake and dispatch proof
- Defer until later: broader integrations after live evidence
- Blockers to remove first: arrival of the first paid intake

## Priority rationale

- Rationale 1: early proof reduces downstream errors
- Rationale 2: visible evidence improves trust in recommendations
EOF

cat >"$workspace_path/02_Research/finance-return.md" <<EOF
# Finance Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Finance
- Returned at: 2026-07-16-0025-AWST

## Scope

- Time saved: reduced admin rework
- Tool costs: low starter-cost workflow tools
- Implementation cost band: low to medium
- ROI assumptions: faster handling and lower manual effort

## Findings

- Finding 1: simple automation wins likely produce the fastest payback
- Finding 2: reporting visibility supports prioritised follow-up

## Cost-benefit detail

- Fastest ROI opportunity: intake validation and routing
- Highest-value opportunity: workflow reporting visibility
- Assumptions affecting economics: stable intake volume

## Cost-benefit notes

- Note 1: avoid promising hard ROI guarantees
- Note 2: keep assumptions visible in the report
EOF

cat >"$workspace_path/02_Research/growth-return.md" <<EOF
# Growth Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Growth
- Returned at: 2026-07-16-0026-AWST

## Scope

- Lead response: quicker first response
- Sales workflow: less manual follow-up
- Customer journey: clearer handoffs
- Retention opportunities: smoother delivery and follow-up

## Findings

- Finding 1: lead-response speed is a visible growth lever
- Finding 2: follow-up consistency supports retention

## Customer journey detail

- Pre-sale friction: slow or inconsistent contact
- Post-sale friction: unclear status transitions
- Conversion or retention lift candidates: response and delivery visibility

## Customer-facing opportunities

- Opportunity 1: auto-acknowledged intake progression
- Opportunity 2: cleaner delivery handoff communication
EOF

cat >"$workspace_path/02_Research/archivist-return.md" <<EOF
# Archivist Return

## Return metadata

- Business: $business_name
- Tier: $tier
- Returned by: Archivist
- Returned at: 2026-07-16-0027-AWST

## Scope

- Source capture: evidence refs and assumptions
- Citation trail: SRC and ASM ids
- Versioning: current dry-run files only
- Assumptions continuity: isolated and reviewable

## Findings

- Finding 1: evidence surfaces are present for all main lanes
- Finding 2: assumption tracking is needed for incomplete live data

## Evidence assets

- Key artifacts: evidence index, sources log, assumptions register
- File references: 01_Evidence_Vault/*
- Continuity notes: keep receipts with the client workspace

## Archive notes

- Archive action 1: preserve current lane receipts
- Archive action 2: update evidence links after live intake
EOF

cat >"$evidence_index_file" <<EOF
# Evidence Index

## Client

- Business: $business_name
- Client: Sample Client
- Tier: $tier
- Audit start: 2026-07-16-0000-AWST
- Evidence owner: Archivist

## Evidence groups

- Intake evidence: raw intake, completeness check, activation receipt
- Market and vendor evidence: signal return plus source refs
- Workflow evidence: ops-chief return and dispatch log
- Integration evidence: build return and current scripts
- Privacy and risk evidence: sentinel return
- ROI and cost evidence: finance return

## Top recommendation evidence links

| Opportunity | Evidence refs | Notes |
|---|---|---|
| $priority_1 | SRC-001, SRC-002, /02_Research/ops-chief-return.md | grounded in intake and workflow findings |
| $priority_2 | SRC-002, /02_Research/build-return.md, /02_Research/finance-return.md | grounded in workflow visibility, delivery timing, and ROI notes |
| $priority_3 | SRC-001, /02_Research/sentinel-return.md, /02_Research/archivist-return.md | grounded in delivery controls, review boundaries, and evidence discipline |

## Coverage check

- All major claims have evidence or are marked as assumptions: yes
- Tier-critical recommendations have source coverage: yes
- Evidence gaps still open: none in dry run
EOF

cat >"$sources_log_file" <<EOF
# Sources Log

## Log metadata

- Business: $business_name
- Tier: $tier
- Maintained by: Archivist

## Source entries

| ID | Type | Source | Date checked | Supports | Notes |
|---|---|---|---|---|---|
| SRC-001 | client-intake | raw intake payload | 2026-07-16 | intake activation recommendation | sample dry-run input |
| SRC-002 | workflow-analysis | ops-chief return | 2026-07-16 | dispatch and handoff recommendations | local rehearsal artifact |

## Source quality notes

- Official/vendor sources: not required for this dry-run sample
- Client-provided sources: sample intake payload only
- Cross-checks completed: intake receipt aligned with research returns
EOF

cat >"$assumptions_register_file" <<EOF
# Assumptions Register

## Register metadata

- Business: $business_name
- Tier: $tier
- Owner: Strategy
- Last updated: 2026-07-16-0028-AWST

## Assumptions

| ID | Assumption | Reason needed | Risk if wrong | Resolution path |
|---|---|---|---|---|
| ASM-001 | intake volume is stable enough for lightweight automation | dry run has no live production volume data | automation priority may shift | confirm after first paid intake |

## Verification

- High-risk assumptions isolated: yes
- Items requiring client clarification: none in dry run
- Items requiring human review: regulated workflows if discovered live
EOF

cat >"$opportunity_register_file" <<EOF
# Opportunity Register

## Scoring model

Use the authoritative AIReady Prompt Kit scoring model.

## Register metadata

- Business: $business_name
- Tier: $tier
- Register owner: Strategy
- Last updated: 2026-07-16-0029-AWST

## Opportunities

| ID | Opportunity | Problem Solved | Client Evidence | Proposed Solution | Owner | Effort | Cost Band | Expected Benefit | Risk Flags | Required Data | Human Review | Priority Score | 90-Day Milestone | Evidence Links |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | $priority_1 | slow intake handling | raw intake plus dispatch findings | standardise intake activation and routing | Ops-Chief | low | low | faster intake progression | low | intake metadata | no | 4.6 | activation receipt live in week 1 | SRC-001, SRC-002 |
| 2 | $priority_2 | unclear progress status | dispatch log and ops workflow notes | add lightweight reporting visibility | Build | medium | low | fewer follow-up gaps | low | workflow timestamps | no | 4.1 | reporting checkpoints in month 1 | SRC-002 |
| 3 | $priority_3 | delivery inconsistency risk | qa and delivery surfaces | enforce delivery gates before send | Prime | low | low | safer final delivery | medium | final report artifacts | yes - final human review | 3.8 | delivery gate locked in month 2 | SRC-001 |

## Priority notes

- Priority 1: $priority_1
- Priority 2: $priority_2
- Priority 3: $priority_3
- Watchlist: $watchlist_item
- Do not recommend now: high-risk automation without real client proof

## Assumptions

- Assumption 1: intake volume justifies lightweight automation first
- Assumption 2: current workflow pain is mainly handoff visibility

## Coverage check

- Tier cap respected: yes
- All opportunities have evidence: yes
- All opportunities have owner, effort, cost, risk, and milestone: yes
EOF

cat >"$priority_summary_file" <<EOF
# Priority Summary

## Summary metadata

- Business: $business_name
- Tier: $tier
- Prepared by: Strategy
- Updated at: 2026-07-16-0030-AWST

## Priority 1

- Opportunity: $priority_1
- Why first: fastest path to reducing intake friction

## Priority 2

- Opportunity: $priority_2
- Why next: improves coordination after intake is stabilised

## Priority 3

- Opportunity: $priority_3
- Why later: builds on validated upstream flow

## Watchlist / not now

- Item: $watchlist_item
- Why deferred: requires proof from the first real paid intake

## Decision notes

- Recommended first 90-day sequence: activation receipt -> dispatch visibility -> delivery hardening
- Dependencies or blockers: first real paid intake still pending
- Human-review items: final delivery and any sensitive automation recommendation
EOF

cat >"$starter_draft_file" <<EOF
# AIReady Starter Report Draft

## Client

- Business: $business_name
- Tier: Starter
- Client: Sample Client
- Zoho record id: zoho_$slug
- Draft owner: Prime
- Draft date: 2026-07-16

## Executive summary

- Business context: sample dry run for the first-intake readiness lane
- Top readiness finding: the fastest lift comes from standardising intake activation before deeper automation
- Best first move: implement $priority_1

## Readiness snapshot

- Overall readiness: moderate and suitable for staged rollout
- Top constraints: no live paid intake yet and limited production evidence
- What to do first: lock intake activation and routing
- What not to do yet: broad high-risk automation without live evidence

## Operations pain-point map

- Workflow 1: intake to dispatch handoff has avoidable delay
- Workflow 2: research coordination needs clearer visibility
- Workflow 3: final delivery should stay behind explicit gates

## Top opportunities

- Opportunity 1: $priority_1
- Opportunity 2: $priority_2
- Opportunity 3: $priority_3

## Prioritised opportunity list

1. $priority_1
2. $priority_2
3. $priority_3
4. confirm live intake evidence before deeper integrations
5. keep qa and delivery approvals explicit
6. preserve source links in the evidence vault
7. track human-review boundaries for sensitive recommendations
8. expand automation only after first-intake proof

## Tool recommendations

- Tool: lightweight forms, routing, and reporting stack
- Indicative pricing: low to moderate monthly software spend
- Why it fits: supports a staged rollout with low operational risk

## 90-day starter plan

- Days 0-30: launch $priority_1 and capture live intake proof
- Days 31-60: add $priority_2 with visible checkpoints
- Days 61-90: tighten $priority_3 and prepare the next wave

## Sources and assumptions appendix

- Verified sources: SRC-001, SRC-002, local dry-run research returns
- Assumptions: intake volume remains stable and main friction is handoff visibility

## Risks and assumptions

- Main risks: overfitting to sample data and introducing automation before live proof
- Main assumptions: the first live intake confirms current prioritisation
EOF

cat >"$business_draft_file" <<EOF
# AIReady Business Report Draft

## Client

- Business: $business_name
- Tier: Business
- Client: Sample Client
- Zoho record id: zoho_$slug
- Draft owner: Prime
- Draft date: 2026-07-16

## Executive summary

- Business context: the business lane benefits most from a staged operations-first rollout
- Top readiness finding: upstream intake and workflow visibility will unlock cleaner downstream delivery
- Best 90-day direction: sequence $priority_1, then $priority_2, then $priority_3

## Readiness snapshot

- Overall readiness: moderate with strong short-term execution potential
- Main leverage areas: intake standardisation, reporting visibility, delivery control
- Main constraints: live intake evidence is not yet available

## Operations map

- Front office: lead and intake handling need faster acknowledgement
- Back office: dispatch and evidence capture need clearer receipts
- Reporting: status visibility should be lightweight and reliable
- Handoffs: transitions between intake, research, and delivery are the main friction

## Top opportunities

- Opportunity 1: $priority_1
- Opportunity 2: $priority_2
- Opportunity 3: $priority_3
- Opportunity 4: evidence-vault source discipline
- Opportunity 5: follow-up walkthrough preparation

## Prioritised opportunity list

1. $priority_1
2. $priority_2
3. $priority_3
4. evidence-vault source discipline
5. follow-up walkthrough preparation
6. stable handoff checklists
7. role-based ownership for recommendations
8. reporting checkpoints for open work
9. assumptions isolation for uncertain data
10. safe tool onboarding path
11. escalation rules for sensitive workflows
12. implementation sequencing notes
13. human-review gates for client-facing outputs
14. post-delivery follow-up cadence
15. next-wave integration shortlist after live proof

## Effort vs impact view

- Quick wins: $priority_1 and $priority_3
- Medium-lift leverage plays: $priority_2
- Higher-complexity strategic plays: deeper integrations after live evidence

## Tool and integration notes

- Tool: workflow routing plus reporting stack
- Integration dependency: intake metadata and timestamp capture
- Change risk: moderate if upstream data quality drifts

## 90-day implementation plan

- Days 0-30: implement $priority_1 and confirm receipt quality
- Days 31-60: deploy $priority_2 with visible coordination checkpoints
- Days 61-90: formalise $priority_3 and package the next-wave roadmap

## Walkthrough and follow-up prep

- Walkthrough agenda: review priorities, proof, constraints, and 90-day rollout
- 30-day Q&A notes: confirm live findings before expanding automation scope

## Risks and assumptions

- Main risks: stale sample assumptions and overcommitting before live client proof
- Main assumptions: current operational bottlenecks stay centred on intake and visibility
EOF

cat >"$enterprise_draft_file" <<EOF
# AIReady Enterprise Report Draft

## Client

- Business: $business_name
- Tier: Enterprise
- Client: Sample Client
- Zoho record id: zoho_$slug
- Draft owner: Prime
- Draft date: 2026-07-16

## Leadership summary

- Business context: enterprise readiness hinges on proving low-risk operational wins before broad transformation
- Transformation case: staged proof lowers governance risk while building internal confidence
- Highest-priority decision: approve $priority_1 as the first controlled move

## Stakeholder and system context

- Stakeholder interviews completed: not applicable in dry run, required in live enterprise lane
- Core business systems: intake capture, routing, reporting, and delivery controls
- Compliance or privacy constraints: sensitive automations require explicit human review

## Opportunity register summary

- Highest-value opportunities: $priority_1 and $priority_2
- Highest-confidence opportunities: $priority_1
- Deferred opportunities: $watchlist_item

## Priority segmentation

- Priority 1: $priority_1
- Priority 2: $priority_2
- Priority 3: $priority_3
- Watchlist: $watchlist_item

## Integration and governance notes

- Integration architecture notes: keep the first rollout file-backed and proof-oriented
- Governance controls: evidence links, qa gate, and delivery sign-off remain mandatory
- Human-review boundaries: privacy-sensitive and regulated recommendations stay human-reviewed

## Vendor shortlist

- Vendor: intake, workflow, and reporting stack shortlist
- Why shortlisted: supports staged delivery without heavy upfront integration cost
- Key caveat: final selection depends on live system and compliance details

## 90-day and strategic roadmap

- Days 0-30: prove $priority_1 on a live intake
- Days 31-60: add $priority_2 and validate coordination gains
- Days 61-90: operationalise $priority_3 across delivery lanes
- 6-12 month direction: revisit deeper integrations after evidence accumulates

## Board brief and follow-up prep

- Board brief status: ready for controlled post-intake refinement
- 60-day Q&A notes: confirm governance posture before scaling automation depth

## Risks and assumptions

- Main risks: governance drift, stale assumptions, and overreach before live proof
- Main assumptions: the first paid intake confirms present scoring priorities
EOF

cat >"$delivery_file" <<EOF
# Delivery Package Checklist

## Delivery identity

- Business: $business_name
- Client: $sample_client_name
- Tier: $tier
- Zoho record id: zoho_$slug

## Delivery bundle

- [x] Final report file ready
- [x] Executive summary or board brief included if tier requires it
- [x] Delivery email draft ready
- [x] Evidence or assumptions appendix included if needed

## Delivery metadata

- Client: $sample_client_name
- Tier: $tier
- Delivery date: $sample_delivery_date
- Delivery channel: email

## Follow-up state

- Follow-up window: $follow_up_window
- Follow-up due: $follow_up_due
- Owner: $sample_delivery_owner

## Final artifact paths

- Report: /Clients/$slug/06_Delivery/${slug}-aiready-report-final.pdf
- Email draft: /Clients/$slug/06_Delivery/${slug}-delivery-email-draft.md
- Supporting files: $supporting_files

## Verification

- Tier-specific deliverables checked: yes
- File names checked against naming convention: yes
- Final handoff ready: yes
EOF

cat >"$delivery_email_file" <<EOF
# Delivery Email Draft

## Client

- Business: $business_name
- Client: $sample_client_name
- Email: $sample_client_email
- Tier: $tier
- Zoho record id: zoho_$slug
- Delivery owner: $sample_delivery_owner
- Delivery date: $sample_delivery_date

## Subject

- AIReady Australia Audit Delivery - $business_name

## Email body

Hi $sample_client_name,

Thank you for completing your AIReady Australia audit for $business_name.

Attached is your $tier AI Readiness Report for $business_name.

What is included:

- $deliverable_1
- $deliverable_2
- $deliverable_3

Top next step:

- $top_next_step

Important notes:

- $risk_or_assumption_note
- $email_follow_up_note
EOF

case "$tier" in
  Starter)
    cat >>"$delivery_email_file" <<EOF

If you would like implementation help after reading the report, reply and we can scope that separately.
EOF
    ;;
  Business)
    cat >>"$delivery_email_file" <<EOF

Please review the 90-day implementation plan before the walkthrough call.
Reply with your preferred times to book the 1-hour walkthrough call.
EOF
    ;;
  Enterprise)
    cat >>"$delivery_email_file" <<EOF

Please reply with your preferred times to book the 2-hour walkthrough.
Please let us know who should attend the 2-hour walkthrough.
EOF
    ;;
esac

cat >>"$delivery_email_file" <<EOF

If you have questions, reply to this email and we will guide the next step.

Regards,

Prime
AIReady Australia

## Attachments

- Attachment 1: ${slug}-aiready-report-final.pdf
- Attachment 2: ${slug}-evidence-appendix.pdf
EOF

if [[ -n "$attachment_3" ]]; then
  cat >>"$delivery_email_file" <<EOF
- Attachment 3: $(basename "$attachment_3")
EOF
fi

if [[ -n "$attachment_4" ]]; then
  cat >>"$delivery_email_file" <<EOF
- Attachment 4: $(basename "$attachment_4")
EOF
fi

cat >>"$delivery_email_file" <<EOF

## Send check

- Tier-specific attachments present: yes
- Naming checked: yes
- Follow-up expectation stated: yes
EOF

"$report_draft_validator" "$workspace_path" "$tier" "$slug" | tee "$report_draft_validation_output"
"$activation_record_validator" "$workspace_path" "$slug" | tee "$activation_record_validation_output"
"$research_dispatch_validator" "$workspace_path" | tee "$research_dispatch_validation_output"
"$evidence_capture_validator" "$workspace_path" | tee "$evidence_capture_validation_output"
"$scoring_pack_validator" "$workspace_path" | tee "$scoring_pack_validation_output"
"$delivery_email_validator" "$workspace_path" "$tier" "$slug" | tee "$delivery_email_validation_output"
"$delivery_validator" "$workspace_path" "$tier" | tee "$delivery_validation_output"
"$closeout_validator" "$workspace_path" "$slug" | tee "$closeout_validation_output"

cat >"$summary_readme" <<EOF
# AIReady Full Dry Run

- Report root: \`$report_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`
- Business: \`$business_name\`
- Business slug: \`$slug\`
- Tier: \`$tier\`
- Workspace path: \`$workspace_path\`

## Validation receipts

- Preflight output: [preflight-output.txt](./preflight-output.txt)
- Report draft: [report-draft-validation.txt](./report-draft-validation.txt)
- Intake activation record: [intake-activation-record-validation.txt](./intake-activation-record-validation.txt)
- Research dispatch: [research-dispatch-validation.txt](./research-dispatch-validation.txt)
- Evidence capture: [evidence-capture-validation.txt](./evidence-capture-validation.txt)
- Scoring pack: [scoring-pack-validation.txt](./scoring-pack-validation.txt)
- Delivery email: [delivery-email-validation.txt](./delivery-email-validation.txt)
- Delivery package: [delivery-package-validation.txt](./delivery-package-validation.txt)
- Closeout records: [closeout-record-validation.txt](./closeout-record-validation.txt)
- Full dry-run report validation: [full-dry-run-report-validation.txt](./full-dry-run-report-validation.txt)

## Evidence roots

- Preflight root: [preflight/](./preflight/)
- Preflight summary: [preflight/README.md](./preflight/README.md)
- Preflight manifest: [preflight/manifest.json](./preflight/manifest.json)
- Preflight report validation: [preflight/preflight-report-validation.txt](./preflight/preflight-report-validation.txt)
- Client workspace root: [preflight/Clients/](./preflight/Clients/)

## Outcome

This run proves the disposable AIReady lane can move from preflight through
draft, delivery bundle, and closeout validation for the selected paid tier.
EOF

cat >"$summary_manifest" <<EOF
{
  "report_root": "$report_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "business_name": "$business_name",
  "business_slug": "$slug",
  "tier": "$tier",
  "workspace_path": "$workspace_path",
  "preflight_root": "$preflight_root",
  "preflight_summary_readme": "$preflight_root/README.md",
  "preflight_summary_manifest": "$preflight_root/manifest.json",
  "preflight_report_validation": "$preflight_root/preflight-report-validation.txt",
  "receipts": [
    {
      "name": "preflight output",
      "output_file": "$preflight_output"
    },
    {
      "name": "report draft",
      "output_file": "$report_draft_validation_output"
    },
    {
      "name": "intake activation record",
      "output_file": "$activation_record_validation_output"
    },
    {
      "name": "research dispatch",
      "output_file": "$research_dispatch_validation_output"
    },
    {
      "name": "evidence capture",
      "output_file": "$evidence_capture_validation_output"
    },
    {
      "name": "scoring pack",
      "output_file": "$scoring_pack_validation_output"
    },
    {
      "name": "delivery email",
      "output_file": "$delivery_email_validation_output"
    },
    {
      "name": "delivery package",
      "output_file": "$delivery_validation_output"
    },
    {
      "name": "closeout records",
      "output_file": "$closeout_validation_output"
    },
    {
      "name": "full dry-run report validation",
      "output_file": "$full_dry_run_report_validation_output"
    }
  ]
}
EOF

"$full_dry_run_report_validator" "$report_root" | tee "$full_dry_run_report_validation_output"

final_outputs=(
  "$summary_readme"
  "$summary_manifest"
  "$full_dry_run_report_validation_output"
)

for path in "${final_outputs[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty final full dry-run artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady full dry run completed"
echo "business_name: $business_name"
echo "business_slug: $slug"
echo "tier: $tier"
echo "report_root: $report_root"
echo "workspace_path: $workspace_path"
