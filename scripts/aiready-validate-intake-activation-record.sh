#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-intake-activation-record.sh /path/to/Clients/business-slug [expected_slug]

Validates that an AIReady client workspace contains a completed trigger-to-
activation receipt for the live first-intake lane.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
expected_slug="${2:-$(basename "$workspace_root")}"
record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
}

require_value_line() {
  local label="$1"
  local file="$2"
  local value
  value="$(
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
  )"
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

require_file "$record_file"
preflight_root="$(dirname "$(dirname "$workspace_root")")"

require_value_line "Trigger received at" "$record_file"
require_value_line "Trigger channel or source" "$record_file"
require_value_line "Trigger operator" "$record_file"
require_value_line "Zoho readiness snapshot checked" "$record_file"
require_value_line "Order-trigger message checked" "$record_file"
require_value_line "Client" "$record_file"
require_value_line "Business" "$record_file"
require_value_line "Tier" "$record_file"
require_value_line "Email" "$record_file"
require_value_line "Zoho record id" "$record_file"
require_value_line "Tally response id" "$record_file"
require_value_line "Stripe payment id" "$record_file"
require_value_line "Report due date" "$record_file"
require_value_line "Activation status" "$record_file"
require_value_line "Activation approved by" "$record_file"
require_value_line "Activation timestamp" "$record_file"
require_value_line "Client workspace path" "$record_file"
require_value_line "Readiness snapshot file" "$record_file"
require_value_line "Trigger message file" "$record_file"
require_value_line "Raw intake file" "$record_file"
require_value_line "Intake completeness check" "$record_file"

readiness_checked="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Zoho readiness snapshot checked") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
trigger_checked="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Order-trigger message checked") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_client="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Client") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_business="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Business") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_tier="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_email="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Email") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_zoho="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Zoho record id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_tally="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tally response id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_stripe="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Stripe payment id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
record_due_date="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Report due date") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
activation_status="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Activation status") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
blocking_issue="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Blocking issue") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
workspace_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Client workspace path") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
readiness_snapshot_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Readiness snapshot file") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
trigger_message_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Trigger message file") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
raw_intake_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Raw intake file") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"
intake_completeness_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Intake completeness check") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$record_file"
)"

if [[ "$readiness_checked" != "yes" ]]; then
  echo "Readiness snapshot check is not recorded as yes: $readiness_checked" >&2
  exit 1
fi

if [[ "$trigger_checked" != "yes" ]]; then
  echo "Order-trigger check is not recorded as yes: $trigger_checked" >&2
  exit 1
fi

if [[ "$activation_status" != "cleared to start" ]]; then
  echo "Activation status is not cleared to start: $activation_status" >&2
  exit 1
fi

if [[ "$blocking_issue" != "none" ]]; then
  echo "Blocking issue is not none: $blocking_issue" >&2
  exit 1
fi

case "$workspace_path" in
  *"/Clients/$expected_slug") ;;
  *)
    echo "Client workspace path does not reference the expected slug '$expected_slug'" >&2
    exit 1
    ;;
esac

for evidence_path in \
  "$readiness_snapshot_path" \
  "$trigger_message_path" \
  "$raw_intake_path" \
  "$intake_completeness_path"; do
  case "$evidence_path" in
    /Clients/*)
      resolved_path="$preflight_root${evidence_path}"
      ;;
    *)
      echo "Evidence path is not rooted under /Clients: $evidence_path" >&2
      exit 1
      ;;
  esac
  require_file "$resolved_path"
done

require_value_line "Status" "$preflight_root$intake_completeness_path"
require_value_line "Operator" "$preflight_root$intake_completeness_path"
require_value_line "Timestamp" "$preflight_root$intake_completeness_path"
require_value_line "client_name" "$preflight_root$readiness_snapshot_path"
require_value_line "business_name" "$preflight_root$readiness_snapshot_path"
require_value_line "email" "$preflight_root$readiness_snapshot_path"
require_value_line "package_type" "$preflight_root$readiness_snapshot_path"
require_value_line "stripe_payment_id" "$preflight_root$readiness_snapshot_path"
require_value_line "tally_response_id" "$preflight_root$readiness_snapshot_path"
require_value_line "zoho_record_id" "$preflight_root$readiness_snapshot_path"
require_value_line "report_due_date" "$preflight_root$readiness_snapshot_path"
require_value_line "client_name" "$preflight_root$trigger_message_path"
require_value_line "business_name" "$preflight_root$trigger_message_path"
require_value_line "email" "$preflight_root$trigger_message_path"
require_value_line "package_type" "$preflight_root$trigger_message_path"
require_value_line "stripe_payment_id" "$preflight_root$trigger_message_path"
require_value_line "tally_response_id" "$preflight_root$trigger_message_path"
require_value_line "zoho_record_id" "$preflight_root$trigger_message_path"
require_value_line "report_due_date" "$preflight_root$trigger_message_path"

snapshot_client="$(awk -F': ' '/^client_name: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_business="$(awk -F': ' '/^business_name: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_email="$(awk -F': ' '/^email: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_tier="$(awk -F': ' '/^package_type: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_stripe="$(awk -F': ' '/^stripe_payment_id: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_tally="$(awk -F': ' '/^tally_response_id: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_zoho="$(awk -F': ' '/^zoho_record_id: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
snapshot_due_date="$(awk -F': ' '/^report_due_date: /{print $2; exit}' "$preflight_root$readiness_snapshot_path")"
trigger_client="$(awk -F': ' '/^client_name: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_business="$(awk -F': ' '/^business_name: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_email="$(awk -F': ' '/^email: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_tier="$(awk -F': ' '/^package_type: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_stripe="$(awk -F': ' '/^stripe_payment_id: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_tally="$(awk -F': ' '/^tally_response_id: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_zoho="$(awk -F': ' '/^zoho_record_id: /{print $2; exit}' "$preflight_root$trigger_message_path")"
trigger_due_date="$(awk -F': ' '/^report_due_date: /{print $2; exit}' "$preflight_root$trigger_message_path")"
raw_client="$(jq -r '.client_name' "$preflight_root$raw_intake_path")"
raw_business="$(jq -r '.business_name' "$preflight_root$raw_intake_path")"
raw_email="$(jq -r '.email' "$preflight_root$raw_intake_path")"
raw_tier="$(jq -r '.package_type' "$preflight_root$raw_intake_path")"
raw_stripe="$(jq -r '.stripe_payment_id' "$preflight_root$raw_intake_path")"
raw_tally="$(jq -r '.tally_response_id' "$preflight_root$raw_intake_path")"
raw_zoho="$(jq -r '.zoho_record_id' "$preflight_root$raw_intake_path")"
raw_due_date="$(jq -r '.report_due_date' "$preflight_root$raw_intake_path")"

for pair in \
  "record_client:$record_client:$snapshot_client:$trigger_client:$raw_client" \
  "record_business:$record_business:$snapshot_business:$trigger_business:$raw_business" \
  "record_email:$record_email:$snapshot_email:$trigger_email:$raw_email" \
  "record_tier:$record_tier:$snapshot_tier:$trigger_tier:$raw_tier" \
  "record_stripe:$record_stripe:$snapshot_stripe:$trigger_stripe:$raw_stripe" \
  "record_tally:$record_tally:$snapshot_tally:$trigger_tally:$raw_tally" \
  "record_zoho:$record_zoho:$snapshot_zoho:$trigger_zoho:$raw_zoho" \
  "record_due_date:$record_due_date:$snapshot_due_date:$trigger_due_date:$raw_due_date"; do
  IFS=':' read -r field_name record_value snapshot_value trigger_value raw_value <<<"$pair"
  if [[ "$record_value" != "$snapshot_value" || "$record_value" != "$trigger_value" || "$record_value" != "$raw_value" ]]; then
    echo "Activation record field does not match source inputs for $field_name" >&2
    exit 1
  fi
done

completeness_status="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Status") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$preflight_root$intake_completeness_path"
)"
stop_line="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Stop line if blocked") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$preflight_root$intake_completeness_path"
)"

if [[ "$completeness_status" != "pass" ]]; then
  echo "Intake completeness status is not pass: $completeness_status" >&2
  exit 1
fi

if [[ "$stop_line" != "none" ]]; then
  echo "Intake completeness stop line is not none: $stop_line" >&2
  exit 1
fi

echo "AIReady intake activation record validated"
echo "workspace_root: $workspace_root"
echo "business_slug: $expected_slug"
echo "record_file: $record_file"
echo
echo "validated_record_fields:"
printf '  - %s\n' \
  "trigger receipt" \
  "trigger payload readback" \
  "activation decision" \
  "evidence refs"
