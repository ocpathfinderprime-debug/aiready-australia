#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-delivery-email-draft.sh /path/to/Clients/business-slug <Starter|Business|Enterprise> [expected_slug]

Validates that the AIReady delivery email draft is populated, free of template
placeholders, and aligned to the tier-specific follow-up promise.
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$1"
tier="$2"
expected_slug="${3:-$(basename "$workspace_root")}"
delivery_file="$workspace_root/06_Delivery/${expected_slug}-delivery-email-draft.md"
checklist_file="$workspace_root/06_Delivery/delivery-package-checklist.md"
activation_record_file="$workspace_root/00_Intake/trigger-and-activation-record.md"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
}

get_value_line() {
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
  value="$(get_value_line "$label" "$file")"
  if [[ -z "${value:-}" ]]; then
    echo "Missing or empty field '$label' in $file" >&2
    exit 1
  fi
}

require_contains() {
  local needle="$1"
  local file="$2"
  if ! rg -F --quiet "$needle" "$file"; then
    echo "Expected text not found in $file: $needle" >&2
    exit 1
  fi
}

if [[ ! -d "$workspace_root" ]]; then
  echo "Workspace root not found: $workspace_root" >&2
  exit 1
fi

case "$tier" in
  Starter|Business|Enterprise) ;;
  *)
    echo "Invalid tier: $tier" >&2
    exit 1
    ;;
esac

require_file "$delivery_file"
require_file "$checklist_file"
require_file "$activation_record_file"

if rg -n '<[A-Za-z0-9_ -]+>' "$delivery_file" >/dev/null 2>&1; then
  echo "Template placeholder token remains in $delivery_file" >&2
  exit 1
fi

require_value_line "Business" "$delivery_file"
require_value_line "Client" "$delivery_file"
require_value_line "Email" "$delivery_file"
require_value_line "Tier" "$delivery_file"
require_value_line "Zoho record id" "$delivery_file"
require_value_line "Delivery owner" "$delivery_file"
require_value_line "Delivery date" "$delivery_file"
require_value_line "Attachment 1" "$delivery_file"
require_value_line "Attachment 2" "$delivery_file"
require_value_line "Tier-specific attachments present" "$delivery_file"
require_value_line "Naming checked" "$delivery_file"
require_value_line "Follow-up expectation stated" "$delivery_file"
require_value_line "Business" "$checklist_file"
require_value_line "Client" "$checklist_file"
require_value_line "Tier" "$checklist_file"
require_value_line "Zoho record id" "$checklist_file"
require_value_line "Delivery date" "$checklist_file"
require_value_line "Owner" "$checklist_file"
require_value_line "Follow-up window" "$checklist_file"
require_value_line "Follow-up due" "$checklist_file"
require_value_line "Report" "$checklist_file"
require_value_line "Email draft" "$checklist_file"
require_value_line "Supporting files" "$checklist_file"
require_value_line "Client" "$activation_record_file"
require_value_line "Business" "$activation_record_file"
require_value_line "Tier" "$activation_record_file"
require_value_line "Zoho record id" "$activation_record_file"

business_value="$(get_value_line "Business" "$delivery_file")"
client_value="$(get_value_line "Client" "$delivery_file")"
tier_checklist="$(get_value_line "Tier" "$checklist_file")"
tier_value="$(get_value_line "Tier" "$delivery_file")"
zoho_value="$(get_value_line "Zoho record id" "$delivery_file")"
delivery_owner_value="$(get_value_line "Delivery owner" "$delivery_file")"
delivery_date_value="$(get_value_line "Delivery date" "$delivery_file")"
attachment_1="$(get_value_line "Attachment 1" "$delivery_file")"
attachment_2="$(get_value_line "Attachment 2" "$delivery_file")"
tier_specific_attachments="$(get_value_line "Tier-specific attachments present" "$delivery_file")"
naming_checked="$(get_value_line "Naming checked" "$delivery_file")"
follow_up_stated="$(get_value_line "Follow-up expectation stated" "$delivery_file")"
checklist_business="$(get_value_line "Business" "$checklist_file")"
checklist_client="$(get_value_line "Client" "$checklist_file")"
checklist_zoho="$(get_value_line "Zoho record id" "$checklist_file")"
checklist_owner="$(get_value_line "Owner" "$checklist_file")"
checklist_delivery_date="$(get_value_line "Delivery date" "$checklist_file")"
checklist_follow_up_window="$(get_value_line "Follow-up window" "$checklist_file")"
checklist_follow_up_due="$(get_value_line "Follow-up due" "$checklist_file")"
checklist_report_path="$(get_value_line "Report" "$checklist_file")"
checklist_email_path="$(get_value_line "Email draft" "$checklist_file")"
checklist_supporting_files="$(get_value_line "Supporting files" "$checklist_file")"
activation_client="$(get_value_line "Client" "$activation_record_file")"
activation_business="$(get_value_line "Business" "$activation_record_file")"
activation_tier="$(get_value_line "Tier" "$activation_record_file")"
activation_zoho="$(get_value_line "Zoho record id" "$activation_record_file")"

if [[ "$business_value" != "$checklist_business" ]]; then
  echo "Business mismatch between delivery email and checklist" >&2
  exit 1
fi

if [[ "$business_value" != "$activation_business" ]]; then
  echo "Business mismatch between delivery email and activation record" >&2
  exit 1
fi

if [[ "$client_value" != "$checklist_client" ]]; then
  echo "Client mismatch between delivery email and checklist" >&2
  exit 1
fi

if [[ "$client_value" != "$activation_client" ]]; then
  echo "Client mismatch between delivery email and activation record" >&2
  exit 1
fi

if [[ "$zoho_value" != "$checklist_zoho" ]]; then
  echo "Zoho record mismatch between delivery email and checklist" >&2
  exit 1
fi

if [[ "$zoho_value" != "$activation_zoho" ]]; then
  echo "Zoho record mismatch between delivery email and activation record" >&2
  exit 1
fi

if [[ "$delivery_owner_value" != "$checklist_owner" ]]; then
  echo "Delivery owner mismatch between delivery email and checklist" >&2
  exit 1
fi

if [[ "$delivery_date_value" != "$checklist_delivery_date" ]]; then
  echo "Delivery date mismatch between delivery email and checklist" >&2
  exit 1
fi

if [[ "$tier_value" != "$tier" ]]; then
  echo "Tier mismatch in $delivery_file: expected $tier but found $tier_value" >&2
  exit 1
fi

if [[ "$tier_checklist" != "$tier" ]]; then
  echo "Tier mismatch in $checklist_file: expected $tier but found $tier_checklist" >&2
  exit 1
fi

if [[ "$activation_tier" != "$tier" ]]; then
  echo "Tier mismatch in $activation_record_file: expected $tier but found $activation_tier" >&2
  exit 1
fi

case "$checklist_report_path" in
  *"${attachment_1}"*) ;;
  *)
    echo "Attachment 1 does not match checklist report path in $checklist_file" >&2
    exit 1
    ;;
esac

if [[ "$checklist_email_path" != "/Clients/$expected_slug/06_Delivery/${expected_slug}-delivery-email-draft.md" ]]; then
  echo "Checklist email path mismatch in $checklist_file: $checklist_email_path" >&2
  exit 1
fi

case "$attachment_1" in
  *"${expected_slug}-aiready-report-final.pdf"*) ;;
  *)
    echo "Attachment 1 does not reference the expected final report for $expected_slug" >&2
    exit 1
    ;;
esac

case "$attachment_2" in
  *"${expected_slug}-evidence-appendix.pdf"*) ;;
  *)
    echo "Attachment 2 does not reference the expected evidence appendix for $expected_slug" >&2
    exit 1
    ;;
esac

case "$checklist_supporting_files" in
  *"${attachment_2}"*) ;;
  *)
    echo "Attachment 2 does not match checklist supporting files in $checklist_file" >&2
    exit 1
    ;;
esac

case "$tier_specific_attachments" in
  yes|Yes) ;;
  *)
    echo "Tier-specific attachments flag is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

case "$naming_checked" in
  yes|Yes) ;;
  *)
    echo "Naming check flag is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

case "$follow_up_stated" in
  yes|Yes) ;;
  *)
    echo "Follow-up expectation flag is not complete in $delivery_file" >&2
    exit 1
    ;;
esac

require_contains "AIReady Australia Audit Delivery - $business_value" "$delivery_file"
require_contains "Hi $client_value," "$delivery_file"
require_contains "Attached is your $tier AI Readiness Report for $business_value." "$delivery_file"
require_contains "Prime" "$delivery_file"
require_contains "AIReady Australia" "$delivery_file"

case "$tier" in
  Starter)
    if [[ "$checklist_follow_up_window" != "No included follow-up support" ]]; then
      echo "Starter checklist follow-up window mismatch in $checklist_file: $checklist_follow_up_window" >&2
      exit 1
    fi
    if [[ "$checklist_follow_up_due" != "not scheduled - starter tier has no included follow-up" ]]; then
      echo "Starter checklist follow-up due mismatch in $checklist_file: $checklist_follow_up_due" >&2
      exit 1
    fi
    require_contains "No walkthrough call or follow-up support is included unless separately purchased." "$delivery_file"
    require_contains "${expected_slug}-executive-summary.pdf" "$delivery_file"
    ;;
  Business)
    if [[ "$checklist_follow_up_window" != "30-day Q&A by email" ]]; then
      echo "Business checklist follow-up window mismatch in $checklist_file: $checklist_follow_up_window" >&2
      exit 1
    fi
    if [[ ! "$checklist_follow_up_due" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Business checklist follow-up due is not a valid date in $checklist_file: $checklist_follow_up_due" >&2
      exit 1
    fi
    require_contains "Please review the 90-day implementation plan before the walkthrough call." "$delivery_file"
    require_contains "Reply with your preferred times to book the 1-hour walkthrough call." "$delivery_file"
    require_contains "A 30-day Q&A by email is included after delivery." "$delivery_file"
    ;;
  Enterprise)
    if [[ "$checklist_follow_up_window" != "60-day Q&A by email" ]]; then
      echo "Enterprise checklist follow-up window mismatch in $checklist_file: $checklist_follow_up_window" >&2
      exit 1
    fi
    if [[ ! "$checklist_follow_up_due" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Enterprise checklist follow-up due is not a valid date in $checklist_file: $checklist_follow_up_due" >&2
      exit 1
    fi
    require_contains "${expected_slug}-board-brief.pdf" "$delivery_file"
    require_contains "${expected_slug}-integration-map.pdf" "$delivery_file"
    require_contains "A 60-day follow-up Q&A is included after delivery." "$delivery_file"
    require_contains "Please reply with your preferred times to book the 2-hour walkthrough." "$delivery_file"
    require_contains "Please let us know who should attend the 2-hour walkthrough." "$delivery_file"
    ;;
esac

echo "AIReady delivery email draft validated"
echo "workspace_root: $workspace_root"
echo "tier: $tier"
echo "business_slug: $expected_slug"
echo "delivery_file: $delivery_file"
echo
echo "validated_identity_fields:"
printf '  - %s\n' \
  "Business" \
  "Client" \
  "Email" \
  "Tier" \
  "Zoho record id" \
  "Delivery owner" \
  "Delivery date"
echo
echo "validated_attachment_fields:"
printf '  - %s\n' \
  "$attachment_1" \
  "$attachment_2"
