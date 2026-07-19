#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-research-dispatch.sh /path/to/Clients/business-slug

Validates that the AIReady research dispatch log records all required lane
dispatches and return tracking for the first-intake lane.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
dispatch_file="$workspace_root/02_Research/dispatch-log.md"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"

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

require_file "$dispatch_file"
require_file "$activation_record_file"

if rg -n '^- \[ \]' "$dispatch_file" >/dev/null 2>&1; then
  echo "Unchecked research dispatch items remain in $dispatch_file" >&2
  exit 1
fi

require_value_line "Business" "$dispatch_file"
require_value_line "Tier" "$dispatch_file"
require_value_line "Zoho record id" "$dispatch_file"
require_value_line "Tally response id" "$dispatch_file"
require_value_line "Dispatch started at" "$dispatch_file"
require_value_line "Dispatch owner" "$dispatch_file"
require_value_line "Signal" "$dispatch_file"
require_value_line "Ops-Chief" "$dispatch_file"
require_value_line "Build" "$dispatch_file"
require_value_line "Sentinel" "$dispatch_file"
require_value_line "Strategy" "$dispatch_file"
require_value_line "Finance" "$dispatch_file"
require_value_line "Growth" "$dispatch_file"
require_value_line "Archivist" "$dispatch_file"
require_value_line "All required lanes dispatched" "$dispatch_file"
require_value_line "Missing lanes" "$dispatch_file"
require_value_line "Next coordination step" "$dispatch_file"
require_value_line "Client" "$activation_record_file"
require_value_line "Business" "$activation_record_file"
require_value_line "Tier" "$activation_record_file"
require_value_line "Zoho record id" "$activation_record_file"
require_value_line "Tally response id" "$activation_record_file"

dispatch_business="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Business") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"
dispatch_tier="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"
dispatch_zoho="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Zoho record id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"
dispatch_tally="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tally response id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"
activation_business="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Business") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$activation_record_file"
)"
activation_tier="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$activation_record_file"
)"
activation_zoho="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Zoho record id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$activation_record_file"
)"
activation_tally="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tally response id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$activation_record_file"
)"

all_required_lanes_dispatched="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "All required lanes dispatched") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"
missing_lanes="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Missing lanes") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$dispatch_file"
)"

if [[ "$all_required_lanes_dispatched" != "yes" ]]; then
  echo "All required lanes dispatched is not yes: $all_required_lanes_dispatched" >&2
  exit 1
fi

if [[ "$missing_lanes" != "none" ]]; then
  echo "Missing lanes is not none: $missing_lanes" >&2
  exit 1
fi

if [[ "$dispatch_business" != "$activation_business" ]]; then
  echo "Dispatch and activation business fields do not match: $dispatch_business vs $activation_business" >&2
  exit 1
fi

if [[ "$dispatch_tier" != "$activation_tier" ]]; then
  echo "Dispatch and activation tier fields do not match: $dispatch_tier vs $activation_tier" >&2
  exit 1
fi

if [[ "$dispatch_zoho" != "$activation_zoho" ]]; then
  echo "Dispatch and activation Zoho record fields do not match: $dispatch_zoho vs $activation_zoho" >&2
  exit 1
fi

if [[ "$dispatch_tally" != "$activation_tally" ]]; then
  echo "Dispatch and activation Tally response fields do not match: $dispatch_tally vs $activation_tally" >&2
  exit 1
fi

for lane in Signal Ops-Chief Build Sentinel Strategy Finance Growth Archivist; do
  if ! rg -F "| $lane |" "$dispatch_file" | rg -F "| returned |" >/dev/null 2>&1; then
    echo "Dispatch receipt row is not marked returned for lane: $lane" >&2
    exit 1
  fi

  if ! rg -F -- "- $lane: received and logged" "$dispatch_file" >/dev/null 2>&1; then
    echo "Return status is not recorded as received and logged for lane: $lane" >&2
    exit 1
  fi
done

echo "AIReady research dispatch validated"
echo "workspace_root: $workspace_root"
echo "dispatch_file: $dispatch_file"
echo
echo "validated_dispatch_lanes:"
printf '  - %s\n' \
  "Signal" \
  "Ops-Chief" \
  "Build" \
  "Sentinel" \
  "Strategy" \
  "Finance" \
  "Growth" \
  "Archivist"
