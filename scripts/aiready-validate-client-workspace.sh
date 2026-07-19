#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-client-workspace.sh /path/to/Clients/business-slug [expected_slug]

Validates that an AIReady client workspace matches the first-intake runbook
minimum files and the artifact naming convention.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
expected_slug="${2:-$(basename "$workspace_root")}"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Missing directory: $path" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
}

extract_value_line() {
  local label="$1"
  local file="$2"
  awk -F': ' -v label="$label" '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == label) {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$file"
}

require_value_line() {
  local label="$1"
  local file="$2"
  local value
  value="$(extract_value_line "$label" "$file")"
  if [[ -z "${value:-}" ]]; then
    echo "Missing or empty field '$label' in $file" >&2
    exit 1
  fi
}

if [[ ! -d "$workspace_root" ]]; then
  echo "Workspace root not found: $workspace_root" >&2
  exit 1
fi

if [[ -z "$expected_slug" ]]; then
  echo "Expected slug is empty" >&2
  exit 1
fi

require_dir "$workspace_root/00_Intake"
require_dir "$workspace_root/01_Evidence_Vault"
require_dir "$workspace_root/02_Research"
require_dir "$workspace_root/03_Scoring"
require_dir "$workspace_root/04_Report_Draft"
require_dir "$workspace_root/05_QA"
require_dir "$workspace_root/06_Delivery"

require_file "$workspace_root/00_Intake/raw-intake.json"
require_file "$workspace_root/00_Intake/redacted-working-intake.md"
require_file "$workspace_root/00_Intake/intake-completeness-check.md"
require_file "$workspace_root/00_Intake/client-clarification-required.md"
require_file "$workspace_root/00_Intake/risk-flags.md"
require_file "$activation_record_file"

require_value_line "Business" "$activation_record_file"
require_value_line "Client" "$activation_record_file"
require_value_line "Tier" "$activation_record_file"
require_value_line "Client workspace path" "$activation_record_file"

activation_workspace_path="$(extract_value_line "Client workspace path" "$activation_record_file")"
expected_activation_workspace_path="/Clients/$expected_slug"

if [[ "$activation_workspace_path" != "$expected_activation_workspace_path" ]]; then
  echo "Activation record workspace path does not match expected client slug path: $activation_workspace_path vs $expected_activation_workspace_path" >&2
  exit 1
fi

require_file "$workspace_root/01_Evidence_Vault/evidence-index.md"
require_file "$workspace_root/01_Evidence_Vault/sources-log.md"
require_file "$workspace_root/01_Evidence_Vault/assumptions-register.md"

require_file "$workspace_root/02_Research/dispatch-log.md"
require_file "$workspace_root/02_Research/signal-return.md"
require_file "$workspace_root/02_Research/ops-chief-return.md"
require_file "$workspace_root/02_Research/build-return.md"
require_file "$workspace_root/02_Research/sentinel-return.md"
require_file "$workspace_root/02_Research/strategy-return.md"
require_file "$workspace_root/02_Research/finance-return.md"
require_file "$workspace_root/02_Research/growth-return.md"
require_file "$workspace_root/02_Research/archivist-return.md"

require_file "$workspace_root/03_Scoring/opportunity-register.md"
require_file "$workspace_root/03_Scoring/priority-summary.md"

require_file "$workspace_root/04_Report_Draft/${expected_slug}-aiready-starter-report-draft.md"
require_file "$workspace_root/04_Report_Draft/${expected_slug}-aiready-business-report-draft.md"
require_file "$workspace_root/04_Report_Draft/${expected_slug}-aiready-enterprise-report-draft.md"

require_file "$workspace_root/05_QA/qa-gate-checklist.md"
require_file "$workspace_root/05_QA/qa-review-notes.md"

require_file "$workspace_root/06_Delivery/${expected_slug}-delivery-email-draft.md"
require_file "$workspace_root/06_Delivery/delivery-package-checklist.md"

echo "AIReady client workspace validated"
echo "workspace_root: $workspace_root"
echo "business_slug: $expected_slug"
echo
echo "validated_directories:"
printf '  - %s\n' \
  "00_Intake" \
  "01_Evidence_Vault" \
  "02_Research" \
  "03_Scoring" \
  "04_Report_Draft" \
  "05_QA" \
  "06_Delivery"
echo
echo "validated_slugged_files:"
printf '  - %s\n' \
  "04_Report_Draft/${expected_slug}-aiready-starter-report-draft.md" \
  "04_Report_Draft/${expected_slug}-aiready-business-report-draft.md" \
  "04_Report_Draft/${expected_slug}-aiready-enterprise-report-draft.md" \
  "06_Delivery/${expected_slug}-delivery-email-draft.md"
