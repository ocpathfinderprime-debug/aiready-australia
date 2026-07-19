#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-preflight-report.sh /path/to/preflight-report-root

Validates that an AIReady preflight report root contains the expected summary,
manifest, receipt outputs, and disposable client-workspace evidence.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
trigger_output="$report_root/trigger-contract-validation.txt"
readiness_output="$report_root/readiness-snapshot-validation.txt"
order_trigger_output="$report_root/order-trigger-validation.txt"
bootstrap_output="$report_root/bootstrap-output.txt"
raw_intake_output="$report_root/raw-intake-validation.txt"
workspace_output="$report_root/client-workspace-validation.txt"
activation_output="$report_root/intake-activation-record-validation.txt"
duplicate_guard_output="$report_root/duplicate-guard-check.txt"

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
require_nonempty_file "$trigger_output"
require_nonempty_file "$readiness_output"
require_nonempty_file "$order_trigger_output"
require_nonempty_file "$bootstrap_output"
require_nonempty_file "$raw_intake_output"
require_nonempty_file "$workspace_output"
require_nonempty_file "$activation_output"
require_nonempty_file "$duplicate_guard_output"

if [[ ! -d "$report_root/Clients" ]]; then
  echo "Missing client workspace root: $report_root/Clients" >&2
  exit 1
fi

required_readme_strings=(
  "# AIReady Preflight Check"
  "- Report root: \`$report_root\`"
  "## Validation receipts"
  "Trigger contract: [trigger-contract-validation.txt](./trigger-contract-validation.txt)"
  "Readiness snapshot: [readiness-snapshot-validation.txt](./readiness-snapshot-validation.txt)"
  "Order trigger: [order-trigger-validation.txt](./order-trigger-validation.txt)"
  "Bootstrap output: [bootstrap-output.txt](./bootstrap-output.txt)"
  "Raw intake: [raw-intake-validation.txt](./raw-intake-validation.txt)"
  "Client workspace: [client-workspace-validation.txt](./client-workspace-validation.txt)"
  "Intake activation record: [intake-activation-record-validation.txt](./intake-activation-record-validation.txt)"
  "Duplicate guard: [duplicate-guard-check.txt](./duplicate-guard-check.txt)"
  "Preflight report validation: [preflight-report-validation.txt](./preflight-report-validation.txt)"
  "## Sample inputs"
  "Client workspace root: [Clients/](./Clients/)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"report_root\": \"$report_root\""
  "\"summary_readme\": \"$summary_readme\""
  "\"summary_manifest\": \"$summary_manifest\""
  "\"client_workspace_root\": \"$report_root/Clients\""
  '"name": "trigger contract"'
  '"name": "readiness snapshot"'
  '"name": "order trigger"'
  '"name": "bootstrap output"'
  '"name": "raw intake"'
  '"name": "client workspace"'
  '"name": "intake activation record"'
  '"name": "duplicate guard"'
  '"name": "preflight report validation"'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

echo "AIReady preflight report validated"
echo "report_root: $report_root"
echo
echo "validated_files:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$trigger_output" \
  "$readiness_output" \
  "$order_trigger_output" \
  "$bootstrap_output" \
  "$raw_intake_output" \
  "$workspace_output" \
  "$activation_output" \
  "$duplicate_guard_output"
echo
echo "validated_root:"
printf '  - %s\n' "$report_root/Clients"
