#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-delivery-package.sh /path/to/Clients/business-slug <Starter|Business|Enterprise> [expected_slug]

Validates that an AIReady delivery package contains the minimum tier-matched
final artifacts, including the evidence appendix lane used by the live dry-run
workflow, and that their file names follow the live naming convention.
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
tier="$2"
expected_slug="${3:-$(basename "$workspace_root")}"
delivery_root="$workspace_root/06_Delivery"
checklist_file="$delivery_root/delivery-package-checklist.md"
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

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
}

require_nonempty_file() {
  local path="$1"
  require_file "$path"
  if [[ ! -s "$path" ]]; then
    echo "File is empty: $path" >&2
    exit 1
  fi
}

collect_supporting_basenames() {
  local raw="$1"
  local part

  while IFS= read -r part; do
    [[ -n "$part" ]] || continue
    basename "$part"
  done < <(printf '%s\n' "$raw" | awk -F', ' '{ for (i = 1; i <= NF; i++) print $i }' | sed 's/^ *//; s/ *$//')
}

if [[ ! -d "$workspace_root" ]]; then
  echo "Workspace root not found: $workspace_root" >&2
  exit 1
fi

if [[ ! -d "$delivery_root" ]]; then
  echo "Delivery root not found: $delivery_root" >&2
  exit 1
fi

case "$tier" in
  Starter|Business|Enterprise) ;;
  *)
    echo "Invalid tier: $tier" >&2
    exit 1
    ;;
esac

require_nonempty_file "$delivery_root/${expected_slug}-aiready-report-final.pdf"
require_nonempty_file "$delivery_root/${expected_slug}-delivery-email-draft.md"
require_nonempty_file "$delivery_root/${expected_slug}-evidence-appendix.pdf"
require_nonempty_file "$delivery_root/delivery-package-checklist.md"
require_file "$activation_record_file"

extra_artifacts=()
expected_supporting_basenames=("${expected_slug}-evidence-appendix.pdf")

case "$tier" in
  Starter)
    expected_supporting_basenames+=("${expected_slug}-executive-summary.pdf")
    require_nonempty_file "$delivery_root/${expected_slug}-executive-summary.pdf"
    extra_artifacts+=("${expected_slug}-executive-summary.pdf")
    ;;
  Business)
    ;;
  Enterprise)
    expected_supporting_basenames+=(
      "${expected_slug}-board-brief.pdf"
      "${expected_slug}-integration-map.pdf"
    )
    require_nonempty_file "$delivery_root/${expected_slug}-board-brief.pdf"
    require_nonempty_file "$delivery_root/${expected_slug}-integration-map.pdf"
    extra_artifacts+=(
      "${expected_slug}-board-brief.pdf"
      "${expected_slug}-integration-map.pdf"
    )
    ;;
esac

require_value_line "Business" "$checklist_file"
require_value_line "Client" "$checklist_file"
require_value_line "Tier" "$checklist_file"
require_value_line "Zoho record id" "$checklist_file"
require_value_line "Delivery date" "$checklist_file"
require_value_line "Delivery channel" "$checklist_file"
require_value_line "Follow-up window" "$checklist_file"
require_value_line "Follow-up due" "$checklist_file"
require_value_line "Owner" "$checklist_file"
require_value_line "Report" "$checklist_file"
require_value_line "Email draft" "$checklist_file"
require_value_line "Supporting files" "$checklist_file"
require_value_line "Tier-specific deliverables checked" "$checklist_file"
require_value_line "File names checked against naming convention" "$checklist_file"
require_value_line "Final handoff ready" "$checklist_file"
require_value_line "Business" "$activation_record_file"
require_value_line "Client" "$activation_record_file"
require_value_line "Tier" "$activation_record_file"
require_value_line "Zoho record id" "$activation_record_file"

checklist_business="$(extract_value_line "Business" "$checklist_file")"
checklist_client="$(extract_value_line "Client" "$checklist_file")"
checklist_tier="$(extract_value_line "Tier" "$checklist_file")"
checklist_zoho="$(extract_value_line "Zoho record id" "$checklist_file")"
report_path="$(extract_value_line "Report" "$checklist_file")"
email_draft_path="$(extract_value_line "Email draft" "$checklist_file")"
supporting_files="$(extract_value_line "Supporting files" "$checklist_file")"
follow_up_window="$(extract_value_line "Follow-up window" "$checklist_file")"
follow_up_due="$(extract_value_line "Follow-up due" "$checklist_file")"
delivery_channel="$(extract_value_line "Delivery channel" "$checklist_file")"
tier_checked="$(extract_value_line "Tier-specific deliverables checked" "$checklist_file")"
naming_checked="$(extract_value_line "File names checked against naming convention" "$checklist_file")"
handoff_ready="$(extract_value_line "Final handoff ready" "$checklist_file")"
activation_business="$(extract_value_line "Business" "$activation_record_file")"
activation_client="$(extract_value_line "Client" "$activation_record_file")"
activation_tier="$(extract_value_line "Tier" "$activation_record_file")"
activation_zoho="$(extract_value_line "Zoho record id" "$activation_record_file")"
mapfile -t supporting_basenames < <(collect_supporting_basenames "$supporting_files")

if [[ "$checklist_business" != "$activation_business" ]]; then
  echo "Business mismatch between delivery checklist and activation record" >&2
  exit 1
fi

if [[ "$checklist_client" != "$activation_client" ]]; then
  echo "Client mismatch between delivery checklist and activation record" >&2
  exit 1
fi

if [[ "$checklist_tier" != "$tier" ]]; then
  echo "Tier mismatch in $checklist_file: expected $tier but found $checklist_tier" >&2
  exit 1
fi

if [[ "$activation_tier" != "$tier" ]]; then
  echo "Tier mismatch in $activation_record_file: expected $tier but found $activation_tier" >&2
  exit 1
fi

if [[ "$checklist_zoho" != "$activation_zoho" ]]; then
  echo "Zoho record mismatch between delivery checklist and activation record" >&2
  exit 1
fi

if [[ "$delivery_channel" != "email" ]]; then
  echo "Unexpected delivery channel in $checklist_file: $delivery_channel" >&2
  exit 1
fi

if [[ "$report_path" != "/Clients/$expected_slug/06_Delivery/${expected_slug}-aiready-report-final.pdf" ]]; then
  echo "Checklist report path mismatch in $checklist_file: $report_path" >&2
  exit 1
fi

if [[ "$email_draft_path" != "/Clients/$expected_slug/06_Delivery/${expected_slug}-delivery-email-draft.md" ]]; then
  echo "Checklist email draft path mismatch in $checklist_file: $email_draft_path" >&2
  exit 1
fi

if [[ ${#supporting_basenames[@]} -ne ${#expected_supporting_basenames[@]} ]]; then
  echo "Supporting files count mismatch in $checklist_file" >&2
  exit 1
fi

for expected_basename in "${expected_supporting_basenames[@]}"; do
  if [[ ! " ${supporting_basenames[*]} " =~ [[:space:]]${expected_basename}[[:space:]] ]]; then
    echo "Missing expected supporting file in $checklist_file: $expected_basename" >&2
    exit 1
  fi
done

case "$tier_checked" in
  yes|Yes) ;;
  *)
    echo "Tier-specific deliverables check is not complete in $checklist_file" >&2
    exit 1
    ;;
esac

case "$naming_checked" in
  yes|Yes) ;;
  *)
    echo "Naming convention check is not complete in $checklist_file" >&2
    exit 1
    ;;
esac

case "$handoff_ready" in
  yes|Yes) ;;
  *)
    echo "Final handoff readiness is not complete in $checklist_file" >&2
    exit 1
    ;;
esac

echo "AIReady delivery package validated"
echo "workspace_root: $workspace_root"
echo "tier: $tier"
echo "business_slug: $expected_slug"
echo
echo "validated_required_artifacts:"
printf '  - %s\n' \
  "06_Delivery/${expected_slug}-aiready-report-final.pdf" \
  "06_Delivery/${expected_slug}-delivery-email-draft.md" \
  "06_Delivery/${expected_slug}-evidence-appendix.pdf" \
  "06_Delivery/delivery-package-checklist.md"

if [[ ${#extra_artifacts[@]} -gt 0 ]]; then
  echo
  echo "validated_tier_specific_artifacts:"
  for artifact in "${extra_artifacts[@]}"; do
    printf '  - %s\n' "06_Delivery/$artifact"
  done
fi

case "$tier" in
  Starter)
    if [[ "$follow_up_window" != "No included follow-up support" ]]; then
      echo "Starter follow-up window mismatch in $checklist_file: $follow_up_window" >&2
      exit 1
    fi
    if [[ "$follow_up_due" != "not scheduled - starter tier has no included follow-up" ]]; then
      echo "Starter follow-up due mismatch in $checklist_file: $follow_up_due" >&2
      exit 1
    fi
    require_literal "${expected_slug}-executive-summary.pdf" "$checklist_file"
    ;;
  Business)
    if [[ "$follow_up_window" != "30-day Q&A by email" ]]; then
      echo "Business follow-up window mismatch in $checklist_file: $follow_up_window" >&2
      exit 1
    fi
    if [[ ! "$follow_up_due" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Business follow-up due is not a valid date in $checklist_file: $follow_up_due" >&2
      exit 1
    fi
    ;;
  Enterprise)
    if [[ "$follow_up_window" != "60-day Q&A by email" ]]; then
      echo "Enterprise follow-up window mismatch in $checklist_file: $follow_up_window" >&2
      exit 1
    fi
    if [[ ! "$follow_up_due" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Enterprise follow-up due is not a valid date in $checklist_file: $follow_up_due" >&2
      exit 1
    fi
    require_literal "${expected_slug}-board-brief.pdf" "$checklist_file"
    require_literal "${expected_slug}-integration-map.pdf" "$checklist_file"
    ;;
esac
