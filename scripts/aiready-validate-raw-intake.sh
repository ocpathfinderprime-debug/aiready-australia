#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-raw-intake.sh /path/to/raw-intake.json

Validates that a saved AIReady raw intake payload is valid JSON and includes the
minimum first-intake fields required by the runbook.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

raw_intake_path="$1"
client_workspace_root="$(dirname "$(dirname "$raw_intake_path")")"
preflight_root="$(dirname "$(dirname "$client_workspace_root")")"
readiness_snapshot_path="$preflight_root/sample-readiness-snapshot.txt"
trigger_file="$preflight_root/sample-order-trigger.txt"

if [[ ! -f "$raw_intake_path" ]]; then
  echo "Raw intake file not found: $raw_intake_path" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but was not found in PATH" >&2
  exit 1
fi

if ! jq empty "$raw_intake_path" >/dev/null 2>&1; then
  echo "Raw intake is not valid JSON: $raw_intake_path" >&2
  exit 1
fi

has_coherence_context=true
if [[ ! -f "$readiness_snapshot_path" || ! -f "$trigger_file" ]]; then
  has_coherence_context=false
fi

required_fields=(
  client_name
  business_name
  email
  package_type
  payment_status
  stripe_payment_id
  intake_status
  tally_response_id
  intake_link
  zoho_record_id
  report_due_date
)

for field in "${required_fields[@]}"; do
  value="$(jq -r --arg field "$field" '.[$field] // empty' "$raw_intake_path")"
  if [[ -z "$value" ]]; then
    echo "Missing required field: $field" >&2
    exit 1
  fi
done

payment_status="$(jq -r '.payment_status' "$raw_intake_path")"
intake_status="$(jq -r '.intake_status' "$raw_intake_path")"

if [[ "$payment_status" != "paid" ]]; then
  echo "Expected payment_status=paid but found: $payment_status" >&2
  exit 1
fi

if [[ "$intake_status" != "complete" ]]; then
  echo "Expected intake_status=complete but found: $intake_status" >&2
  exit 1
fi

if [[ "$has_coherence_context" == true ]]; then
  get_kv_value() {
    local key="$1"
    local file="$2"
    awk -F': ' -v key="$key" '
      $1 == key {
        print substr($0, length(key) + 3)
        found = 1
        exit
      }
      END {
        if (!found) {
          exit 1
        }
      }
    ' "$file"
  }

  for pair in \
    "client_name:client_name" \
    "business_name:business_name" \
    "email:email" \
    "package_type:package_type" \
    "payment_status:payment_status" \
    "stripe_payment_id:stripe_payment_id" \
    "intake_status:intake_status" \
    "tally_response_id:tally_response_id" \
    "intake_link:intake_link" \
    "zoho_record_id:zoho_record_id" \
    "report_due_date:report_due_date"; do
    IFS=':' read -r json_field kv_field <<<"$pair"
    raw_value="$(jq -r --arg field "$json_field" '.[$field]' "$raw_intake_path")"
    snapshot_value="$(get_kv_value "$kv_field" "$readiness_snapshot_path")"
    trigger_value="$(get_kv_value "$kv_field" "$trigger_file")"
    if [[ "$raw_value" != "$snapshot_value" || "$raw_value" != "$trigger_value" ]]; then
      echo "Raw intake field does not match readiness snapshot and trigger: $json_field" >&2
      exit 1
    fi
  done
fi

echo "AIReady raw intake validated"
echo "raw_intake_path: $raw_intake_path"
echo
echo "validated_fields:"
printf '  - %s\n' "${required_fields[@]}"
