# AIReady Artifact Naming Convention

Date: 2026-07-15 AWST
Mission: AIReady Australia pre-intake naming hardening

## Purpose

Use these naming rules for the first live AIReady intake and every later intake so
client folders, reports, QA records, and delivery artifacts stay predictable.

## Client slug rule

Create `business_slug` as:

- lowercase
- words separated by hyphens
- letters and numbers only
- remove punctuation and trailing spaces

Example:

- `Acme Plumbing WA` -> `acme-plumbing-wa`

## Client workspace root

Use:

`/Clients/{business_slug}/`

## Standard file names

### 00_Intake

- `raw-intake.json`
- `redacted-working-intake.md`
- `intake-completeness-check.md`
- `client-clarification-required.md`
- `risk-flags.md`

### 01_Evidence_Vault

- `evidence-index.md`
- `sources-log.md`
- `assumptions-register.md`

### 02_Research

- `dispatch-log.md`
- `signal-return.md`
- `ops-chief-return.md`
- `build-return.md`
- `sentinel-return.md`
- `strategy-return.md`
- `finance-return.md`
- `growth-return.md`
- `archivist-return.md`

### 03_Scoring

- `opportunity-register.md`
- `priority-summary.md`

### 04_Report_Draft

- `{business_slug}-aiready-starter-report-draft.md`
- `{business_slug}-aiready-business-report-draft.md`
- `{business_slug}-aiready-enterprise-report-draft.md`

Use only the tier-relevant draft file.

### 05_QA

- `qa-gate-checklist.md`
- `qa-review-notes.md`

### 06_Delivery

- `{business_slug}-aiready-report-final.pdf`
- `{business_slug}-delivery-email-draft.md`
- `delivery-package-checklist.md`

If the tier includes extra artifacts, use:

- `{business_slug}-executive-summary.pdf`
- `{business_slug}-board-brief.pdf`
- `{business_slug}-integration-map.pdf`

## Timestamp rule

Only add timestamps when there are multiple versions of the same artifact in the
same folder.

Format:

`YYYY-MM-DD-HHMM-AWST`

Example:

- `2026-07-15-2215-AWST-qa-review-notes.md`

## Version rule

Do not add `final-final`, `v2-final`, or similar unstable names.

If multiple controlled revisions are needed, use:

- `v1`
- `v2`
- `v3`

Example:

- `acme-plumbing-wa-aiready-business-report-draft-v2.md`

## Authority

If this file conflicts with the AIReady Prompt Kit, the kit wins.
