#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-fail-closed-smoke.sh [report_root]

Runs negative-path smoke checks to prove the AIReady intake validators fail
closed on blocking readiness, trigger, and raw-intake problems.
EOF
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_root="${1:-$workspace_root/reports/aiready-fail-closed-$(date +%Y-%m-%d-%H%M-AWST)}"

readiness_validator="$workspace_root/scripts/aiready-validate-readiness-snapshot.sh"
trigger_validator="$workspace_root/scripts/aiready-validate-order-trigger.sh"
raw_intake_validator="$workspace_root/scripts/aiready-validate-raw-intake.sh"
fail_closed_report_validator="$workspace_root/scripts/aiready-validate-fail-closed-report.sh"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

run_expect_failure() {
  local name="$1"
  local expected="$2"
  shift 2
  local output_file="$report_root/${name}.txt"

  set +e
  "$@" >"$output_file" 2>&1
  local exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    echo "Expected failure but command succeeded: $name" >&2
    exit 1
  fi

  if ! rg -Fq "$expected" "$output_file"; then
    echo "Expected failure text not found for $name: $expected" >&2
    echo "Actual output:" >&2
    cat "$output_file" >&2
    exit 1
  fi

  {
    echo "exit_code: $exit_code"
    echo "expected_error: $expected"
  } >>"$output_file"
}

require_file "$readiness_validator"
require_file "$trigger_validator"
require_file "$raw_intake_validator"
require_file "$fail_closed_report_validator"

if [[ -e "$report_root" ]]; then
  echo "Report root already exists: $report_root" >&2
  exit 1
fi

mkdir -p "$report_root"

summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
report_validation_output="$report_root/fail-closed-report-validation.txt"

bad_readiness_file="$report_root/bad-readiness-snapshot.txt"
bad_trigger_file="$report_root/bad-order-trigger.txt"
bad_raw_intake_file="$report_root/bad-raw-intake.json"

cat >"$bad_readiness_file" <<'EOF'
client_name: Sample Client
business_name: Fails Closed Pty Ltd
email: owner@example.com
package_type: Business
payment_status: paid
stripe_payment_id: pi_sample_fail_closed
intake_status: complete
tally_response_id: tally_fail_closed
intake_link: https://example.com/intake/fails-closed
zoho_record_id: zoho_fail_closed
report_due_date: 2026-07-31
audit_status: ready_to_start
prime_trigger_sent: false
EOF

cat >"$bad_trigger_file" <<'EOF'
AIREADY ORDER READY
client_name: Sample Client
business_name: Fails Closed Pty Ltd
email: owner@example.com
package_type: Business
payment_status: pending
stripe_payment_id: pi_sample_fail_closed
intake_status: complete
tally_response_id: tally_fail_closed
intake_link: https://example.com/intake/fails-closed
zoho_record_id: zoho_fail_closed
report_due_date: 2026-07-31
EOF

cat >"$bad_raw_intake_file" <<'EOF'
{
  "client_name": "Sample Client",
  "business_name": "Fails Closed Pty Ltd",
  "email": "owner@example.com",
  "package_type": "Business",
  "payment_status": "paid",
  "stripe_payment_id": "pi_sample_fail_closed",
  "intake_status": "complete",
  "tally_response_id": "tally_fail_closed",
  "report_due_date": "2026-07-31"
}
EOF

run_expect_failure \
  "readiness-invalid-audit-status" \
  "Invalid audit_status: ready_to_start" \
  "$readiness_validator" "$bad_readiness_file"

run_expect_failure \
  "trigger-invalid-payment-status" \
  "Invalid payment_status: pending" \
  "$trigger_validator" "$bad_trigger_file"

run_expect_failure \
  "raw-intake-missing-intake-link" \
  "Missing required field: intake_link" \
  "$raw_intake_validator" "$bad_raw_intake_file"

cat >"$summary_readme" <<EOF
# AIReady Fail-Closed Smoke

- Report root: \`$report_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`

## Negative-path checks

- Readiness invalid audit status: [readiness-invalid-audit-status.txt](./readiness-invalid-audit-status.txt)
- Trigger invalid payment status: [trigger-invalid-payment-status.txt](./trigger-invalid-payment-status.txt)
- Raw intake missing intake link: [raw-intake-missing-intake-link.txt](./raw-intake-missing-intake-link.txt)
- Fail-closed report validation: [fail-closed-report-validation.txt](./fail-closed-report-validation.txt)

## Bad sample inputs

- Bad readiness snapshot: [bad-readiness-snapshot.txt](./bad-readiness-snapshot.txt)
- Bad order trigger: [bad-order-trigger.txt](./bad-order-trigger.txt)
- Bad raw intake: [bad-raw-intake.json](./bad-raw-intake.json)

## Outcome

This run proves the AIReady intake validators reject blocking bad inputs instead
of silently allowing a bad start.
EOF

cat >"$summary_manifest" <<EOF
{
  "report_root": "$report_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "summary_readme": "$summary_readme",
  "summary_manifest": "$summary_manifest",
  "report_validation_output": "$report_validation_output",
  "validated_failures": [
    {
      "name": "readiness-invalid-audit-status",
      "sample_input": "$bad_readiness_file",
      "output_file": "$report_root/readiness-invalid-audit-status.txt",
      "expected_error": "Invalid audit_status: ready_to_start"
    },
    {
      "name": "trigger-invalid-payment-status",
      "sample_input": "$bad_trigger_file",
      "output_file": "$report_root/trigger-invalid-payment-status.txt",
      "expected_error": "Invalid payment_status: pending"
    },
    {
      "name": "raw-intake-missing-intake-link",
      "sample_input": "$bad_raw_intake_file",
      "output_file": "$report_root/raw-intake-missing-intake-link.txt",
      "expected_error": "Missing required field: intake_link"
    }
  ]
}
EOF

"$fail_closed_report_validator" "$report_root" | tee "$report_validation_output"

final_outputs=(
  "$summary_readme"
  "$summary_manifest"
  "$report_validation_output"
)

for path in "${final_outputs[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty final fail-closed artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady fail-closed smoke completed"
echo "report_root: $report_root"
echo
echo "artifacts:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$report_validation_output" \
  "$bad_readiness_file" \
  "$bad_trigger_file" \
  "$bad_raw_intake_file" \
  "$report_root/readiness-invalid-audit-status.txt" \
  "$report_root/trigger-invalid-payment-status.txt" \
  "$report_root/raw-intake-missing-intake-link.txt"
echo
echo "validated_failures:"
printf '  - %s\n' \
  "readiness-invalid-audit-status" \
  "trigger-invalid-payment-status" \
  "raw-intake-missing-intake-link"
