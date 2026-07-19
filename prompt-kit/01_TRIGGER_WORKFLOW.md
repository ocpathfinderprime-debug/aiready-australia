# OC Prime Trigger Workflow — Tally Form Received

## Trigger Event
Event name: `aiready.tally_form.completed`

Required inputs:
- `submission_id`
- `submission_timestamp`
- `business_name`
- `client_name`
- `client_email`
- `client_phone`
- `purchase_tier`
- `industry`
- `location`
- `fte_staff`
- `annual_revenue`
- `website`
- `answers_q1_to_q25`
- `payment_status`
- `source_form_url`

## Immediate Prime Procedure
1. Confirm payment status and purchased tier.
2. Create client workspace:
   - `/Clients/{YYYY-MM-DD}_{business_slug}/`
   - `/Clients/{business_slug}/00_Intake/`
   - `/Clients/{business_slug}/01_Evidence_Vault/`
   - `/Clients/{business_slug}/02_Research/`
   - `/Clients/{business_slug}/03_Scoring/`
   - `/Clients/{business_slug}/04_Report_Draft/`
   - `/Clients/{business_slug}/05_QA/`
   - `/Clients/{business_slug}/06_Delivery/`
3. Save raw intake exactly as received.
4. Create a redacted working copy:
   - remove unnecessary personal contact fields;
   - preserve business-relevant operational facts;
   - label sensitive or regulated data.
5. Run intake completeness check.
6. Run risk classification.
7. Run tier entitlement check.
8. Dispatch agents.
9. Build evidence vault.
10. Draft report.
11. Run QA gate.
12. Prepare final client PDF/email package.

## Missing Information Rule
If any field blocks meaningful analysis, Prime must create a `Client Clarification Required` note. Do not delay the entire audit if the missing item is non-critical. Use conservative assumptions and label them.

## Red Flags That Require Human Review
- sensitive health, legal, financial, children, biometric, surveillance, or employee monitoring data;
- client requests replacing human judgement in high-impact decisions;
- regulated industry with unclear compliance constraints;
- automation involving customer personal data without secure storage;
- tool recommendation requiring data export to a foreign vendor;
- apparent mismatch between paid tier and business complexity;
- incomplete intake for Business or Enterprise;
- client expects guaranteed ROI without data support.
