# AIReady Australia — Zoho CRM Workflow Spec

Date: 2026-04-23 AWST
Mission: AIReady Australia launch workflow

## Objective
Create a reliable automation path so a paid AIReady order moves from purchase to intake to audit-start without manual confusion.

## Control principle
Zoho CRM is the source of truth.

External tools may feed data into the workflow, but the audit should only start when the Zoho record shows the job is truly ready.

## Recommended module design

### Preferred option
Create a dedicated Zoho CRM custom module:
- `AIReady Audits`

This is cleaner than overloading Deals for delivery work.

## Required records and links
Each audit record should link or reference:
- Contact
- Company / Account
- Stripe payment
- Tally intake response
- assigned Prime workflow state

## Required fields

### Identity
- `Audit Name` (text)
  - example: `AI Audit - Acme Plumbing - 2026-04-23`
- `Client Name` (text)
- `Business Name` (text)
- `Primary Email` (email)
- `Phone` (phone)
- `Website` (URL)
- `Industry` (picklist)
- `Team Size` (number or picklist)

### Commercial
- `Package Type` (picklist)
  - Starter
  - Business
  - Enterprise
- `Package Price` (currency)
- `Stripe Payment ID` (text)
- `Payment Status` (picklist)
  - pending
  - paid
  - failed
  - refunded
- `Purchase Date` (datetime)
- `Source` (picklist)
  - Website
  - Direct
  - Referral
  - Campaign

### Intake
- `Tally Response ID` (text)
- `Tally Submission Date` (datetime)
- `Intake Status` (picklist)
  - not_sent
  - waiting
  - complete
  - invalid
- `Intake Link` (URL)
- `Intake Summary` (multi-line text)
- `Attached Intake Sheet Row ID` (text)

### Delivery
- `Audit Status` (picklist)
  - new
  - ready_to_start
  - in_progress
  - report_ready
  - delivered
  - follow_up
  - closed
- `Assigned To` (user/text)
  - Prime
- `Report Due Date` (date)
- `Delivery Date` (datetime)
- `Follow-up Due` (date)
- `Priority` (picklist)
  - normal
  - high
  - urgent

### Control / operations
- `Prime Trigger Sent` (checkbox)
- `Prime Trigger Timestamp` (datetime)
- `Prime Trigger Channel` (text)
- `Notes` (multi-line text)
- `Error State` (picklist)
  - none
  - payment_mismatch
  - intake_missing
  - duplicate_order
  - manual_review

## Status logic

### Payment Status
- `pending` → order not confirmed
- `paid` → safe to move toward audit readiness
- `failed` → stop workflow
- `refunded` → stop / close

### Intake Status
- `not_sent` → intake path not yet delivered
- `waiting` → client has not completed intake
- `complete` → client answers received
- `invalid` → bad/partial/malformed response

### Audit Status
- `new` → record created
- `ready_to_start` → paid + intake complete + trigger ready
- `in_progress` → audit actively being worked
- `report_ready` → report complete, pending send/review
- `delivered` → report sent to client
- `follow_up` → follow-up window active
- `closed` → finished

## Trigger rule

### Master readiness rule
Trigger Prime ONLY when all conditions are true:
- `Payment Status = paid`
- `Intake Status = complete`
- `Audit Status = new`
- `Prime Trigger Sent = false`

### Action on trigger
1. update `Audit Status = ready_to_start`
2. set `Assigned To = Prime`
3. set `Prime Trigger Sent = true`
4. set `Prime Trigger Timestamp = now`
5. post structured trigger into Discord orders channel
6. optionally create follow-up internal task in Zoho

## Recommended automation stack

### Core
- Zoho CRM Workflow Rules
- Zoho CRM Functions
- Zoho Connections

### Optional glue
- Zoho Flow or Make/Zapier if native mapping from Stripe/Tally is awkward

## Recommended event flow

### Step 1 — purchase happens
Stripe confirms payment.

### Step 2 — CRM record is created or updated
Create / update `AIReady Audits` record with:
- package
- contact info
- payment id
- payment status = paid

### Step 3 — intake happens
Tally form is completed.

### Step 4 — intake is mapped into same audit record
Update:
- tally response id
- intake summary / link
- intake status = complete

### Step 5 — readiness workflow fires
Zoho checks the master readiness rule.

### Step 6 — Prime is triggered
Send trigger to Discord:
- channel: `#mission-005-aiready-orders`
- channel id: `1496711660247842956`
- template: `ops/AIREADY-DISCORD-TRIGGER-TEMPLATE.md`

## Trigger payload format
Post this into the orders channel:

- `AIREADY ORDER READY`
- `client_name: <name>`
- `business_name: <business>`
- `email: <email>`
- `package_type: <Starter|Business|Enterprise>`
- `payment_status: paid`
- `stripe_payment_id: <id>`
- `intake_status: complete`
- `tally_response_id: <id>`
- `intake_link: <url>`
- `zoho_record_id: <id>`
- `report_due_date: <date>`
- `notes: <optional>`

Reusable version:

- `ops/AIREADY-DISCORD-TRIGGER-TEMPLATE.md`

Local readiness validation helper before emitting the trigger:

- `scripts/aiready-validate-readiness-snapshot.sh`

Full local standby gate before the first real paid trigger:

- `scripts/aiready-standby-readiness-check.sh`

## Best operational rule
Do NOT trigger Prime on payment alone.
Do NOT trigger Prime on intake alone.
Trigger only on `paid + intake complete`.

## Google Sheets role
Use Google Sheets as:
- reporting log
- backup visibility layer
- lightweight operations dashboard

Do NOT use Sheets as the master trigger source if Zoho CRM exists.

## Email role
Use Zoho Mail / Gmail as:
- notification layer
- delivery channel
- backup reference trail

Do NOT use email as the sole system of truth for job state.

## Suggested Zoho workflow names
- `AIReady - Create Audit Record on Paid Order`
- `AIReady - Update Audit on Tally Submission`
- `AIReady - Trigger Prime When Audit Ready`
- `AIReady - Mark Audit In Progress`
- `AIReady - Mark Audit Delivered`
- `AIReady - Start Follow-up Window`

## Launch-success criteria
The workflow is successful when:
- every paid client has one CRM audit record
- every intake lands on the same record
- Prime only starts when the record is ready
- trigger is visible in Discord orders channel
- audit progress can be tracked from Zoho without guesswork
