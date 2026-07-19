#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-release-readiness-history-trend-report.sh /path/to/history-trend-audit-root

Validate that an AIReady release-readiness history trend audit root contains the
expected summary packet, checksum packet, and per-audit status structure.
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
compatibility_report="$audit_root/history-trend-compatibility.txt"
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
require_nonempty_file "$compatibility_report"
require_nonempty_file "$artifact_audit"
require_nonempty_file "$proof_checksums"
require_nonempty_file "$proof_checksums_validation"
require_nonempty_file "$trend_report_validation"

required_readme_strings=(
  "# AIReady Release Readiness History Trend Audit"
  "- Audit root: \`$audit_root\`"
  "## Audit status"
  "## Aggregate evidence"
  "Validation log: [history-trend-validation.txt](./history-trend-validation.txt)"
  "Compatibility report: [history-trend-compatibility.txt](./history-trend-compatibility.txt)"
  "Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "Trend report validation: [history-trend-report-validation.txt](./history-trend-report-validation.txt)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"audit_root\": \"$audit_root\""
  "\"validation_log\": \"$validation_log\""
  "\"compatibility_report\": \"$compatibility_report\""
  "\"artifact_audit\": \"$artifact_audit\""
  "\"proof_checksums\": \"$proof_checksums\""
  "\"proof_checksum_validation\": \"$proof_checksums_validation\""
  "\"trend_report_validation\": \"$trend_report_validation\""
  '"requested_history_window":'
  '"history_audits_checked":'
  '"history_audits_passed":'
  '"history_audits_failed":'
  '"stable_reports_checked":'
  '"stable_reports_passed":'
  '"stable_reports_failed":'
  '"comparable_history_audits_checked":'
  '"comparable_history_audits_passed":'
  '"comparable_history_audits_failed":'
  '"legacy_window_mismatch_audits":'
  '"stable_comparable_reports_checked":'
  '"stable_comparable_reports_passed":'
  '"stable_comparable_reports_failed":'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

required_artifact_audit_strings=(
  "AIReady release-readiness history trend artifact audit"
  "audit_root: $audit_root"
  "$summary_readme"
  "$summary_manifest"
  "$validation_log"
  "$compatibility_report"
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
mapfile -t audit_status_pairs < <(jq -r '.audit_status[] | [.status, .audit_root, .reports_checked, .reports_passed, .reports_failed, .mode] | @tsv' "$summary_manifest")

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
  if ! [[ "$audit_item_root" =~ /reports/aiready-release-readiness-history-[0-9-]+-AWST$ ]]; then
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
  mode="$(printf '%s' "$audit_status_pair" | cut -f6)"
  require_literal "- \`$status\` — \`$audit_item_root\` (checked=$reports_checked passed=$reports_passed failed=$reports_failed mode=$mode)" "$summary_readme"
done

checked_count="$(jq -r '.history_audits_checked' "$summary_manifest")"
pass_count="$(jq -r '.history_audits_passed' "$summary_manifest")"
fail_count="$(jq -r '.history_audits_failed' "$summary_manifest")"
comparable_checked_count="$(jq -r '.comparable_history_audits_checked' "$summary_manifest")"
comparable_pass_count="$(jq -r '.comparable_history_audits_passed' "$summary_manifest")"
comparable_fail_count="$(jq -r '.comparable_history_audits_failed' "$summary_manifest")"
legacy_window_mismatch_count="$(jq -r '.legacy_window_mismatch_audits' "$summary_manifest")"
status_count="$(jq -r '.audit_status | length' "$summary_manifest")"
manifest_pass_status_count="$(jq '[.audit_status[] | select(.status == "PASS")] | length' "$summary_manifest")"
manifest_fail_status_count="$(jq '[.audit_status[] | select(.status == "FAIL")] | length' "$summary_manifest")"
manifest_comparable_status_count="$(jq '[.audit_status[] | select(.mode == "comparable")] | length' "$summary_manifest")"
manifest_legacy_status_count="$(jq '[.audit_status[] | select(.mode == "legacy-window-mismatch")] | length' "$summary_manifest")"
manifest_comparable_pass_count="$(jq '[.audit_status[] | select(.mode == "comparable" and .status == "PASS")] | length' "$summary_manifest")"
manifest_comparable_fail_count="$(jq '[.audit_status[] | select(.mode == "comparable" and .status == "FAIL")] | length' "$summary_manifest")"

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

if [[ "$comparable_checked_count" != "$manifest_comparable_status_count" ]]; then
  echo "comparable_history_audits_checked does not match comparable modes in manifest" >&2
  exit 1
fi

if [[ "$legacy_window_mismatch_count" != "$manifest_legacy_status_count" ]]; then
  echo "legacy_window_mismatch_audits does not match legacy-window-mismatch modes in manifest" >&2
  exit 1
fi

if [[ "$comparable_pass_count" != "$manifest_comparable_pass_count" ]]; then
  echo "comparable_history_audits_passed does not match comparable PASS statuses in manifest" >&2
  exit 1
fi

if [[ "$comparable_fail_count" != "$manifest_comparable_fail_count" ]]; then
  echo "comparable_history_audits_failed does not match comparable FAIL statuses in manifest" >&2
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

required_checksum_strings=(
  "# AIReady Release Readiness History Trend Proof Checksums"
  "audit_root: $audit_root"
  "  $summary_readme"
  "  $summary_manifest"
  "  $validation_log"
  "  $compatibility_report"
  "  $artifact_audit"
  "  $trend_report_validation"
)

for expected in "${required_checksum_strings[@]}"; do
  require_literal "$expected" "$proof_checksums"
done

required_checksum_validation_strings=(
  "AIReady release-readiness history trend proof checksum validation"
  "audit_root: $audit_root"
  "$summary_readme: OK"
  "$summary_manifest: OK"
  "$validation_log: OK"
  "$compatibility_report: OK"
  "$artifact_audit: OK"
  "$trend_report_validation: OK"
)

for expected in "${required_checksum_validation_strings[@]}"; do
  require_literal "$expected" "$proof_checksums_validation"
done

{
  echo "AIReady release-readiness history trend report validated"
  echo "audit_root: $audit_root"
  echo "history_audits_checked: $checked_count"
  echo "history_audits_passed: $pass_count"
  echo "history_audits_failed: $fail_count"
} | tee "$trend_report_validation"
