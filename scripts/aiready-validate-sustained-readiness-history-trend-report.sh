#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-sustained-readiness-history-trend-report.sh /path/to/history-trend-audit-root

Validate that an AIReady sustained-readiness history trend audit root contains
the expected summary packet, checksum packet, and per-audit status structure.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

audit_root="$1"
summary_readme="$audit_root/README.md"
summary_manifest="$audit_root/manifest.json"
validation_log="$audit_root/history-trend-validation.txt"
artifact_audit="$audit_root/artifact-audit.txt"
proof_checksums="$audit_root/proof-sha256.txt"
proof_checksums_validation="$audit_root/proof-sha256-validation.txt"
trend_report_validation="$audit_root/history-trend-report-validation.txt"

require_nonempty_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    exit 1
  fi
  if [[ ! -s "$path" ]]; then
    echo "File is empty: $path" >&2
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

if [[ ! -d "$audit_root" ]]; then
  echo "Audit root not found: $audit_root" >&2
  exit 1
fi

require_nonempty_file "$summary_readme"
require_nonempty_file "$summary_manifest"
require_nonempty_file "$validation_log"
require_nonempty_file "$artifact_audit"
require_nonempty_file "$proof_checksums"
require_nonempty_file "$proof_checksums_validation"
require_nonempty_file "$trend_report_validation"

required_readme_strings=(
  "# AIReady Sustained Readiness History Trend Audit"
  "- Audit root: \`$audit_root\`"
  "## Audit status"
  "## Aggregate evidence"
  "Validation log: [history-trend-validation.txt](./history-trend-validation.txt)"
  "Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "Trend report validation: [history-trend-report-validation.txt](./history-trend-report-validation.txt)"
  "- Requested-window mismatch present: \`$(jq -r '.requested_window_mismatch_present' "$summary_manifest")\`"
  "- Authoritative stability basis: \`$(jq -r '.authoritative_stability_basis' "$summary_manifest")\`"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"audit_root\": \"$audit_root\""
  "\"validation_log\": \"$validation_log\""
  "\"artifact_audit\": \"$artifact_audit\""
  "\"proof_checksums\": \"$proof_checksums\""
  "\"proof_checksum_validation\": \"$proof_checksums_validation\""
  "\"trend_report_validation\": \"$trend_report_validation\""
  '"history_audits_checked":'
  '"history_audits_passed":'
  '"history_audits_failed":'
  '"stable_reports_checked":'
  '"stable_reports_passed":'
  '"stable_reports_failed":'
  '"requested_window_mismatch_present":'
  '"authoritative_stability_basis":'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

required_artifact_audit_strings=(
  "AIReady sustained-readiness history trend artifact audit"
  "audit_root: $audit_root"
  "$summary_readme"
  "$summary_manifest"
  "$validation_log"
  "$artifact_audit"
  "$proof_checksums"
  "$proof_checksums_validation"
  "$trend_report_validation"
)

for expected in "${required_artifact_audit_strings[@]}"; do
  require_literal "$expected" "$artifact_audit"
done

mapfile -t audit_roots < <(jq -r '.audit_status[].audit_root' "$summary_manifest")
mapfile -t audit_status_values < <(jq -r '.audit_status[].status' "$summary_manifest")
mapfile -t audit_status_pairs < <(jq -r '.audit_status[] | [.status, .audit_root, .reports_checked, .reports_passed, .reports_failed] | @tsv' "$summary_manifest")

if [[ "${#audit_status_values[@]}" -eq 0 ]]; then
  echo "audit_status array is empty" >&2
  exit 1
fi

for status in "${audit_status_values[@]}"; do
  case "$status" in
    PASS|FAIL) ;;
    *)
      echo "Invalid audit_status value: $status" >&2
      exit 1
      ;;
  esac
done

for audit_item_root in "${audit_roots[@]}"; do
  if ! [[ "$audit_item_root" =~ /reports/aiready-sustained-readiness-history-[0-9-]+-AWST$ ]]; then
    echo "Invalid audit_root path shape: $audit_item_root" >&2
    exit 1
  fi
  require_nonempty_file "$audit_item_root/README.md"
  require_nonempty_file "$audit_item_root/manifest.json"
  require_literal "$audit_item_root" "$artifact_audit"
done

for audit_status_pair in "${audit_status_pairs[@]}"; do
  status="$(printf '%s' "$audit_status_pair" | cut -f1)"
  audit_item_root="$(printf '%s' "$audit_status_pair" | cut -f2)"
  reports_checked="$(printf '%s' "$audit_status_pair" | cut -f3)"
  reports_passed="$(printf '%s' "$audit_status_pair" | cut -f4)"
  reports_failed="$(printf '%s' "$audit_status_pair" | cut -f5)"
  mode="$(jq -r --arg root "$audit_item_root" '.audit_status[] | select(.audit_root == $root) | .mode' "$summary_manifest")"
  if [[ -z "$mode" || "$mode" == "null" ]]; then
    require_literal "- \`$status\` — \`$audit_item_root\` (checked=$reports_checked passed=$reports_passed failed=$reports_failed)" "$summary_readme"
  else
    require_literal "- \`$status\` — \`$audit_item_root\` (checked=$reports_checked passed=$reports_passed failed=$reports_failed mode=$mode)" "$summary_readme"
  fi
done

checked_count="$(jq -r '.history_audits_checked' "$summary_manifest")"
pass_count="$(jq -r '.history_audits_passed' "$summary_manifest")"
fail_count="$(jq -r '.history_audits_failed' "$summary_manifest")"
status_count="$(jq -r '.audit_status | length' "$summary_manifest")"
manifest_pass_status_count="$(jq '[.audit_status[] | select(.status == "PASS")] | length' "$summary_manifest")"
manifest_fail_status_count="$(jq '[.audit_status[] | select(.status == "FAIL")] | length' "$summary_manifest")"
requested_window="$(jq -r '.requested_history_window' "$summary_manifest")"
requested_window_mismatch_audits="$(jq -r '.requested_window_mismatch_audits' "$summary_manifest")"
requested_window_mismatch_present="$(jq -r '.requested_window_mismatch_present' "$summary_manifest")"
authoritative_stability_basis="$(jq -r '.authoritative_stability_basis' "$summary_manifest")"
comparable_checked="$(jq -r '.comparable_history_audits_checked' "$summary_manifest")"
comparable_passed="$(jq -r '.comparable_history_audits_passed' "$summary_manifest")"
comparable_failed="$(jq -r '.comparable_history_audits_failed' "$summary_manifest")"
stable_comparable_checked="$(jq -r '.stable_comparable_reports_checked' "$summary_manifest")"
stable_comparable_passed="$(jq -r '.stable_comparable_reports_passed' "$summary_manifest")"
stable_comparable_failed="$(jq -r '.stable_comparable_reports_failed' "$summary_manifest")"
stable_checked="$(jq -r '.stable_reports_checked' "$summary_manifest")"
stable_passed="$(jq -r '.stable_reports_passed' "$summary_manifest")"
stable_failed="$(jq -r '.stable_reports_failed' "$summary_manifest")"
comparable_status_count="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested)] | length' "$summary_manifest")"
comparable_pass_status_count="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested and .status == "PASS")] | length' "$summary_manifest")"
comparable_fail_status_count="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested and .status == "FAIL")] | length' "$summary_manifest")"
actual_requested_window_mismatches="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked != $requested)] | length' "$summary_manifest")"
distinct_checked="$(jq '[.audit_status[] | .reports_checked] | unique | length' "$summary_manifest")"
distinct_passed="$(jq '[.audit_status[] | .reports_passed] | unique | length' "$summary_manifest")"
distinct_failed="$(jq '[.audit_status[] | .reports_failed] | unique | length' "$summary_manifest")"

if [[ "$checked_count" != "$status_count" ]]; then
  echo "history_audits_checked does not match audit_status length" >&2
  exit 1
fi

if [[ "$pass_count" != "$manifest_pass_status_count" ]]; then
  echo "history_audits_passed does not match PASS statuses in manifest" >&2
  exit 1
fi

if [[ "$fail_count" != "$manifest_fail_status_count" ]]; then
  echo "history_audits_failed does not match FAIL statuses in manifest" >&2
  exit 1
fi

pass_log_count="$(rg -c '^- `PASS`' "$summary_readme" 2>/dev/null || printf '0\n')"
fail_log_count="$(rg -c '^- `FAIL`' "$summary_readme" 2>/dev/null || printf '0\n')"

if [[ "$pass_count" != "$pass_log_count" ]]; then
  echo "history_audits_passed does not match README PASS count" >&2
  exit 1
fi

if [[ "$fail_count" != "$fail_log_count" ]]; then
  echo "history_audits_failed does not match README FAIL count" >&2
  exit 1
fi

if [[ "$requested_window_mismatch_audits" != "$actual_requested_window_mismatches" ]]; then
  echo "requested_window_mismatch_audits does not match audit_status mismatch count" >&2
  exit 1
fi

if [[ "$actual_requested_window_mismatches" -gt 0 && "$requested_window_mismatch_present" != "true" ]]; then
  echo "requested_window_mismatch_present should be true when mismatches exist" >&2
  exit 1
fi

if [[ "$actual_requested_window_mismatches" -eq 0 && "$requested_window_mismatch_present" != "false" ]]; then
  echo "requested_window_mismatch_present should be false when no mismatches exist" >&2
  exit 1
fi

if [[ "$requested_window_mismatch_present" == "true" && "$authoritative_stability_basis" != "comparable-set" ]]; then
  echo "authoritative_stability_basis should be comparable-set when mismatches exist" >&2
  exit 1
fi

if [[ "$requested_window_mismatch_present" == "false" && "$authoritative_stability_basis" != "all-audits" ]]; then
  echo "authoritative_stability_basis should be all-audits when no mismatches exist" >&2
  exit 1
fi

if [[ "$comparable_checked" != "$comparable_status_count" ]]; then
  echo "comparable_history_audits_checked does not match comparable audit_status count" >&2
  exit 1
fi

if [[ "$comparable_passed" != "$comparable_pass_status_count" ]]; then
  echo "comparable_history_audits_passed does not match comparable PASS count" >&2
  exit 1
fi

if [[ "$comparable_failed" != "$comparable_fail_status_count" ]]; then
  echo "comparable_history_audits_failed does not match comparable FAIL count" >&2
  exit 1
fi

if [[ "$stable_checked" == "true" && "$distinct_checked" != "1" ]]; then
  echo "stable_reports_checked is true but reports_checked values are not identical" >&2
  exit 1
fi

if [[ "$stable_checked" == "false" && "$distinct_checked" == "1" ]]; then
  echo "stable_reports_checked is false but reports_checked values are identical" >&2
  exit 1
fi

if [[ "$stable_passed" == "true" && "$distinct_passed" != "1" ]]; then
  echo "stable_reports_passed is true but reports_passed values are not identical" >&2
  exit 1
fi

if [[ "$stable_passed" == "false" && "$distinct_passed" == "1" ]]; then
  echo "stable_reports_passed is false but reports_passed values are identical" >&2
  exit 1
fi

if [[ "$stable_failed" == "true" && "$distinct_failed" != "1" ]]; then
  echo "stable_reports_failed is true but reports_failed values are not identical" >&2
  exit 1
fi

if [[ "$stable_failed" == "false" && "$distinct_failed" == "1" ]]; then
  echo "stable_reports_failed is false but reports_failed values are identical" >&2
  exit 1
fi

if [[ "$stable_comparable_checked" == "true" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_checked="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_checked] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_checked" != "1" ]]; then
    echo "stable_comparable_reports_checked is true but comparable reports_checked values are not identical" >&2
    exit 1
  fi
fi

if [[ "$stable_comparable_checked" == "false" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_checked="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_checked] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_checked" == "1" ]]; then
    echo "stable_comparable_reports_checked is false but comparable reports_checked values are identical" >&2
    exit 1
  fi
fi

if [[ "$stable_comparable_passed" == "true" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_passed="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_passed] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_passed" != "1" ]]; then
    echo "stable_comparable_reports_passed is true but comparable reports_passed values are not identical" >&2
    exit 1
  fi
fi

if [[ "$stable_comparable_passed" == "false" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_passed="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_passed] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_passed" == "1" ]]; then
    echo "stable_comparable_reports_passed is false but comparable reports_passed values are identical" >&2
    exit 1
  fi
fi

if [[ "$stable_comparable_failed" == "true" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_failed="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_failed] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_failed" != "1" ]]; then
    echo "stable_comparable_reports_failed is true but comparable reports_failed values are not identical" >&2
    exit 1
  fi
fi

if [[ "$stable_comparable_failed" == "false" && "$comparable_checked" -gt 0 ]]; then
  distinct_comparable_failed="$(jq --argjson requested "$requested_window" '[.audit_status[] | select(.reports_checked == $requested) | .reports_failed] | unique | length' "$summary_manifest")"
  if [[ "$distinct_comparable_failed" == "1" ]]; then
    echo "stable_comparable_reports_failed is false but comparable reports_failed values are identical" >&2
    exit 1
  fi
fi

required_checksum_strings=(
  "# AIReady Sustained Readiness History Trend Proof Checksums"
  "audit_root: $audit_root"
  "  $summary_readme"
  "  $summary_manifest"
  "  $validation_log"
  "  $artifact_audit"
  "  $trend_report_validation"
)

for expected in "${required_checksum_strings[@]}"; do
  require_literal "$expected" "$proof_checksums"
done

required_checksum_validation_strings=(
  "AIReady sustained-readiness history trend proof checksum validation"
  "audit_root: $audit_root"
  "$summary_readme: OK"
  "$summary_manifest: OK"
  "$validation_log: OK"
  "$artifact_audit: OK"
  "$trend_report_validation: OK"
)

for expected in "${required_checksum_validation_strings[@]}"; do
  require_literal "$expected" "$proof_checksums_validation"
done

{
  echo "AIReady sustained-readiness history trend report validated"
  echo "audit_root: $audit_root"
  echo "history_audits_checked: $checked_count"
  echo "history_audits_passed: $pass_count"
  echo "history_audits_failed: $fail_count"
  if jq -e 'has("requested_history_window")' "$summary_manifest" >/dev/null; then
    echo "requested_history_window: $(jq -r '.requested_history_window' "$summary_manifest")"
  fi
  if jq -e 'has("comparable_history_audits_checked")' "$summary_manifest" >/dev/null; then
    echo "comparable_history_audits_checked: $(jq -r '.comparable_history_audits_checked' "$summary_manifest")"
    echo "comparable_history_audits_passed: $(jq -r '.comparable_history_audits_passed' "$summary_manifest")"
    echo "comparable_history_audits_failed: $(jq -r '.comparable_history_audits_failed' "$summary_manifest")"
  fi
  if jq -e 'has("legacy_window_mismatch_audits")' "$summary_manifest" >/dev/null; then
    echo "legacy_window_mismatch_audits: $(jq -r '.legacy_window_mismatch_audits' "$summary_manifest")"
  fi
  if jq -e 'has("requested_window_mismatch_audits")' "$summary_manifest" >/dev/null; then
    echo "requested_window_mismatch_audits: $(jq -r '.requested_window_mismatch_audits' "$summary_manifest")"
  fi
  if jq -e 'has("requested_window_mismatch_present")' "$summary_manifest" >/dev/null; then
    echo "requested_window_mismatch_present: $(jq -r '.requested_window_mismatch_present' "$summary_manifest")"
  fi
  if jq -e 'has("authoritative_stability_basis")' "$summary_manifest" >/dev/null; then
    echo "authoritative_stability_basis: $(jq -r '.authoritative_stability_basis' "$summary_manifest")"
  fi
} | tee "$trend_report_validation"
