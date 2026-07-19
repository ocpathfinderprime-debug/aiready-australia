#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-preflight-check.sh "Business Name" [report_root]
  aiready-preflight-check.sh "Business Name" <Starter|Business|Enterprise> [report_root]

Runs the local AIReady pre-intake readiness checks end-to-end:
1. validates the trigger contract docs
2. validates a sample Zoho readiness snapshot
3. validates a sample paid-order trigger message
4. bootstraps a disposable client workspace
5. validates the saved raw intake payload
6. validates the generated client workspace
7. validates the trigger-to-activation receipt
8. confirms duplicate-target protection

When a tier is supplied, the sample readiness snapshot, trigger message, and
raw intake payload use that tier instead of the default `Business`.
EOF
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

business_name="$1"
tier="Business"
report_root=""

if [[ $# -ge 2 ]]; then
  case "$2" in
    Starter|Business|Enterprise)
      tier="$2"
      report_root="${3:-}"
      ;;
    *)
      report_root="$2"
      ;;
  esac
fi

if [[ $# -eq 3 ]]; then
  case "$2" in
    Starter|Business|Enterprise) ;;
    *)
      echo "Invalid tier: $2" >&2
      usage >&2
      exit 1
      ;;
  esac
fi
workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bootstrap_script="$workspace_root/scripts/aiready-bootstrap-client-workspace.sh"
trigger_validator="$workspace_root/scripts/aiready-validate-trigger-contract.sh"
readiness_validator="$workspace_root/scripts/aiready-validate-readiness-snapshot.sh"
order_trigger_validator="$workspace_root/scripts/aiready-validate-order-trigger.sh"
raw_intake_validator="$workspace_root/scripts/aiready-validate-raw-intake.sh"
workspace_validator="$workspace_root/scripts/aiready-validate-client-workspace.sh"
activation_record_validator="$workspace_root/scripts/aiready-validate-intake-activation-record.sh"
preflight_report_validator="$workspace_root/scripts/aiready-validate-preflight-report.sh"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

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
  timestamp="$(date +%Y-%m-%d-%H%M-AWST)"
  report_root="$workspace_root/reports/aiready-preflight-$timestamp"
fi

clients_root="$report_root/Clients"
workspace_path="$clients_root/$slug"

require_file "$bootstrap_script"
require_file "$trigger_validator"
require_file "$readiness_validator"
require_file "$order_trigger_validator"
require_file "$raw_intake_validator"
require_file "$workspace_validator"
require_file "$activation_record_validator"
require_file "$preflight_report_validator"

if [[ -e "$report_root" ]]; then
  echo "Report root already exists: $report_root" >&2
  exit 1
fi

mkdir -p "$report_root"

trigger_output="$report_root/trigger-contract-validation.txt"
sample_readiness_file="$report_root/sample-readiness-snapshot.txt"
readiness_output="$report_root/readiness-snapshot-validation.txt"
sample_trigger_file="$report_root/sample-order-trigger.txt"
order_trigger_output="$report_root/order-trigger-validation.txt"
bootstrap_output="$report_root/bootstrap-output.txt"
sample_raw_intake_file="$workspace_path/00_Intake/raw-intake.json"
workspace_readiness_file="$workspace_path/00_Intake/sample-readiness-snapshot.txt"
workspace_trigger_file="$workspace_path/00_Intake/sample-order-trigger.txt"
workspace_completeness_file="$workspace_path/00_Intake/intake-completeness-check.md"
raw_intake_validation_output="$report_root/raw-intake-validation.txt"
workspace_validation_output="$report_root/client-workspace-validation.txt"
activation_record_validation_output="$report_root/intake-activation-record-validation.txt"
duplicate_guard_output="$report_root/duplicate-guard-check.txt"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
preflight_report_validation_output="$report_root/preflight-report-validation.txt"

"$trigger_validator" | tee "$trigger_output"
cat >"$sample_readiness_file" <<EOF
client_name: Sample Client
business_name: $business_name
email: owner@$slug.example.com
package_type: $tier
payment_status: paid
stripe_payment_id: pi_sample_$slug
intake_status: complete
tally_response_id: tally_$slug
intake_link: https://example.com/intake/$slug
zoho_record_id: zoho_$slug
report_due_date: 2026-07-31
audit_status: new
prime_trigger_sent: false
EOF
"$readiness_validator" "$sample_readiness_file" | tee "$readiness_output"
cat >"$sample_trigger_file" <<EOF
AIREADY ORDER READY
client_name: Sample Client
business_name: $business_name
email: owner@$slug.example.com
package_type: $tier
payment_status: paid
stripe_payment_id: pi_sample_$slug
intake_status: complete
tally_response_id: tally_$slug
intake_link: https://example.com/intake/$slug
zoho_record_id: zoho_$slug
report_due_date: 2026-07-31
notes: sample preflight trigger
EOF
"$order_trigger_validator" "$sample_trigger_file" | tee "$order_trigger_output"
"$bootstrap_script" "$business_name" "$clients_root" | tee "$bootstrap_output"
cp "$sample_readiness_file" "$workspace_readiness_file"
cp "$sample_trigger_file" "$workspace_trigger_file"
cat >"$sample_raw_intake_file" <<EOF
{
  "client_name": "Sample Client",
  "business_name": "$business_name",
  "email": "owner@$slug.example.com",
  "package_type": "$tier",
  "payment_status": "paid",
  "stripe_payment_id": "pi_sample_$slug",
  "intake_status": "complete",
  "tally_response_id": "tally_$slug",
  "intake_link": "https://example.com/intake/$slug",
  "zoho_record_id": "zoho_$slug",
  "report_due_date": "2026-07-31",
  "notes": "sample preflight raw intake payload"
}
EOF
cat >"$workspace_completeness_file" <<EOF
# Intake Completeness Check

## Intake identity

- Business: $business_name
- Client: Sample Client
- Tier: $tier
- Zoho record id: zoho_$slug
- Tally response id: tally_$slug
- Stripe payment id: pi_sample_$slug
- Intake received at: 2026-07-16-0000-AWST
- Checked by: Prime

## Required fields

- [x] payment_status = paid
- [x] intake_status = complete
- [x] package type present
- [x] client name present
- [x] business name present
- [x] primary email present
- [x] intake link or raw payload present
- [x] order reference present
- [x] report due date present

## Required payload readback

- client_name: Sample Client
- business_name: $business_name
- email: owner@$slug.example.com
- package_type: $tier
- payment_status: paid
- stripe_payment_id: pi_sample_$slug
- intake_status: complete
- tally_response_id: tally_$slug
- intake_link: https://example.com/intake/$slug
- zoho_record_id: zoho_$slug
- report_due_date: 2026-07-31

## Missing but non-blocking

- none

## Blocking gaps

- none

## Decision

- Status: pass
- Operator: Prime
- Timestamp: 2026-07-16-0001-AWST
- Stop line if blocked: none
EOF
cat >"$workspace_path/00_Intake/trigger-and-activation-record.md" <<EOF
# Trigger And Activation Record

## Trigger receipt

- Trigger received at: 2026-07-16-0000-AWST
- Trigger channel or source: Discord #mission-005-aiready-orders
- Trigger operator: Prime
- Zoho readiness snapshot checked: yes
- Order-trigger message checked: yes

## Trigger payload readback

- Client: Sample Client
- Business: $business_name
- Tier: $tier
- Email: owner@$slug.example.com
- Zoho record id: zoho_$slug
- Tally response id: tally_$slug
- Stripe payment id: pi_sample_$slug
- Report due date: 2026-07-31

## Activation decision

- Activation status: cleared to start
- Blocking issue: none
- Activation approved by: Prime
- Activation timestamp: 2026-07-16-0002-AWST
- Client workspace path: /Clients/$slug

## Evidence refs

- Readiness snapshot file: /Clients/$slug/00_Intake/sample-readiness-snapshot.txt
- Trigger message file: /Clients/$slug/00_Intake/sample-order-trigger.txt
- Raw intake file: /Clients/$slug/00_Intake/raw-intake.json
- Intake completeness check: /Clients/$slug/00_Intake/intake-completeness-check.md

## Notes

- Sample preflight activation receipt.
EOF
"$raw_intake_validator" "$sample_raw_intake_file" | tee "$raw_intake_validation_output"
"$workspace_validator" "$workspace_path" "$slug" | tee "$workspace_validation_output"
"$activation_record_validator" "$workspace_path" "$slug" | tee "$activation_record_validation_output"

set +e
"$bootstrap_script" "$business_name" "$clients_root" >"$duplicate_guard_output" 2>&1
duplicate_exit=$?
set -e

if [[ $duplicate_exit -eq 0 ]]; then
  echo "Duplicate-target protection failed: bootstrap unexpectedly succeeded on rerun" >&2
  exit 1
fi

echo "exit_code: $duplicate_exit" >> "$duplicate_guard_output"

cat >"$summary_readme" <<EOF
# AIReady Preflight Check

- Report root: \`$report_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`
- Business: \`$business_name\`
- Business slug: \`$slug\`
- Tier: \`$tier\`
- Workspace path: \`$workspace_path\`

## Validation receipts

- Trigger contract: [trigger-contract-validation.txt](./trigger-contract-validation.txt)
- Readiness snapshot: [readiness-snapshot-validation.txt](./readiness-snapshot-validation.txt)
- Order trigger: [order-trigger-validation.txt](./order-trigger-validation.txt)
- Bootstrap output: [bootstrap-output.txt](./bootstrap-output.txt)
- Raw intake: [raw-intake-validation.txt](./raw-intake-validation.txt)
- Client workspace: [client-workspace-validation.txt](./client-workspace-validation.txt)
- Intake activation record: [intake-activation-record-validation.txt](./intake-activation-record-validation.txt)
- Duplicate guard: [duplicate-guard-check.txt](./duplicate-guard-check.txt)
- Preflight report validation: [preflight-report-validation.txt](./preflight-report-validation.txt)

## Sample inputs

- Sample readiness snapshot: [sample-readiness-snapshot.txt](./sample-readiness-snapshot.txt)
- Sample order trigger: [sample-order-trigger.txt](./sample-order-trigger.txt)
- Client workspace root: [Clients/](./Clients/)

## Outcome

This run proves the local AIReady pre-intake lane can validate the trigger
contract, rehearse the readiness gate, bootstrap a disposable client workspace,
and reject duplicate targeting before a live intake arrives.
EOF

cat >"$summary_manifest" <<EOF
{
  "report_root": "$report_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "business_name": "$business_name",
  "business_slug": "$slug",
  "tier": "$tier",
  "workspace_path": "$workspace_path",
  "summary_readme": "$summary_readme",
  "summary_manifest": "$summary_manifest",
  "client_workspace_root": "$report_root/Clients",
  "receipts": [
    {
      "name": "trigger contract",
      "output_file": "$trigger_output"
    },
    {
      "name": "readiness snapshot",
      "output_file": "$readiness_output",
      "sample_input": "$sample_readiness_file"
    },
    {
      "name": "order trigger",
      "output_file": "$order_trigger_output",
      "sample_input": "$sample_trigger_file"
    },
    {
      "name": "bootstrap output",
      "output_file": "$bootstrap_output"
    },
    {
      "name": "raw intake",
      "output_file": "$raw_intake_validation_output",
      "sample_input": "$sample_raw_intake_file"
    },
    {
      "name": "client workspace",
      "output_file": "$workspace_validation_output"
    },
    {
      "name": "intake activation record",
      "output_file": "$activation_record_validation_output"
    },
    {
      "name": "duplicate guard",
      "output_file": "$duplicate_guard_output"
    },
    {
      "name": "preflight report validation",
      "output_file": "$preflight_report_validation_output"
    }
  ]
}
EOF

"$preflight_report_validator" "$report_root" | tee "$preflight_report_validation_output"

final_outputs=(
  "$summary_readme"
  "$summary_manifest"
  "$preflight_report_validation_output"
)

for path in "${final_outputs[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty final preflight artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady preflight check completed"
echo "business_name: $business_name"
echo "business_slug: $slug"
echo "tier: $tier"
echo "report_root: $report_root"
echo "workspace_path: $workspace_path"
echo
echo "artifacts:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$trigger_output" \
  "$sample_readiness_file" \
  "$readiness_output" \
  "$sample_trigger_file" \
  "$order_trigger_output" \
  "$bootstrap_output" \
  "$raw_intake_validation_output" \
  "$workspace_validation_output" \
  "$activation_record_validation_output" \
  "$duplicate_guard_output" \
  "$preflight_report_validation_output" \
  "$report_root/Clients"
