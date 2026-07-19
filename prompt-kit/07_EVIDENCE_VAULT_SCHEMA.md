# Evidence Vault Schema

Each source must be logged before it is used in the report.

## Source Record Template

```yaml
source_id: EV-0001
client: "{{business_slug}}"
date_accessed: "{{YYYY-MM-DD}}"
source_type: "official_vendor | government | case_study | industry | pricing | legal_guidance | internal_intake | competitor_site | other"
title: ""
publisher: ""
url: ""
relevance:
  client_question_or_pain_point: ""
  recommendation_supported: ""
  tier: "Starter | Business | Enterprise"
reliability:
  score_1_to_5: 0
  reason: ""
currency:
  current_as_of: ""
  stale_risk: "low | medium | high"
claims_supported:
  - ""
limits_or_cautions:
  - ""
used_in_report_section:
  - ""
```

## Evidence Rules
- Internal intake answers count as evidence of client context, not proof that a solution works.
- Vendor pages can prove availability, features, integrations, and stated pricing, but not guaranteed ROI.
- Case studies can support feasibility, but must not be copied as proof that the same result will occur.
- Government and regulator sources override marketing claims for privacy, security, and AI governance.
- If evidence conflicts, escalate to Prime for judgement and label uncertainty.
