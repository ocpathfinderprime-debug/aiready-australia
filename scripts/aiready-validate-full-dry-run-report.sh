#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-full-dry-run-report.sh /path/to/full-dry-run-report-root

Validates that an AIReady full dry-run report root contains the expected
summary, manifest, nested preflight validation, and tier-specific validation
receipts.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
preflight_output="$report_root/preflight-output.txt"
report_draft_output="$report_root/report-draft-validation.txt"
activation_output="$report_root/intake-activation-record-validation.txt"
research_output="$report_root/research-dispatch-validation.txt"
evidence_output="$report_root/evidence-capture-validation.txt"
scoring_output="$report_root/scoring-pack-validation.txt"
delivery_email_output="$report_root/delivery-email-validation.txt"
delivery_package_output="$report_root/delivery-package-validation.txt"
closeout_output="$report_root/closeout-record-validation.txt"
preflight_report_validation="$report_root/preflight/preflight-report-validation.txt"

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
require_nonempty_file "$preflight_output"
require_nonempty_file "$report_draft_output"
require_nonempty_file "$activation_output"
require_nonempty_file "$research_output"
require_nonempty_file "$evidence_output"
require_nonempty_file "$scoring_output"
require_nonempty_file "$delivery_email_output"
require_nonempty_file "$delivery_package_output"
require_nonempty_file "$closeout_output"
require_nonempty_file "$preflight_report_validation"

required_readme_strings=(
  "# AIReady Full Dry Run"
  "- Report root: \`$report_root\`"
  "## Validation receipts"
  "Preflight output: [preflight-output.txt](./preflight-output.txt)"
  "Report draft: [report-draft-validation.txt](./report-draft-validation.txt)"
  "Intake activation record: [intake-activation-record-validation.txt](./intake-activation-record-validation.txt)"
  "Research dispatch: [research-dispatch-validation.txt](./research-dispatch-validation.txt)"
  "Evidence capture: [evidence-capture-validation.txt](./evidence-capture-validation.txt)"
  "Scoring pack: [scoring-pack-validation.txt](./scoring-pack-validation.txt)"
  "Delivery email: [delivery-email-validation.txt](./delivery-email-validation.txt)"
  "Delivery package: [delivery-package-validation.txt](./delivery-package-validation.txt)"
  "Closeout records: [closeout-record-validation.txt](./closeout-record-validation.txt)"
  "Full dry-run report validation: [full-dry-run-report-validation.txt](./full-dry-run-report-validation.txt)"
  "## Evidence roots"
  "Preflight summary: [preflight/README.md](./preflight/README.md)"
  "Preflight manifest: [preflight/manifest.json](./preflight/manifest.json)"
  "Preflight report validation: [preflight/preflight-report-validation.txt](./preflight/preflight-report-validation.txt)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"report_root\": \"$report_root\""
  "\"preflight_root\": \"$report_root/preflight\""
  "\"preflight_summary_readme\": \"$report_root/preflight/README.md\""
  "\"preflight_summary_manifest\": \"$report_root/preflight/manifest.json\""
  "\"preflight_report_validation\": \"$report_root/preflight/preflight-report-validation.txt\""
  '"name": "preflight output"'
  '"name": "report draft"'
  '"name": "intake activation record"'
  '"name": "research dispatch"'
  '"name": "evidence capture"'
  '"name": "scoring pack"'
  '"name": "delivery email"'
  '"name": "delivery package"'
  '"name": "closeout records"'
  '"name": "full dry-run report validation"'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

echo "AIReady full dry-run report validated"
echo "report_root: $report_root"
echo
echo "validated_receipts:"
printf '  - %s\n' \
  "$preflight_output" \
  "$report_draft_output" \
  "$activation_output" \
  "$research_output" \
  "$evidence_output" \
  "$scoring_output" \
  "$delivery_email_output" \
  "$delivery_package_output" \
  "$closeout_output" \
  "$preflight_report_validation"
