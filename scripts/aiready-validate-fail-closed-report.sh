#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-fail-closed-report.sh /path/to/fail-closed-report-root

Validates that an AIReady fail-closed report root contains the expected
negative-path proof packet, sample bad inputs, and failure receipts.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
bad_readiness_file="$report_root/bad-readiness-snapshot.txt"
bad_trigger_file="$report_root/bad-order-trigger.txt"
bad_raw_intake_file="$report_root/bad-raw-intake.json"
readiness_output="$report_root/readiness-invalid-audit-status.txt"
trigger_output="$report_root/trigger-invalid-payment-status.txt"
raw_intake_output="$report_root/raw-intake-missing-intake-link.txt"
report_validation_output="$report_root/fail-closed-report-validation.txt"

require_nonempty_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
  if [[ ! -s "$path" ]]; then
    echo "File is empty: $path" >&2
    exit 1
  fi
}

require_literal() {
  local needle="$1"
  local file="$2"
  if ! rg -Fq -- "$needle" "$file"; then
    echo "Missing required text in $file: $needle" >&2
    exit 1
  fi
}

if [[ ! -d "$report_root" ]]; then
  echo "Report root not found: $report_root" >&2
  exit 1
fi

require_nonempty_file "$summary_readme"
require_nonempty_file "$summary_manifest"
require_nonempty_file "$bad_readiness_file"
require_nonempty_file "$bad_trigger_file"
require_nonempty_file "$bad_raw_intake_file"
require_nonempty_file "$readiness_output"
require_nonempty_file "$trigger_output"
require_nonempty_file "$raw_intake_output"

required_readme_strings=(
  "# AIReady Fail-Closed Smoke"
  "- Report root: \`$report_root\`"
  "## Negative-path checks"
  "Readiness invalid audit status: [readiness-invalid-audit-status.txt](./readiness-invalid-audit-status.txt)"
  "Trigger invalid payment status: [trigger-invalid-payment-status.txt](./trigger-invalid-payment-status.txt)"
  "Raw intake missing intake link: [raw-intake-missing-intake-link.txt](./raw-intake-missing-intake-link.txt)"
  "Fail-closed report validation: [fail-closed-report-validation.txt](./fail-closed-report-validation.txt)"
  "## Bad sample inputs"
  "Bad readiness snapshot: [bad-readiness-snapshot.txt](./bad-readiness-snapshot.txt)"
  "Bad order trigger: [bad-order-trigger.txt](./bad-order-trigger.txt)"
  "Bad raw intake: [bad-raw-intake.json](./bad-raw-intake.json)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"report_root\": \"$report_root\""
  "\"summary_readme\": \"$summary_readme\""
  "\"summary_manifest\": \"$summary_manifest\""
  "\"report_validation_output\": \"$report_validation_output\""
  '"name": "readiness-invalid-audit-status"'
  '"name": "trigger-invalid-payment-status"'
  '"name": "raw-intake-missing-intake-link"'
  '"expected_error": "Invalid audit_status: ready_to_start"'
  '"expected_error": "Invalid payment_status: pending"'
  '"expected_error": "Missing required field: intake_link"'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

require_literal "Invalid audit_status: ready_to_start" "$readiness_output"
require_literal "expected_error: Invalid audit_status: ready_to_start" "$readiness_output"
require_literal "Invalid payment_status: pending" "$trigger_output"
require_literal "expected_error: Invalid payment_status: pending" "$trigger_output"
require_literal "Missing required field: intake_link" "$raw_intake_output"
require_literal "expected_error: Missing required field: intake_link" "$raw_intake_output"

echo "AIReady fail-closed report validated"
echo "report_root: $report_root"
echo
echo "validated_failures:"
printf '  - %s\n' \
  "readiness-invalid-audit-status" \
  "trigger-invalid-payment-status" \
  "raw-intake-missing-intake-link"
echo
echo "validated_artifacts:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$bad_readiness_file" \
  "$bad_trigger_file" \
  "$bad_raw_intake_file" \
  "$readiness_output" \
  "$trigger_output" \
  "$raw_intake_output"
