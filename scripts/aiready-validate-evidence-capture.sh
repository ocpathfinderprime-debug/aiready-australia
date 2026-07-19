#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-evidence-capture.sh /path/to/Clients/business-slug

Validates that the AIReady research returns, evidence index, sources log, and
assumptions register are populated enough to support a real first-intake lane.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"
evidence_index="$workspace_root/01_Evidence_Vault/evidence-index.md"
sources_log="$workspace_root/01_Evidence_Vault/sources-log.md"
assumptions_register="$workspace_root/01_Evidence_Vault/assumptions-register.md"
priority_summary="$workspace_root/03_Scoring/priority-summary.md"

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

require_file "$evidence_index"
require_file "$sources_log"
require_file "$assumptions_register"
require_file "$priority_summary"
require_file "$activation_record_file"

activation_business="$(extract_value_line "Business" "$activation_record_file")"
activation_client="$(extract_value_line "Client" "$activation_record_file")"
activation_tier="$(extract_value_line "Tier" "$activation_record_file")"

evidence_business="$(extract_value_line "Business" "$evidence_index")"
evidence_client="$(extract_value_line "Client" "$evidence_index")"
evidence_tier="$(extract_value_line "Tier" "$evidence_index")"
sources_business="$(extract_value_line "Business" "$sources_log")"
sources_tier="$(extract_value_line "Tier" "$sources_log")"
assumptions_business="$(extract_value_line "Business" "$assumptions_register")"
assumptions_tier="$(extract_value_line "Tier" "$assumptions_register")"

require_value_line "Business" "$evidence_index"
require_value_line "Client" "$evidence_index"
require_value_line "Tier" "$evidence_index"
require_value_line "Audit start" "$evidence_index"
require_value_line "Evidence owner" "$evidence_index"
require_value_line "Intake evidence" "$evidence_index"
require_value_line "Market and vendor evidence" "$evidence_index"
require_value_line "Workflow evidence" "$evidence_index"
require_value_line "Integration evidence" "$evidence_index"
require_value_line "Privacy and risk evidence" "$evidence_index"
require_value_line "ROI and cost evidence" "$evidence_index"
require_value_line "All major claims have evidence or are marked as assumptions" "$evidence_index"
require_value_line "Tier-critical recommendations have source coverage" "$evidence_index"
require_value_line "Evidence gaps still open" "$evidence_index"

require_value_line "Business" "$sources_log"
require_value_line "Tier" "$sources_log"
require_value_line "Maintained by" "$sources_log"
require_value_line "Official/vendor sources" "$sources_log"
require_value_line "Client-provided sources" "$sources_log"
require_value_line "Cross-checks completed" "$sources_log"

require_value_line "Business" "$assumptions_register"
require_value_line "Tier" "$assumptions_register"
require_value_line "Owner" "$assumptions_register"
require_value_line "Last updated" "$assumptions_register"
require_value_line "High-risk assumptions isolated" "$assumptions_register"
require_value_line "Items requiring client clarification" "$assumptions_register"
require_value_line "Items requiring human review" "$assumptions_register"

if [[ "$evidence_business" != "$activation_business" ]]; then
  echo "Business mismatch between evidence index and activation record" >&2
  exit 1
fi

if [[ "$evidence_client" != "$activation_client" ]]; then
  echo "Client mismatch between evidence index and activation record" >&2
  exit 1
fi

if [[ "$evidence_tier" != "$activation_tier" ]]; then
  echo "Tier mismatch between evidence index and activation record" >&2
  exit 1
fi

if [[ "$sources_business" != "$activation_business" ]]; then
  echo "Business mismatch between sources log and activation record" >&2
  exit 1
fi

if [[ "$sources_tier" != "$activation_tier" ]]; then
  echo "Tier mismatch between sources log and activation record" >&2
  exit 1
fi

if [[ "$assumptions_business" != "$activation_business" ]]; then
  echo "Business mismatch between assumptions register and activation record" >&2
  exit 1
fi

if [[ "$assumptions_tier" != "$activation_tier" ]]; then
  echo "Tier mismatch between assumptions register and activation record" >&2
  exit 1
fi

all_major_claims_covered="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "All major claims have evidence or are marked as assumptions") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$evidence_index"
)"
tier_critical_coverage="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier-critical recommendations have source coverage") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$evidence_index"
)"
evidence_gaps_open="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Evidence gaps still open") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$evidence_index"
)"
high_risk_assumptions_isolated="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "High-risk assumptions isolated") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$assumptions_register"
)"
items_requiring_client_clarification="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Items requiring client clarification") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$assumptions_register"
)"

if [[ "$all_major_claims_covered" != "yes" ]]; then
  echo "All major claims coverage flag is not yes: $all_major_claims_covered" >&2
  exit 1
fi

if [[ "$tier_critical_coverage" != "yes" ]]; then
  echo "Tier-critical recommendation coverage flag is not yes: $tier_critical_coverage" >&2
  exit 1
fi

case "$evidence_gaps_open" in
  none|none\ in\ dry\ run) ;;
  *)
    echo "Evidence gaps field is not closed: $evidence_gaps_open" >&2
    exit 1
    ;;
esac

if [[ "$high_risk_assumptions_isolated" != "yes" ]]; then
  echo "High-risk assumptions isolation flag is not yes: $high_risk_assumptions_isolated" >&2
  exit 1
fi

case "$items_requiring_client_clarification" in
  none|none\ in\ dry\ run) ;;
  *)
    echo "Client clarification field is not closed: $items_requiring_client_clarification" >&2
    exit 1
    ;;
esac

if ! rg -n '^\\| SRC-[0-9]{3} \\|' "$sources_log" >/dev/null 2>&1; then
  echo "No concrete source entries found in $sources_log" >&2
  exit 1
fi

if ! rg -n '^\\| ASM-[0-9]{3} \\|' "$assumptions_register" >/dev/null 2>&1; then
  echo "No concrete assumption entries found in $assumptions_register" >&2
  exit 1
fi

if ! rg -n '^\\| .+ \\| SRC-[0-9]{3}.+ \\|' "$evidence_index" >/dev/null 2>&1; then
  echo "No top recommendation evidence links found in $evidence_index" >&2
  exit 1
fi

priority_1="$(
  awk '
    /^## Priority 1$/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- Opportunity: / {
      sub(/^- Opportunity: /, "", $0)
      print
      exit
    }
  ' "$priority_summary"
)"
priority_2="$(
  awk '
    /^## Priority 2$/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- Opportunity: / {
      sub(/^- Opportunity: /, "", $0)
      print
      exit
    }
  ' "$priority_summary"
)"
priority_3="$(
  awk '
    /^## Priority 3$/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- Opportunity: / {
      sub(/^- Opportunity: /, "", $0)
      print
      exit
    }
  ' "$priority_summary"
)"

for priority in "$priority_1" "$priority_2" "$priority_3"; do
  if [[ -z "${priority:-}" ]]; then
    echo "Priority summary is missing one of the top three opportunities: $priority_summary" >&2
    exit 1
  fi
  if ! rg -Fq -- "$priority" "$evidence_index"; then
    echo "Evidence index does not reference scored priority: $priority" >&2
    exit 1
  fi
done

for return_file in "$workspace_root"/02_Research/*-return.md; do
  require_file "$return_file"
  require_value_line "Business" "$return_file"
  require_value_line "Tier" "$return_file"
  require_value_line "Returned by" "$return_file"
  require_value_line "Returned at" "$return_file"

  return_business="$(extract_value_line "Business" "$return_file")"
  return_tier="$(extract_value_line "Tier" "$return_file")"

  if [[ "$return_business" != "$activation_business" ]]; then
    echo "Business mismatch between research return and activation record: $return_file" >&2
    exit 1
  fi

  if [[ "$return_tier" != "$activation_tier" ]]; then
    echo "Tier mismatch between research return and activation record: $return_file" >&2
    exit 1
  fi
done

echo "AIReady evidence capture validated"
echo "workspace_root: $workspace_root"
echo "evidence_index: $evidence_index"
echo "sources_log: $sources_log"
echo "assumptions_register: $assumptions_register"
echo
echo "validated_capture_surfaces:"
printf '  - %s\n' \
  "research return files" \
  "evidence index" \
  "sources log" \
  "assumptions register"
