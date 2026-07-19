#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-sustained-readiness-history-report.sh /path/to/history-audit-root

Validate that an AIReady sustained-readiness history audit root contains the
expected summary packet, checksum packet, and per-report status structure.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

audit_root="$1"
summary_readme="$audit_root/README.md"
summary_manifest="$audit_root/manifest.json"
validation_log="$audit_root/history-validation.txt"
artifact_audit="$audit_root/artifact-audit.txt"
proof_checksums="$audit_root/proof-sha256.txt"
proof_checksums_validation="$audit_root/proof-sha256-validation.txt"
history_report_validation="$audit_root/history-report-validation.txt"

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
require_nonempty_file "$history_report_validation"

required_readme_strings=(
  "# AIReady Sustained Readiness History Audit"
  "- Audit root: \`$audit_root\`"
  "- Requested history window: \`$(jq -r '.requested_history_window' "$summary_manifest")\`"
  "- Validated report packets: \`$(jq -r '.validated_report_packet_count' "$summary_manifest")\`"
  "## Report status"
  "## Aggregate evidence"
  "Validation log: [history-validation.txt](./history-validation.txt)"
  "Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"audit_root\": \"$audit_root\""
  '"requested_history_window":'
  "\"validation_log\": \"$validation_log\""
  "\"artifact_audit\": \"$artifact_audit\""
  '"validated_report_packet_count":'
  "\"proof_checksums\": \"$proof_checksums\""
  "\"proof_checksum_validation\": \"$proof_checksums_validation\""
  "\"history_report_validation\": \"$history_report_validation\""
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

required_artifact_audit_strings=(
  "AIReady sustained-readiness history artifact audit"
  "audit_root: $audit_root"
  "$summary_readme"
  "$summary_manifest"
  "$validation_log"
  "$history_report_validation"
  "$proof_checksums"
  "$proof_checksums_validation"
)

for expected in "${required_artifact_audit_strings[@]}"; do
  require_literal "$expected" "$artifact_audit"
done

mapfile -t report_roots < <(jq -r '.report_status[].report_root' "$summary_manifest")
mapfile -t report_status_values < <(jq -r '.report_status[].status' "$summary_manifest")
mapfile -t report_status_pairs < <(jq -r '.report_status[] | [.status, .report_root] | @tsv' "$summary_manifest")
mapfile -t unique_report_roots < <(printf '%s\n' "${report_roots[@]}" | sort -u)

if [[ "${#report_status_values[@]}" -eq 0 ]]; then
  echo "report_status array is empty" >&2
  exit 1
fi

if [[ "${#unique_report_roots[@]}" != "${#report_roots[@]}" ]]; then
  echo "Duplicate report_root entries found in report_status" >&2
  exit 1
fi

for status in "${report_status_values[@]}"; do
  case "$status" in
    PASS|FAIL) ;;
    *)
      echo "Invalid report_status value: $status" >&2
      exit 1
      ;;
  esac
done

for report_root in "${report_roots[@]}"; do
  if ! [[ "$report_root" =~ /reports/aiready-sustained-readiness-[0-9-]+-AWST$ ]]; then
    echo "Invalid report_root path shape: $report_root" >&2
    exit 1
  fi
  require_nonempty_file "$report_root/sustained-readiness-report-validation.txt"
  require_nonempty_file "$report_root/proof-sha256-validation.txt"
  require_literal "$report_root" "$artifact_audit"
  require_literal "$report_root/sustained-readiness-report-validation.txt" "$artifact_audit"
  require_literal "$report_root/proof-sha256-validation.txt" "$artifact_audit"
done

for report_status_pair in "${report_status_pairs[@]}"; do
  status="${report_status_pair%%$'\t'*}"
  report_root="${report_status_pair#*$'\t'}"
  require_literal "- \`$status\` — \`$report_root\`" "$summary_readme"
done

report_packet_count="$(grep -Ec '^  - .*/reports/aiready-sustained-readiness-[0-9-]+-AWST/(sustained-readiness-report-validation\.txt|proof-sha256-validation\.txt)$' "$artifact_audit" 2>/dev/null || printf '0\n')"
expected_packet_count=$(( ${#report_roots[@]} * 2 ))
manifest_packet_count="$(jq -r '.validated_report_packet_count' "$summary_manifest")"

if [[ "$report_packet_count" != "$expected_packet_count" ]]; then
  echo "validated_report_packets count does not match expected per-report packet count" >&2
  exit 1
fi

if [[ "$manifest_packet_count" != "$expected_packet_count" ]]; then
  echo "validated_report_packet_count in manifest does not match expected per-report packet count" >&2
  exit 1
fi

require_literal "validated_report_packet_count: $expected_packet_count" "$artifact_audit"

required_checksum_strings=(
  "# AIReady Sustained Readiness History Proof Checksums"
  "audit_root: $audit_root"
  "  $summary_readme"
  "  $summary_manifest"
  "  $validation_log"
  "  $artifact_audit"
  "  $history_report_validation"
)

for expected in "${required_checksum_strings[@]}"; do
  require_literal "$expected" "$proof_checksums"
done

required_checksum_validation_strings=(
  "AIReady sustained-readiness history proof checksum validation"
  "audit_root: $audit_root"
  "$summary_readme: OK"
  "$summary_manifest: OK"
  "$validation_log: OK"
  "$artifact_audit: OK"
  "$history_report_validation: OK"
)

for expected in "${required_checksum_validation_strings[@]}"; do
  require_literal "$expected" "$proof_checksums_validation"
done

pass_count="$(jq -r '.reports_passed' "$summary_manifest")"
fail_count="$(jq -r '.reports_failed' "$summary_manifest")"
checked_count="$(jq -r '.reports_checked' "$summary_manifest")"
requested_window="$(jq -r '.requested_history_window' "$summary_manifest")"
status_count="$(jq -r '.report_status | length' "$summary_manifest")"
manifest_pass_status_count="$(jq '[.report_status[] | select(.status == "PASS")] | length' "$summary_manifest")"
manifest_fail_status_count="$(jq '[.report_status[] | select(.status == "FAIL")] | length' "$summary_manifest")"

if [[ "$checked_count" != "$status_count" ]]; then
  echo "reports_checked does not match report_status length" >&2
  exit 1
fi

if [[ "$requested_window" != "$status_count" ]]; then
  echo "requested_history_window does not match report_status length" >&2
  exit 1
fi

if [[ "$pass_count" != "$manifest_pass_status_count" ]]; then
  echo "reports_passed does not match PASS statuses in manifest" >&2
  exit 1
fi

if [[ "$fail_count" != "$manifest_fail_status_count" ]]; then
  echo "reports_failed does not match FAIL statuses in manifest" >&2
  exit 1
fi

pass_log_count="$(rg -c '^- `PASS`' "$summary_readme" 2>/dev/null || printf '0\n')"
fail_log_count="$(rg -c '^- `FAIL`' "$summary_readme" 2>/dev/null || printf '0\n')"

if [[ "$pass_count" != "$pass_log_count" ]]; then
  echo "reports_passed does not match README PASS count" >&2
  exit 1
fi

if [[ "$fail_count" != "$fail_log_count" ]]; then
  echo "reports_failed does not match README FAIL count" >&2
  exit 1
fi

{
  echo "AIReady sustained-readiness history report validated"
  echo "audit_root: $audit_root"
  echo "reports_checked: $checked_count"
  echo "reports_passed: $pass_count"
  echo "reports_failed: $fail_count"
} | tee "$history_report_validation"
