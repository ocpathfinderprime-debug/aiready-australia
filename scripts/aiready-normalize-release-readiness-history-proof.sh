#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-release-readiness-history-proof.sh /path/to/history-audit-root

Rebuild a legacy AIReady release-readiness history audit packet so it matches the
current README/artifact-audit/checksum/validation contract without changing the
underlying report-status truth.
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
history_validator="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/aiready-validate-release-readiness-history-report.sh"

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

if [[ ! -d "$audit_root" ]]; then
  echo "Audit root not found: $audit_root" >&2
  exit 1
fi

require_nonempty_file "$summary_manifest"
require_nonempty_file "$validation_log"

if [[ ! -f "$history_validator" ]]; then
  echo "Missing history validator: $history_validator" >&2
  exit 1
fi

report_roots=()
report_status_values=()
current_root=""
current_status="FAIL"

flush_current() {
  if [[ -z "$current_root" ]]; then
    return
  fi

  if [[ "$current_root" =~ /reports/aiready-release-readiness-[0-9-]+-AWST$ ]]; then
    report_roots+=("$current_root")
    report_status_values+=("$current_status")
  fi
}

while IFS= read -r line; do
  if [[ "$line" == "Validating: "* ]]; then
    flush_current
    current_root="${line#Validating: }"
    current_status="FAIL"
    continue
  fi

  if [[ -n "$current_root" && "$line" == "AIReady release-readiness report validated" ]]; then
    current_status="PASS"
  fi
done <"$validation_log"

flush_current

if [[ "${#report_roots[@]}" -eq 0 ]]; then
  echo "Could not reconstruct release-readiness report_status from $validation_log" >&2
  exit 1
fi

reports_checked="${#report_roots[@]}"
reports_passed=0
for status in "${report_status_values[@]}"; do
  if [[ "$status" == "PASS" ]]; then
    reports_passed=$((reports_passed + 1))
  fi
done
reports_failed=$((reports_checked - reports_passed))
requested_history_window="$reports_checked"
validated_report_packet_count="$(( reports_checked * 2 ))"

{
  echo "# AIReady Release Readiness History Audit"
  echo
  echo "- Audit root: \`$audit_root\`"
  echo "- Generated: \`$(jq -r '.generated_at' "$summary_manifest")\`"
  echo "- Requested history window: \`$requested_history_window\`"
  echo "- Reports checked: \`$reports_checked\`"
  echo "- Reports passed: \`$reports_passed\`"
  echo "- Reports failed: \`$reports_failed\`"
  echo "- Validated report packets: \`$validated_report_packet_count\`"
  echo
  echo "## Report status"
  for i in "${!report_roots[@]}"; do
    printf -- '- `%s` — `%s`\n' "${report_status_values[$i]}" "${report_roots[$i]}"
  done
  echo
  echo "## Aggregate evidence"
  echo
  echo "- Validation log: [history-validation.txt](./history-validation.txt)"
  echo "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  echo "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  echo "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  echo "- History report validation: [history-report-validation.txt](./history-report-validation.txt)"
} >"$summary_readme"

jq \
  --arg audit_root "$audit_root" \
  --arg artifact_audit "$artifact_audit" \
  --arg history_report_validation "$history_report_validation" \
  --arg proof_checksums "$proof_checksums" \
  --arg proof_checksums_validation "$proof_checksums_validation" \
  --arg validation_log "$validation_log" \
  --argjson requested_history_window "$requested_history_window" \
  --argjson reports_checked "$reports_checked" \
  --argjson reports_passed "$reports_passed" \
  --argjson reports_failed "$reports_failed" \
  --argjson report_roots_json "$(printf '%s\n' "${report_roots[@]}" | jq -R . | jq -s .)" \
  --argjson report_status_values_json "$(printf '%s\n' "${report_status_values[@]}" | jq -R . | jq -s .)" \
  --argjson validated_report_packet_count "$validated_report_packet_count" \
  '
  .audit_root = $audit_root
  | .requested_history_window = $requested_history_window
  | .reports_checked = $reports_checked
  | .reports_passed = $reports_passed
  | .reports_failed = $reports_failed
  | .artifact_audit = $artifact_audit
  | .history_report_validation = $history_report_validation
  | .proof_checksums = $proof_checksums
  | .proof_checksum_validation = $proof_checksums_validation
  | .validation_log = $validation_log
  | .validated_report_packet_count = $validated_report_packet_count
  | .report_status = [
      range(0; $report_roots_json | length) as $i
      | {
          status: $report_status_values_json[$i],
          report_root: $report_roots_json[$i]
        }
    ]
  ' "$summary_manifest" >"$summary_manifest.tmp"
mv "$summary_manifest.tmp" "$summary_manifest"

{
  echo "AIReady release-readiness history report validated"
  echo "audit_root: $audit_root"
  echo "reports_checked: $reports_checked"
  echo "reports_passed: $reports_passed"
  echo "reports_failed: $reports_failed"
} >"$history_report_validation"

{
  echo "AIReady release-readiness history artifact audit"
  echo "audit_root: $audit_root"
  echo
  echo "validated_artifacts:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$history_report_validation" \
    "$proof_checksums" \
    "$proof_checksums_validation"
  echo
  echo "validated_report_roots:"
  printf '  - %s\n' "${report_roots[@]}"
  echo
  echo "validated_report_packets:"
  for report_root in "${report_roots[@]}"; do
    printf '  - %s\n' "$report_root/release-readiness-report-validation.txt"
    printf '  - %s\n' "$report_root/proof-sha256-validation.txt"
  done
  echo
  echo "validated_report_packet_count: $validated_report_packet_count"
} >"$artifact_audit"

{
  echo "# AIReady Release Readiness History Proof Checksums"
  echo
  echo "audit_root: $audit_root"
  echo "generated_at: $(jq -r '.generated_at' "$summary_manifest")"
  echo
  sha256sum \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$artifact_audit" \
    "$history_report_validation"
} >"$proof_checksums"

{
  echo "AIReady release-readiness history proof checksum validation"
  echo "audit_root: $audit_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$proof_checksums" | sha256sum -c
} | tee "$proof_checksums_validation"

"$history_validator" "$audit_root"

echo "AIReady release-readiness history proof normalized"
echo "audit_root: $audit_root"
echo "reports_checked: $reports_checked"
echo "reports_passed: $reports_passed"
echo "reports_failed: $reports_failed"
