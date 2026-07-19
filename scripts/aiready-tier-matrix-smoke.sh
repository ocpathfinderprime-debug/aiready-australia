#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-tier-matrix-smoke.sh [report_root]

Runs the disposable AIReady full dry run once for each tier:
- Starter
- Business
- Enterprise

This proves the local first-intake lane works across the full paid tier matrix.
EOF
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_root="${1:-$workspace_root/reports/aiready-tier-matrix-$(date +%Y-%m-%d-%H%M-AWST)}"
full_dry_run_script="$workspace_root/scripts/aiready-full-dry-run.sh"
tier_matrix_report_validator="$workspace_root/scripts/aiready-validate-tier-matrix-report.sh"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

require_file "$full_dry_run_script"
require_file "$tier_matrix_report_validator"

if [[ -e "$report_root" ]]; then
  echo "Report root already exists: $report_root" >&2
  exit 1
fi

mkdir -p "$report_root"

summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
tier_matrix_report_validation_output="$report_root/tier-matrix-report-validation.txt"

run_tier() {
  local business_name="$1"
  local tier="$2"
  local lane="$3"
  local lane_root="$report_root/$lane"
  local output_file="$report_root/${lane}.txt"

  "$full_dry_run_script" "$business_name" "$tier" "$lane_root" | tee "$output_file"
}

run_tier "Signal Forge" Starter starter
run_tier "Northwind Ops" Business business
run_tier "Harbor Grid Systems" Enterprise enterprise

cat >"$summary_readme" <<EOF
# AIReady Tier Matrix Smoke

- Report root: \`$report_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`

## Tier runs

- Starter output: [starter.txt](./starter.txt)
  - Dry-run root: [starter/](./starter/)
  - Dry-run summary: [starter/README.md](./starter/README.md)
  - Dry-run manifest: [starter/manifest.json](./starter/manifest.json)
  - Starter dry-run validation: [starter/full-dry-run-report-validation.txt](./starter/full-dry-run-report-validation.txt)
- Business output: [business.txt](./business.txt)
  - Dry-run root: [business/](./business/)
  - Dry-run summary: [business/README.md](./business/README.md)
  - Dry-run manifest: [business/manifest.json](./business/manifest.json)
  - Business dry-run validation: [business/full-dry-run-report-validation.txt](./business/full-dry-run-report-validation.txt)
- Enterprise output: [enterprise.txt](./enterprise.txt)
  - Dry-run root: [enterprise/](./enterprise/)
  - Dry-run summary: [enterprise/README.md](./enterprise/README.md)
  - Dry-run manifest: [enterprise/manifest.json](./enterprise/manifest.json)
  - Enterprise dry-run validation: [enterprise/full-dry-run-report-validation.txt](./enterprise/full-dry-run-report-validation.txt)

## Validation root

- Tier-matrix report validation: [tier-matrix-report-validation.txt](./tier-matrix-report-validation.txt)

## Outcome

This run proves the disposable AIReady first-intake lane passes across all paid
tiers using tier-matched dry runs and validation receipts.
EOF

cat >"$summary_manifest" <<EOF
{
  "report_root": "$report_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "validated_tiers": [
    {
      "tier": "Starter",
      "business_name": "Signal Forge",
      "output_file": "$report_root/starter.txt",
      "dry_run_root": "$report_root/starter",
      "summary_readme": "$report_root/starter/README.md",
      "summary_manifest": "$report_root/starter/manifest.json",
      "report_validation_output": "$report_root/starter/full-dry-run-report-validation.txt"
    },
    {
      "tier": "Business",
      "business_name": "Northwind Ops",
      "output_file": "$report_root/business.txt",
      "dry_run_root": "$report_root/business",
      "summary_readme": "$report_root/business/README.md",
      "summary_manifest": "$report_root/business/manifest.json",
      "report_validation_output": "$report_root/business/full-dry-run-report-validation.txt"
    },
    {
      "tier": "Enterprise",
      "business_name": "Harbor Grid Systems",
      "output_file": "$report_root/enterprise.txt",
      "dry_run_root": "$report_root/enterprise",
      "summary_readme": "$report_root/enterprise/README.md",
      "summary_manifest": "$report_root/enterprise/manifest.json",
      "report_validation_output": "$report_root/enterprise/full-dry-run-report-validation.txt"
    }
  ],
  "validations": [
    {
      "name": "tier-matrix report validation",
      "output_file": "$tier_matrix_report_validation_output"
    }
  ]
}
EOF

"$tier_matrix_report_validator" "$report_root" | tee "$tier_matrix_report_validation_output"

if [[ ! -s "$tier_matrix_report_validation_output" ]]; then
  echo "Missing or empty tier-matrix report validation output: $tier_matrix_report_validation_output" >&2
  exit 1
fi

echo "AIReady tier matrix smoke completed"
echo "report_root: $report_root"
echo
echo "validated_tiers:"
printf '  - %s\n' \
  "Starter" \
  "Business" \
  "Enterprise"
