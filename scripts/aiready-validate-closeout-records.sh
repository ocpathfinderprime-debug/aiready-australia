#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-closeout-records.sh /path/to/Clients/business-slug [expected_slug]

Validates that the AIReady QA gate and delivery checklist are fully completed
before a live delivery is treated as release-ready.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
expected_slug="${2:-$(basename "$workspace_root")}"
qa_file="$workspace_root/05_QA/qa-gate-checklist.md"
delivery_file="$workspace_root/06_Delivery/delivery-package-checklist.md"
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

require_file "$qa_file"
require_file "$delivery_file"
require_file "$activation_record_file"

if rg -n '^- \[ \]' "$qa_file" "$delivery_file" >/dev/null 2>&1; then
  echo "Unchecked checklist items remain in QA or delivery records" >&2
  exit 1
fi

require_value_line "Business" "$qa_file"
require_value_line "Tier" "$qa_file"
require_value_line "Reviewer" "$qa_file"
require_value_line "Review date" "$qa_file"
require_value_line "Status" "$qa_file"
require_value_line "Timestamp" "$qa_file"
require_value_line "Rework required" "$qa_file"
require_value_line "Release decision" "$qa_file"

require_value_line "Business" "$delivery_file"
require_value_line "Client" "$delivery_file"
require_value_line "Tier" "$delivery_file"
require_value_line "Zoho record id" "$delivery_file"
require_value_line "Delivery date" "$delivery_file"
require_value_line "Delivery channel" "$delivery_file"
require_value_line "Follow-up window" "$delivery_file"
require_value_line "Follow-up due" "$delivery_file"
require_value_line "Owner" "$delivery_file"
require_value_line "Report" "$delivery_file"
require_value_line "Email draft" "$delivery_file"
require_value_line "Supporting files" "$delivery_file"
require_value_line "Tier-specific deliverables checked" "$delivery_file"
require_value_line "File names checked against naming convention" "$delivery_file"
require_value_line "Final handoff ready" "$delivery_file"
require_value_line "Client" "$activation_record_file"
require_value_line "Business" "$activation_record_file"
require_value_line "Tier" "$activation_record_file"
require_value_line "Zoho record id" "$activation_record_file"

qa_business="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Business") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"
qa_tier="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"
qa_reviewer="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Reviewer") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"
delivery_business="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Business") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
delivery_client="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Client") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
tier_value="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
delivery_zoho="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Zoho record id") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
activation_client="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Client") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$activation_record_file"
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
delivery_owner="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Owner") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
report_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Report") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
email_draft_path="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Email draft") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
follow_up_window="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Follow-up window") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
follow_up_due="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Follow-up due") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
delivery_channel="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Delivery channel") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
supporting_files="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Supporting files") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
tier_checked="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Tier-specific deliverables checked") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
naming_checked="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "File names checked against naming convention") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
handoff_ready="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Final handoff ready") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$delivery_file"
)"
qa_status="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Status") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"
qa_rework_required="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Rework required") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"
qa_release_decision="$(
  awk -F': ' '
    {
      key = $1
      sub(/^- /, "", key)
      if (key == "Release decision") {
        print substr($0, index($0, ": ") + 2)
        exit
      }
    }
  ' "$qa_file"
)"

if [[ "$qa_business" != "$delivery_business" ]]; then
  echo "QA and delivery business fields do not match: $qa_business vs $delivery_business" >&2
  exit 1
fi

if [[ "$qa_business" != "$activation_business" ]]; then
  echo "QA and activation business fields do not match: $qa_business vs $activation_business" >&2
  exit 1
fi

if [[ "$delivery_client" != "$activation_client" ]]; then
  echo "Delivery and activation client fields do not match: $delivery_client vs $activation_client" >&2
  exit 1
fi

if [[ "$qa_tier" != "$tier_value" ]]; then
  echo "QA and delivery tier fields do not match: $qa_tier vs $tier_value" >&2
  exit 1
fi

if [[ "$qa_tier" != "$activation_tier" ]]; then
  echo "QA and activation tier fields do not match: $qa_tier vs $activation_tier" >&2
  exit 1
fi

if [[ "$delivery_zoho" != "$activation_zoho" ]]; then
  echo "Delivery and activation Zoho record fields do not match: $delivery_zoho vs $activation_zoho" >&2
  exit 1
fi

if [[ "$qa_reviewer" != "$delivery_owner" ]]; then
  echo "QA reviewer and delivery owner do not match: $qa_reviewer vs $delivery_owner" >&2
  exit 1
fi

if [[ "$qa_status" != "pass" ]]; then
  echo "QA gate status is not pass: $qa_status" >&2
  exit 1
fi

if [[ "$qa_rework_required" != "none" ]]; then
  echo "QA gate rework field is not none: $qa_rework_required" >&2
  exit 1
fi

if [[ "$qa_release_decision" != "approved for delivery" ]]; then
  echo "QA gate release decision is not approved for delivery: $qa_release_decision" >&2
  exit 1
fi

if [[ "$delivery_channel" != "email" ]]; then
  echo "Delivery channel is not email: $delivery_channel" >&2
  exit 1
fi

case "$tier_checked" in
  yes|Yes) ;;
  *)
    echo "Tier-specific deliverables check is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

case "$naming_checked" in
  yes|Yes) ;;
  *)
    echo "Naming convention check is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

case "$handoff_ready" in
  yes|Yes) ;;
  *)
    echo "Final handoff readiness is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

if [[ "$report_path" != "/Clients/$expected_slug/06_Delivery/${expected_slug}-aiready-report-final.pdf" ]]; then
  echo "Report path mismatch in $delivery_file: $report_path" >&2
  exit 1
fi

if [[ "$email_draft_path" != "/Clients/$expected_slug/06_Delivery/${expected_slug}-delivery-email-draft.md" ]]; then
  echo "Email draft path mismatch in $delivery_file: $email_draft_path" >&2
  exit 1
fi

case "$report_path" in
  *"${expected_slug}-aiready-report-final.pdf"*) ;;
  *)
    echo "Report path does not reference the expected final report name for $expected_slug" >&2
    exit 1
    ;;
esac

case "$email_draft_path" in
  *"${expected_slug}-delivery-email-draft.md"*) ;;
  *)
    echo "Email draft path does not reference the expected delivery email name for $expected_slug" >&2
    exit 1
    ;;
esac

case "$supporting_files" in
  *"${expected_slug}-evidence-appendix.pdf"*) ;;
  *)
    echo "Supporting files do not reference the expected evidence appendix for $expected_slug" >&2
    exit 1
    ;;
esac

case "$tier_value" in
  Starter)
    if [[ "$follow_up_window" != "No included follow-up support" ]]; then
      echo "Starter closeout has invalid follow-up window: $follow_up_window" >&2
      exit 1
    fi
    if [[ "$follow_up_due" != "not scheduled - starter tier has no included follow-up" ]]; then
      echo "Starter closeout has invalid follow-up due value: $follow_up_due" >&2
      exit 1
    fi
    case "$supporting_files" in
      *"${expected_slug}-executive-summary.pdf"*) ;;
      *)
        echo "Supporting files do not reference the expected starter executive summary for $expected_slug" >&2
        exit 1
        ;;
    esac
    ;;
  Business)
    if [[ "$follow_up_window" != "30-day Q&A by email" ]]; then
      echo "Business closeout has invalid follow-up window: $follow_up_window" >&2
      exit 1
    fi
    case "$follow_up_due" in
      20[0-9][0-9]-[01][0-9]-[0-3][0-9]) ;;
      *)
        echo "Business closeout has invalid follow-up due value: $follow_up_due" >&2
        exit 1
        ;;
    esac
    ;;
  Enterprise)
    if [[ "$follow_up_window" != "60-day Q&A by email" ]]; then
      echo "Enterprise closeout has invalid follow-up window: $follow_up_window" >&2
      exit 1
    fi
    case "$follow_up_due" in
      20[0-9][0-9]-[01][0-9]-[0-3][0-9]) ;;
      *)
        echo "Enterprise closeout has invalid follow-up due value: $follow_up_due" >&2
        exit 1
        ;;
    esac
    case "$supporting_files" in
      *"${expected_slug}-board-brief.pdf"*) ;;
      *)
        echo "Supporting files do not reference the expected enterprise board brief for $expected_slug" >&2
        exit 1
        ;;
    esac
    case "$supporting_files" in
      *"${expected_slug}-integration-map.pdf"*) ;;
      *)
        echo "Supporting files do not reference the expected enterprise integration map for $expected_slug" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Delivery checklist contains invalid tier: $tier_value" >&2
    exit 1
    ;;
esac

echo "AIReady closeout records validated"
echo "workspace_root: $workspace_root"
echo "business_slug: $expected_slug"
echo
echo "validated_records:"
printf '  - %s\n' \
  "05_QA/qa-gate-checklist.md" \
  "06_Delivery/delivery-package-checklist.md"
