#!/usr/bin/env bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runbook="$workspace_root/ops/AIREADY-FIRST-INTAKE-RUNBOOK.md"
workflow_spec="$workspace_root/ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md"
discord_template="$workspace_root/ops/AIREADY-DISCORD-TRIGGER-TEMPLATE.md"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

extract_runbook_payload() {
  awk '
    /## Required inbound payload/ { in_section=1; next }
    in_section && /^Optional trigger payload fields:/ { exit }
    in_section && /^## / { exit }
    in_section && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/`.*/, "", line)
      print line
    }
  ' "$runbook"
}

extract_runbook_optional_payload() {
  awk '
    /Optional trigger payload fields:/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/`.*/, "", line)
      print line
    }
  ' "$runbook"
}

extract_workflow_payload() {
  awk '
    /## Trigger payload format/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- `[^`]+: / {
      line=$0
      sub(/^- `/, "", line)
      sub(/: .*/, "", line)
      if (line != "notes") {
        print line
      }
    }
  ' "$workflow_spec"
}

extract_workflow_optional_payload() {
  awk '
    /## Trigger payload format/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- `notes: / {
      print "notes"
    }
  ' "$workflow_spec"
}

extract_template_payload() {
  awk '
    /## Exact message template/ { in_block=1; next }
    in_block && /^```text$/ { next }
    in_block && /^```$/ { exit }
    in_block && /^[a-z_]+: / {
      line=$0
      sub(/: .*/, "", line)
      if (line != "notes") {
        print line
      }
    }
  ' "$discord_template"
}

extract_template_optional_payload() {
  awk '
    /## Exact message template/ { in_block=1; next }
    in_block && /^```text$/ { next }
    in_block && /^```$/ { exit }
    in_block && /^notes: / {
      print "notes"
    }
  ' "$discord_template"
}

extract_template_send_rule() {
  awk '
    /## Send rule/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/ = .*/, "", line)
      print line
    }
  ' "$discord_template"
}

extract_runbook_acceptance_rule() {
  awk '
    /## Trigger acceptance rule/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/ = .*/, "", line)
      print line
    }
  ' "$runbook"
}

extract_workflow_master_rule() {
  awk '
    /### Master readiness rule/ { in_section=1; next }
    in_section && /^### / { exit }
    in_section && /^- `/ {
      line=$0
      sub(/^- `/, "", line)
      sub(/ = .*/, "", line)
      line=tolower(line)
      gsub(/[[:space:]-]+/, "_", line)
      print line
    }
  ' "$workflow_spec"
}

compare_sets() {
  local left_label="$1"
  local left_file="$2"
  local right_label="$3"
  local right_file="$4"

  local left_only="$tmp_dir/left_only.txt"
  local right_only="$tmp_dir/right_only.txt"
  comm -23 "$left_file" "$right_file" > "$left_only"
  comm -13 "$left_file" "$right_file" > "$right_only"

  if [[ -s "$left_only" || -s "$right_only" ]]; then
    echo "Mismatch: $left_label vs $right_label" >&2
    if [[ -s "$left_only" ]]; then
      echo "Only in $left_label:" >&2
      sed 's/^/  - /' "$left_only" >&2
    fi
    if [[ -s "$right_only" ]]; then
      echo "Only in $right_label:" >&2
      sed 's/^/  - /' "$right_only" >&2
    fi
    exit 1
  fi
}

require_file "$runbook"
require_file "$workflow_spec"
require_file "$discord_template"

extract_runbook_payload | sort -u > "$tmp_dir/runbook_payload.txt"
extract_workflow_payload | sort -u > "$tmp_dir/workflow_payload.txt"
extract_template_payload | sort -u > "$tmp_dir/template_payload.txt"
extract_template_send_rule | sort -u > "$tmp_dir/template_send_rule.txt"
extract_runbook_acceptance_rule | sort -u > "$tmp_dir/runbook_acceptance_rule.txt"
extract_workflow_master_rule | sort -u > "$tmp_dir/workflow_master_rule.txt"
extract_runbook_optional_payload | sort -u > "$tmp_dir/runbook_optional_payload.txt"
extract_workflow_optional_payload | sort -u > "$tmp_dir/workflow_optional_payload.txt"
extract_template_optional_payload | sort -u > "$tmp_dir/template_optional_payload.txt"

compare_sets "runbook payload" "$tmp_dir/runbook_payload.txt" "workflow payload" "$tmp_dir/workflow_payload.txt"
compare_sets "runbook payload" "$tmp_dir/runbook_payload.txt" "Discord template payload" "$tmp_dir/template_payload.txt"
compare_sets "runbook acceptance rule" "$tmp_dir/runbook_acceptance_rule.txt" "workflow master readiness rule" "$tmp_dir/workflow_master_rule.txt"
compare_sets "runbook acceptance rule" "$tmp_dir/runbook_acceptance_rule.txt" "Discord template send rule" "$tmp_dir/template_send_rule.txt"
compare_sets "runbook optional payload" "$tmp_dir/runbook_optional_payload.txt" "workflow optional payload" "$tmp_dir/workflow_optional_payload.txt"
compare_sets "runbook optional payload" "$tmp_dir/runbook_optional_payload.txt" "Discord template optional payload" "$tmp_dir/template_optional_payload.txt"

echo "AIReady trigger contract validated"
echo "runbook: $runbook"
echo "workflow_spec: $workflow_spec"
echo "discord_template: $discord_template"
echo
echo "validated_payload_fields:"
sed 's/^/  - /' "$tmp_dir/runbook_payload.txt"
echo
echo "validated_readiness_fields:"
sed 's/^/  - /' "$tmp_dir/runbook_acceptance_rule.txt"
echo
echo "validated_optional_payload_fields:"
sed 's/^/  - /' "$tmp_dir/runbook_optional_payload.txt"
