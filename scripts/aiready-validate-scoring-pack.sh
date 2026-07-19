#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-scoring-pack.sh /path/to/Clients/business-slug

Validates that the AIReady scoring pack contains a populated opportunity
register and priority summary suitable for the first-intake lane.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"
register_file="$workspace_root/03_Scoring/opportunity-register.md"
summary_file="$workspace_root/03_Scoring/priority-summary.md"

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

extract_section_value() {
  local heading="$1"
  local label="$2"
  local file="$3"
  awk -v heading="$heading" -v label="$label" '
    $0 == heading { in_section=1; next }
    in_section && /^## / { exit }
    in_section && index($0, "- " label ": ") == 1 {
      print substr($0, length(label) + 5)
      exit
    }
  ' "$file"
}

if [[ ! -d "$workspace_root" ]]; then
  echo "Workspace root not found: $workspace_root" >&2
  exit 1
fi

require_file "$register_file"
require_file "$summary_file"
require_file "$activation_record_file"

require_value_line "Business" "$register_file"
require_value_line "Tier" "$register_file"
require_value_line "Register owner" "$register_file"
require_value_line "Last updated" "$register_file"
require_value_line "Priority 1" "$register_file"
require_value_line "Priority 2" "$register_file"
require_value_line "Priority 3" "$register_file"
require_value_line "Watchlist" "$register_file"
require_value_line "Do not recommend now" "$register_file"
require_value_line "Assumption 1" "$register_file"
require_value_line "Assumption 2" "$register_file"
require_value_line "Tier cap respected" "$register_file"
require_value_line "All opportunities have evidence" "$register_file"
require_value_line "All opportunities have owner, effort, cost, risk, and milestone" "$register_file"

require_value_line "Business" "$summary_file"
require_value_line "Tier" "$summary_file"
require_value_line "Prepared by" "$summary_file"
require_value_line "Updated at" "$summary_file"
require_value_line "Opportunity" "$summary_file"
require_value_line "Why first" "$summary_file"
require_value_line "Why next" "$summary_file"
require_value_line "Why later" "$summary_file"
require_value_line "Item" "$summary_file"
require_value_line "Why deferred" "$summary_file"
require_value_line "Recommended first 90-day sequence" "$summary_file"
require_value_line "Dependencies or blockers" "$summary_file"
require_value_line "Human-review items" "$summary_file"

register_priority_1="$(extract_value_line "Priority 1" "$register_file")"
register_priority_2="$(extract_value_line "Priority 2" "$register_file")"
register_priority_3="$(extract_value_line "Priority 3" "$register_file")"
register_watchlist="$(extract_value_line "Watchlist" "$register_file")"
activation_business="$(extract_value_line "Business" "$activation_record_file")"
activation_tier="$(extract_value_line "Tier" "$activation_record_file")"
register_business="$(extract_value_line "Business" "$register_file")"
register_tier="$(extract_value_line "Tier" "$register_file")"
register_owner="$(extract_value_line "Register owner" "$register_file")"
register_tier_cap_respected="$(extract_value_line "Tier cap respected" "$register_file")"
register_all_opportunities_have_evidence="$(extract_value_line "All opportunities have evidence" "$register_file")"
register_all_opportunities_have_complete_fields="$(extract_value_line "All opportunities have owner, effort, cost, risk, and milestone" "$register_file")"
summary_business="$(extract_value_line "Business" "$summary_file")"
summary_tier="$(extract_value_line "Tier" "$summary_file")"
summary_prepared_by="$(extract_value_line "Prepared by" "$summary_file")"

summary_priority_1="$(extract_section_value "## Priority 1" "Opportunity" "$summary_file")"
summary_priority_2="$(extract_section_value "## Priority 2" "Opportunity" "$summary_file")"
summary_priority_3="$(extract_section_value "## Priority 3" "Opportunity" "$summary_file")"
summary_watchlist="$(extract_section_value "## Watchlist / not now" "Item" "$summary_file")"

for value_name in summary_priority_1 summary_priority_2 summary_priority_3 summary_watchlist; do
  if [[ -z "${!value_name:-}" ]]; then
    echo "Missing summary coherence field '$value_name' in $summary_file" >&2
    exit 1
  fi
done

if [[ "$register_priority_1" != "$summary_priority_1" ]]; then
  echo "Priority 1 mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_priority_2" != "$summary_priority_2" ]]; then
  echo "Priority 2 mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_priority_3" != "$summary_priority_3" ]]; then
  echo "Priority 3 mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_watchlist" != "$summary_watchlist" ]]; then
  echo "Watchlist mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_business" != "$summary_business" ]]; then
  echo "Business mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_business" != "$activation_business" ]]; then
  echo "Business mismatch between register and activation record" >&2
  exit 1
fi

if [[ "$summary_business" != "$activation_business" ]]; then
  echo "Business mismatch between summary and activation record" >&2
  exit 1
fi

if [[ "$register_tier" != "$summary_tier" ]]; then
  echo "Tier mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_tier" != "$activation_tier" ]]; then
  echo "Tier mismatch between register and activation record" >&2
  exit 1
fi

if [[ "$summary_tier" != "$activation_tier" ]]; then
  echo "Tier mismatch between summary and activation record" >&2
  exit 1
fi

if [[ "$register_owner" != "$summary_prepared_by" ]]; then
  echo "Owner mismatch between register and summary" >&2
  exit 1
fi

if [[ "$register_tier_cap_respected" != "yes" ]]; then
  echo "Tier cap respected flag is not yes: $register_tier_cap_respected" >&2
  exit 1
fi

if [[ "$register_all_opportunities_have_evidence" != "yes" ]]; then
  echo "All opportunities have evidence flag is not yes: $register_all_opportunities_have_evidence" >&2
  exit 1
fi

if [[ "$register_all_opportunities_have_complete_fields" != "yes" ]]; then
  echo "Opportunity completeness flag is not yes: $register_all_opportunities_have_complete_fields" >&2
  exit 1
fi

if ! rg -n '^\\| [0-9]+ \\|' "$register_file" >/dev/null 2>&1; then
  echo "No populated opportunity rows found in $register_file" >&2
  exit 1
fi

if ! rg -n '^\\| [0-9]+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\| .+ \\|$' "$register_file" >/dev/null 2>&1; then
  echo "Opportunity rows in $register_file do not appear fully populated" >&2
  exit 1
fi

extract_priority_score() {
  local opportunity="$1"
  local file="$2"
  awk -F'|' -v opportunity="$opportunity" '
    /^\| [0-9]+ \|/ {
      row_opportunity = $3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", row_opportunity)
      if (row_opportunity == opportunity) {
        score = $14
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", score)
        print score
        exit
      }
    }
  ' "$file"
}

priority_1_score="$(extract_priority_score "$register_priority_1" "$register_file")"
priority_2_score="$(extract_priority_score "$register_priority_2" "$register_file")"
priority_3_score="$(extract_priority_score "$register_priority_3" "$register_file")"

for score_name in priority_1_score priority_2_score priority_3_score; do
  if [[ -z "${!score_name:-}" ]]; then
    echo "Missing priority score for $score_name in $register_file" >&2
    exit 1
  fi
  if ! [[ "${!score_name}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Priority score is not numeric for $score_name: ${!score_name}" >&2
    exit 1
  fi
done

if ! awk -v p1="$priority_1_score" -v p2="$priority_2_score" -v p3="$priority_3_score" 'BEGIN { exit !(p1 >= p2 && p2 >= p3) }'; then
  echo "Priority scores are not ordered P1 >= P2 >= P3: $priority_1_score, $priority_2_score, $priority_3_score" >&2
  exit 1
fi

echo "AIReady scoring pack validated"
echo "workspace_root: $workspace_root"
echo "register_file: $register_file"
echo "summary_file: $summary_file"
echo
echo "validated_scoring_surfaces:"
printf '  - %s\n' \
  "opportunity register" \
  "priority summary"
