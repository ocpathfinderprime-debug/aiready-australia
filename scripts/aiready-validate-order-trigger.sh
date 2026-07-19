#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-order-trigger.sh /path/to/trigger-message.txt

Validates that an AIReady paid-order trigger message matches the live Discord
template and first-intake runbook requirements.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

trigger_file="$1"

if [[ ! -f "$trigger_file" ]]; then
  echo "Trigger file not found: $trigger_file" >&2
  exit 1
fi

if ! grep -qx 'AIREADY ORDER READY' "$trigger_file"; then
  echo "Missing or invalid header: AIREADY ORDER READY" >&2
  exit 1
fi

get_value() {
  local key="$1"
  awk -F': ' -v key="$key" '
    $1 == key {
      value = substr($0, length(key) + 3)
      print value
      found = 1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$trigger_file"
}

require_value() {
  local key="$1"
  local value
  if ! value="$(get_value "$key")"; then
    echo "Missing required field: $key" >&2
    exit 1
  fi
  if [[ -z "$value" ]]; then
    echo "Empty required field: $key" >&2
    exit 1
  fi
  printf '%s' "$value"
}

client_name="$(require_value client_name)"
business_name="$(require_value business_name)"
email="$(require_value email)"
package_type="$(require_value package_type)"
payment_status="$(require_value payment_status)"
stripe_payment_id="$(require_value stripe_payment_id)"
intake_status="$(require_value intake_status)"
tally_response_id="$(require_value tally_response_id)"
intake_link="$(require_value intake_link)"
zoho_record_id="$(require_value zoho_record_id)"
report_due_date="$(require_value report_due_date)"

case "$package_type" in
  Starter|Business|Enterprise) ;;
  *)
    echo "Invalid package_type: $package_type" >&2
    exit 1
    ;;
esac

if [[ "$payment_status" != "paid" ]]; then
  echo "Invalid payment_status: $payment_status" >&2
  exit 1
fi

if [[ "$intake_status" != "complete" ]]; then
  echo "Invalid intake_status: $intake_status" >&2
  exit 1
fi

if [[ "$email" != *"@"* ]]; then
  echo "Invalid email: $email" >&2
  exit 1
fi

if [[ "$intake_link" != http://* && "$intake_link" != https://* ]]; then
  echo "Invalid intake_link: $intake_link" >&2
  exit 1
fi

echo "AIReady order trigger validated"
echo "trigger_file: $trigger_file"
echo "client_name: $client_name"
echo "business_name: $business_name"
echo "package_type: $package_type"
echo "report_due_date: $report_due_date"
echo
echo "validated_required_fields:"
printf '  - %s\n' \
  "client_name" \
  "business_name" \
  "email" \
  "package_type" \
  "payment_status" \
  "stripe_payment_id" \
  "intake_status" \
  "tally_response_id" \
  "intake_link" \
  "zoho_record_id" \
  "report_due_date"
