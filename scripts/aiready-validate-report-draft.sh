#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-report-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise> [expected_slug]

Validates that the tier-relevant AIReady report draft file exists, is
populated, and reflects the current scored priorities promised by the live
delivery workflow.
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
tier="$2"
expected_slug="${3:-$(basename "$workspace_root")}"
draft_root="$workspace_root/04_Report_Draft"
summary_file="$workspace_root/03_Scoring/priority-summary.md"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"

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

require_literal() {
  local needle="$1"
  local file="$2"
  if ! rg -Fq -- "$needle" "$file"; then
    echo "Missing required text in $file: $needle" >&2
    exit 1
  fi
}

require_numbered_items() {
  local count="$1"
  local file="$2"
  local i
  for ((i = 1; i <= count; i++)); do
    if ! rg -q "^${i}\\. .+\\S" "$file"; then
      echo "Missing populated numbered item ${i} in $file" >&2
      exit 1
    fi
  done
}

extract_numbered_item() {
  local idx="$1"
  local file="$2"
  awk -v idx="$idx" '
    $0 ~ ("^" idx "\\. ") {
      sub("^" idx "\\. ", "", $0)
      print
      exit
    }
  ' "$file"
}

if [[ ! -d "$workspace_root" ]]; then
  echo "Workspace root not found: $workspace_root" >&2
  exit 1
fi

if [[ ! -d "$draft_root" ]]; then
  echo "Report draft root not found: $draft_root" >&2
  exit 1
fi

if [[ ! -f "$summary_file" ]]; then
  echo "Priority summary not found: $summary_file" >&2
  exit 1
fi

if [[ ! -f "$activation_record_file" ]]; then
  echo "Activation record not found: $activation_record_file" >&2
  exit 1
fi

case "$tier" in
  Starter)
    draft_file="$draft_root/${expected_slug}-aiready-starter-report-draft.md"
    required_headings=(
      "## Executive summary"
      "## Readiness snapshot"
      "## Prioritised opportunity list"
      "## Tool recommendations"
      "## 90-day starter plan"
      "## Sources and assumptions appendix"
    )
    required_tier_line="- Tier: Starter"
    numbered_items_required=3
    extra_value_labels=(
      "Business"
      "Client"
      "Zoho record id"
      "Draft owner"
      "Draft date"
      "Business context"
      "Top readiness finding"
      "Best first move"
      "Overall readiness"
      "Top constraints"
      "What to do first"
      "What not to do yet"
      "Workflow 1"
      "Workflow 2"
      "Workflow 3"
      "Opportunity 1"
      "Opportunity 2"
      "Opportunity 3"
      "Tool"
      "Indicative pricing"
      "Why it fits"
      "Days 0-30"
      "Days 31-60"
      "Days 61-90"
      "Verified sources"
      "Assumptions"
      "Main risks"
      "Main assumptions"
    )
    ;;
  Business)
    draft_file="$draft_root/${expected_slug}-aiready-business-report-draft.md"
    required_headings=(
      "## Executive summary"
      "## Operations map"
      "## Effort vs impact view"
      "## Tool and integration notes"
      "## 90-day implementation plan"
      "## Walkthrough and follow-up prep"
    )
    required_tier_line="- Tier: Business"
    numbered_items_required=5
    extra_value_labels=(
      "Business"
      "Client"
      "Zoho record id"
      "Draft owner"
      "Draft date"
      "Business context"
      "Top readiness finding"
      "Best 90-day direction"
      "Overall readiness"
      "Main leverage areas"
      "Main constraints"
      "Front office"
      "Back office"
      "Reporting"
      "Handoffs"
      "Opportunity 1"
      "Opportunity 2"
      "Opportunity 3"
      "Opportunity 4"
      "Opportunity 5"
      "Quick wins"
      "Medium-lift leverage plays"
      "Higher-complexity strategic plays"
      "Tool"
      "Integration dependency"
      "Change risk"
      "Days 0-30"
      "Days 31-60"
      "Days 61-90"
      "Walkthrough agenda"
      "30-day Q&A notes"
      "Main risks"
      "Main assumptions"
    )
    ;;
  Enterprise)
    draft_file="$draft_root/${expected_slug}-aiready-enterprise-report-draft.md"
    required_headings=(
      "## Leadership summary"
      "## Stakeholder and system context"
      "## Integration and governance notes"
      "## Vendor shortlist"
      "## 90-day and strategic roadmap"
      "## Board brief and follow-up prep"
    )
    required_tier_line="- Tier: Enterprise"
    numbered_items_required=0
    extra_value_labels=(
      "Business"
      "Client"
      "Zoho record id"
      "Draft owner"
      "Draft date"
      "Business context"
      "Transformation case"
      "Highest-priority decision"
      "Stakeholder interviews completed"
      "Core business systems"
      "Compliance or privacy constraints"
      "Highest-value opportunities"
      "Highest-confidence opportunities"
      "Deferred opportunities"
      "Priority 1"
      "Priority 2"
      "Priority 3"
      "Watchlist"
      "Integration architecture notes"
      "Governance controls"
      "Human-review boundaries"
      "Vendor"
      "Why shortlisted"
      "Key caveat"
      "Days 0-30"
      "Days 31-60"
      "Days 61-90"
      "6-12 month direction"
      "Board brief status"
      "60-day Q&A notes"
      "Main risks"
      "Main assumptions"
    )
    ;;
  *)
    echo "Invalid tier: $tier" >&2
    exit 1
    ;;
esac

if [[ ! -f "$draft_file" ]]; then
  echo "Missing draft file: $draft_file" >&2
  exit 1
fi

if rg -n '<[A-Za-z0-9_ -]+>' "$draft_file" >/dev/null 2>&1; then
  echo "Template placeholder token remains in $draft_file" >&2
  exit 1
fi

if ! rg -Fq -- "$required_tier_line" "$draft_file"; then
  echo "Draft file does not contain the expected tier line: $required_tier_line" >&2
  exit 1
fi

for label in "${extra_value_labels[@]}"; do
  require_value_line "$label" "$draft_file"
done

for heading in "${required_headings[@]}"; do
  if ! rg -Fq -- "$heading" "$draft_file"; then
    echo "Missing required heading in draft: $heading" >&2
    exit 1
  fi
done

if [[ "$numbered_items_required" -gt 0 ]]; then
  require_numbered_items "$numbered_items_required" "$draft_file"
fi

priority_1="$(extract_value_line "Opportunity" "$summary_file")"
priority_2="$(extract_value_line "Opportunity" <(awk 'found && /^## /{exit} /^## Priority 2$/{found=1; next} found{print}' "$summary_file"))"
priority_3="$(extract_value_line "Opportunity" <(awk 'found && /^## /{exit} /^## Priority 3$/{found=1; next} found{print}' "$summary_file"))"
watchlist_item="$(extract_value_line "Item" "$summary_file")"
summary_business="$(extract_value_line "Business" "$summary_file")"
summary_tier="$(extract_value_line "Tier" "$summary_file")"
draft_business="$(extract_value_line "Business" "$draft_file")"
draft_client="$(extract_value_line "Client" "$draft_file")"
draft_zoho_record_id="$(extract_value_line "Zoho record id" "$draft_file")"
draft_opportunity_1="$(extract_value_line "Opportunity 1" "$draft_file")"
draft_opportunity_2="$(extract_value_line "Opportunity 2" "$draft_file")"
draft_opportunity_3="$(extract_value_line "Opportunity 3" "$draft_file")"
activation_client="$(extract_value_line "Client" "$activation_record_file")"
activation_business="$(extract_value_line "Business" "$activation_record_file")"
activation_tier="$(extract_value_line "Tier" "$activation_record_file")"
activation_zoho_record_id="$(extract_value_line "Zoho record id" "$activation_record_file")"

if [[ "$draft_business" != "$summary_business" ]]; then
  echo "Draft business does not match priority summary in $draft_file" >&2
  exit 1
fi

if [[ "$summary_tier" != "$tier" ]]; then
  echo "Priority summary tier does not match requested tier in $summary_file" >&2
  exit 1
fi

if [[ "$activation_business" != "$summary_business" ]]; then
  echo "Activation record business does not match priority summary in $activation_record_file" >&2
  exit 1
fi

if [[ "$activation_tier" != "$tier" ]]; then
  echo "Activation record tier does not match requested tier in $activation_record_file" >&2
  exit 1
fi

if [[ "$draft_client" != "$activation_client" ]]; then
  echo "Draft client does not match activation record in $draft_file" >&2
  exit 1
fi

if [[ "$draft_zoho_record_id" != "$activation_zoho_record_id" ]]; then
  echo "Draft Zoho record id does not match activation record in $draft_file" >&2
  exit 1
fi

for value in "$priority_1" "$priority_2" "$priority_3"; do
  if [[ -z "${value:-}" ]]; then
    echo "Priority summary is missing one of the top three opportunities: $summary_file" >&2
    exit 1
  fi
  require_literal "$value" "$draft_file"
done

if [[ "$tier" != "Enterprise" ]]; then
  if [[ "$draft_opportunity_1" != "$priority_1" ]]; then
    echo "Draft Opportunity 1 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$draft_opportunity_2" != "$priority_2" ]]; then
    echo "Draft Opportunity 2 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$draft_opportunity_3" != "$priority_3" ]]; then
    echo "Draft Opportunity 3 does not match priority summary in $draft_file" >&2
    exit 1
  fi
fi

if [[ "$tier" != "Enterprise" ]]; then
  numbered_priority_1="$(extract_numbered_item 1 "$draft_file")"
  numbered_priority_2="$(extract_numbered_item 2 "$draft_file")"
  numbered_priority_3="$(extract_numbered_item 3 "$draft_file")"

  if [[ "$numbered_priority_1" != "$priority_1" ]]; then
    echo "Draft numbered item 1 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$numbered_priority_2" != "$priority_2" ]]; then
    echo "Draft numbered item 2 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$numbered_priority_3" != "$priority_3" ]]; then
    echo "Draft numbered item 3 does not match priority summary in $draft_file" >&2
    exit 1
  fi
fi

if [[ "$tier" == "Enterprise" ]]; then
  draft_priority_1="$(extract_value_line "Priority 1" "$draft_file")"
  draft_priority_2="$(extract_value_line "Priority 2" "$draft_file")"
  draft_priority_3="$(extract_value_line "Priority 3" "$draft_file")"
  draft_watchlist="$(extract_value_line "Watchlist" "$draft_file")"

  if [[ "$draft_priority_1" != "$priority_1" ]]; then
    echo "Draft Priority 1 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$draft_priority_2" != "$priority_2" ]]; then
    echo "Draft Priority 2 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ "$draft_priority_3" != "$priority_3" ]]; then
    echo "Draft Priority 3 does not match priority summary in $draft_file" >&2
    exit 1
  fi

  if [[ -z "${watchlist_item:-}" ]]; then
    echo "Priority summary is missing watchlist item: $summary_file" >&2
    exit 1
  fi

  if [[ "$draft_watchlist" != "$watchlist_item" ]]; then
    echo "Draft Watchlist does not match priority summary in $draft_file" >&2
    exit 1
  fi

  require_literal "$watchlist_item" "$draft_file"
fi

echo "AIReady report draft validated"
echo "workspace_root: $workspace_root"
echo "tier: $tier"
echo "business_slug: $expected_slug"
echo "draft_file: $draft_file"
echo "summary_file: $summary_file"
echo
echo "validated_headings:"
printf '  - %s\n' "${required_headings[@]}"
echo
echo "validated_priority_alignment:"
printf '  - %s\n' \
  "$priority_1" \
  "$priority_2" \
  "$priority_3"
