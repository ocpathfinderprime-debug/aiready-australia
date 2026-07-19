#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-tier-matrix-report.sh /path/to/tier-matrix-report-root

Validates that an AIReady tier-matrix smoke report root contains the expected
summary, manifest, and nested full dry-run validations for each paid tier.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
tier_validation_files=(
  "$report_root/starter/full-dry-run-report-validation.txt"
  "$report_root/business/full-dry-run-report-validation.txt"
  "$report_root/enterprise/full-dry-run-report-validation.txt"
)

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

for path in "${tier_validation_files[@]}"; do
  require_nonempty_file "$path"
done

required_readme_strings=(
  "# AIReady Tier Matrix Smoke"
  "- Report root: \`$report_root\`"
  "Starter output: [starter.txt](./starter.txt)"
  "Starter dry-run validation: [starter/full-dry-run-report-validation.txt](./starter/full-dry-run-report-validation.txt)"
  "Business output: [business.txt](./business.txt)"
  "Business dry-run validation: [business/full-dry-run-report-validation.txt](./business/full-dry-run-report-validation.txt)"
  "Enterprise output: [enterprise.txt](./enterprise.txt)"
  "Enterprise dry-run validation: [enterprise/full-dry-run-report-validation.txt](./enterprise/full-dry-run-report-validation.txt)"
  "Tier-matrix report validation: [tier-matrix-report-validation.txt](./tier-matrix-report-validation.txt)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"report_root\": \"$report_root\""
  '"tier": "Starter"'
  '"tier": "Business"'
  '"tier": "Enterprise"'
  "\"report_validation_output\": \"$report_root/starter/full-dry-run-report-validation.txt\""
  "\"report_validation_output\": \"$report_root/business/full-dry-run-report-validation.txt\""
  "\"report_validation_output\": \"$report_root/enterprise/full-dry-run-report-validation.txt\""
  '"name": "tier-matrix report validation"'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

echo "AIReady tier-matrix report validated"
echo "report_root: $report_root"
echo
echo "validated_tier_reports:"
printf '  - %s\n' "${tier_validation_files[@]}"
