# AIReady Discord Trigger Template

Date: 2026-07-15 AWST
Mission: AIReady Australia pre-intake trigger hardening

## Purpose

Use this template for the exact Discord message that announces a paid AIReady order
is ready to start.

This is the reusable rendering of the trigger payload defined in
`ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md`.

## Send target

- Channel: `#mission-005-aiready-orders`
- Channel id: `1496711660247842956`

## Send rule

Only send this trigger when all readiness conditions are true:

- `payment_status = paid`
- `intake_status = complete`
- `audit_status = new`
- `prime_trigger_sent = false`

## Exact message template

```text
AIREADY ORDER READY
client_name: <name>
business_name: <business>
email: <email>
package_type: <Starter|Business|Enterprise>
payment_status: paid
stripe_payment_id: <id>
intake_status: complete
tally_response_id: <id>
intake_link: <url>
zoho_record_id: <id>
report_due_date: <date>
notes: <optional>
```

## Pre-send validation

- client name present
- business name present
- primary email present
- package type present
- Stripe payment id present
- Tally response id present
- intake link present
- Zoho record id present

## Post-send verification

- message landed in the correct channel
- payload fields are readable and complete
- no conflicting tier, payment, or intake state appears in the message
- the client can be unambiguously matched back to the CRM record

## Failure handling

If any required field is missing:

- do not send the trigger
- log the missing field
- hold at clarification state until the blocking field is fixed
