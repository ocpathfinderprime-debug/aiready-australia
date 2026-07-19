#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-release-readiness-history-trend.sh [output_root] [count]

Validate the latest N AIReady release-readiness history audit roots and capture
one aggregate trend packet proving the history-audit lane remains consistent.

Defaults:
  output_root -> reports/aiready-release-readiness-history-trend-<timestamp>
  count       -> 5
EOF
}

if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$workspace_root/reports/aiready-release-readiness-history-trend-$(date +%Y-%m-%d-%H%M-AWST)}"
count="${2:-5}"
validator="$workspace_root/scripts/aiready-validate-release-readiness-history-report.sh"
trend_validator="$workspace_root/scripts/aiready-validate-release-readiness-history-trend-report.sh"
compatibility_classifier="$workspace_root/scripts/aiready-classify-release-readiness-proof-compatibility.sh"

if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
  echo "Count must be a positive integer: $count" >&2
  exit 1
fi

if [[ ! -f "$validator" ]]; then
  echo "Missing required validator: $validator" >&2
  exit 1
fi

if [[ ! -f "$trend_validator" ]]; then
  echo "Missing required validator: $trend_validator" >&2
  exit 1
fi

if [[ ! -f "$compatibility_classifier" ]]; then
  echo "Missing required classifier: $compatibility_classifier" >&2
  exit 1
fi

if [[ -e "$output_root" ]]; then
  echo "Output root already exists: $output_root" >&2
  exit 1
fi

mapfile -t audit_roots < <(
  ls -1dt "$workspace_root"/reports/aiready-release-readiness-history-20*-AWST 2>/dev/null |
    head -n "$count"
)

if [[ "${#audit_roots[@]}" -eq 0 ]]; then
  echo "No release-readiness history audit roots found under $workspace_root/reports" >&2
  exit 1
fi

mkdir -p "$output_root"

summary_readme="$output_root/README.md"
summary_manifest="$output_root/manifest.json"
validation_log="$output_root/history-trend-validation.txt"
artifact_audit="$output_root/artifact-audit.txt"
checksums_output="$output_root/proof-sha256.txt"
checksums_validation_output="$output_root/proof-sha256-validation.txt"
trend_validation_output="$output_root/history-trend-report-validation.txt"
compatibility_report="$output_root/history-trend-compatibility.txt"

: >"$validation_log"

validated_count=0
failed_count=0
status_lines=()
pass_counts=()
fail_counts=()
checked_counts=()
failed_audit_roots=()
comparable_count=0
comparable_passed=0
comparable_failed=0
legacy_window_mismatch_count=0

for audit_root in "${audit_roots[@]}"; do
  echo "Validating: $audit_root" | tee -a "$validation_log"
  if "$validator" "$audit_root" | tee -a "$validation_log"; then
    status_lines+=("PASS|$audit_root")
    validated_count=$((validated_count + 1))
  else
    status_lines+=("FAIL|$audit_root")
    failed_count=$((failed_count + 1))
    failed_audit_roots+=("$audit_root")
  fi
  checked_counts+=("$(jq -r '.reports_checked' "$audit_root/manifest.json")")
  pass_counts+=("$(jq -r '.reports_passed' "$audit_root/manifest.json")")
  fail_counts+=("$(jq -r '.reports_failed' "$audit_root/manifest.json")")
  echo | tee -a "$validation_log"
done

for i in "${!audit_roots[@]}"; do
  if [[ "${checked_counts[$i]}" != "$count" ]]; then
    legacy_window_mismatch_count=$((legacy_window_mismatch_count + 1))
    continue
  fi

  comparable_count=$((comparable_count + 1))
  if [[ "${status_lines[$i]%%|*}" == "PASS" ]]; then
    comparable_passed=$((comparable_passed + 1))
  else
    comparable_failed=$((comparable_failed + 1))
  fi
done

latest_checked="${checked_counts[0]}"
latest_passed="${pass_counts[0]}"
latest_failed="${fail_counts[0]}"
stable_checked=true
stable_passed=true
stable_failed=true
comparable_stable_checked=true
comparable_stable_passed=true
comparable_stable_failed=true

for value in "${checked_counts[@]}"; do
  if [[ "$value" != "$latest_checked" ]]; then
    stable_checked=false
    break
  fi
done

for value in "${pass_counts[@]}"; do
  if [[ "$value" != "$latest_passed" ]]; then
    stable_passed=false
    break
  fi
done

for value in "${fail_counts[@]}"; do
  if [[ "$value" != "$latest_failed" ]]; then
    stable_failed=false
    break
  fi
done

if [[ "$comparable_count" -gt 0 ]]; then
  comparable_latest_index=""
  for i in "${!audit_roots[@]}"; do
    if [[ "${checked_counts[$i]}" == "$count" ]]; then
      comparable_latest_index="$i"
      break
    fi
  done

  comparable_latest_checked="${checked_counts[$comparable_latest_index]}"
  comparable_latest_passed="${pass_counts[$comparable_latest_index]}"
  comparable_latest_failed="${fail_counts[$comparable_latest_index]}"

  for i in "${!audit_roots[@]}"; do
    if [[ "${checked_counts[$i]}" != "$count" ]]; then
      continue
    fi
    if [[ "${checked_counts[$i]}" != "$comparable_latest_checked" ]]; then
      comparable_stable_checked=false
    fi
    if [[ "${pass_counts[$i]}" != "$comparable_latest_passed" ]]; then
      comparable_stable_passed=false
    fi
    if [[ "${fail_counts[$i]}" != "$comparable_latest_failed" ]]; then
      comparable_stable_failed=false
    fi
  done
fi

{
  echo "AIReady release-readiness history trend compatibility report"
  echo "audit_root: $output_root"
  echo "requested_history_window: $count"
  echo
  if [[ "${#failed_audit_roots[@]}" -eq 0 ]]; then
    echo "failed_history_audits: 0"
    echo "compatibility_summary: none"
  else
    echo "failed_history_audits: ${#failed_audit_roots[@]}"
    echo
    for failed_audit_root in "${failed_audit_roots[@]}"; do
      echo "history_audit_root: $failed_audit_root"
      mapfile -t failed_report_roots < <(
        jq -r '.report_status[] | select(.status == "FAIL") | .report_root' "$failed_audit_root/manifest.json" | sort -u
      )
      if [[ "${#failed_report_roots[@]}" -eq 0 ]]; then
        echo "  failed_report_roots: 0"
        echo
        continue
      fi
      echo "  failed_report_roots: ${#failed_report_roots[@]}"
      "$compatibility_classifier" "${failed_report_roots[@]}" | sed 's/^/  /'
    done
  fi
} >"$compatibility_report"

{
  echo "# AIReady Release Readiness History Trend Audit"
  echo
  echo "- Audit root: \`$output_root\`"
  echo "- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`"
  echo "- History audits checked: \`$((validated_count + failed_count))\`"
  echo "- History audits passed: \`$validated_count\`"
  echo "- History audits failed: \`$failed_count\`"
  echo "- Stable reports_checked across audits: \`$stable_checked\`"
  echo "- Stable reports_passed across audits: \`$stable_passed\`"
  echo "- Stable reports_failed across audits: \`$stable_failed\`"
  echo "- Comparable audits with requested window \`$count\`: \`$comparable_count\`"
  echo "- Comparable audits passed: \`$comparable_passed\`"
  echo "- Comparable audits failed: \`$comparable_failed\`"
  echo "- Legacy window mismatch audits excluded from comparable set: \`$legacy_window_mismatch_count\`"
  echo "- Stable comparable reports_checked: \`$comparable_stable_checked\`"
  echo "- Stable comparable reports_passed: \`$comparable_stable_passed\`"
  echo "- Stable comparable reports_failed: \`$comparable_stable_failed\`"
  echo
  echo "## Audit status"
  for i in "${!status_lines[@]}"; do
    status="${status_lines[$i]%%|*}"
    audit_root="${status_lines[$i]#*|}"
    checked="${checked_counts[$i]}"
    passed="${pass_counts[$i]}"
    failed="${fail_counts[$i]}"
    comparable_flag="comparable"
    if [[ "$checked" != "$count" ]]; then
      comparable_flag="legacy-window-mismatch"
    fi
    printf -- '- `%s` — `%s` (checked=%s passed=%s failed=%s mode=%s)\n' \
      "$status" "$audit_root" "$checked" "$passed" "$failed" "$comparable_flag"
  done
  echo
  echo "## Aggregate evidence"
  echo
  echo "- Validation log: [history-trend-validation.txt](./history-trend-validation.txt)"
  echo "- Compatibility report: [history-trend-compatibility.txt](./history-trend-compatibility.txt)"
  echo "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  echo "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  echo "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  echo "- Trend report validation: [history-trend-report-validation.txt](./history-trend-report-validation.txt)"
} >"$summary_readme"

{
  printf '{\n'
  printf '  "audit_root": "%s",\n' "$output_root"
  printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '  "requested_history_window": %s,\n' "$count"
  printf '  "history_audits_checked": %s,\n' "$((validated_count + failed_count))"
  printf '  "history_audits_passed": %s,\n' "$validated_count"
  printf '  "history_audits_failed": %s,\n' "$failed_count"
  printf '  "stable_reports_checked": %s,\n' "$stable_checked"
  printf '  "stable_reports_passed": %s,\n' "$stable_passed"
  printf '  "stable_reports_failed": %s,\n' "$stable_failed"
  printf '  "comparable_history_audits_checked": %s,\n' "$comparable_count"
  printf '  "comparable_history_audits_passed": %s,\n' "$comparable_passed"
  printf '  "comparable_history_audits_failed": %s,\n' "$comparable_failed"
  printf '  "legacy_window_mismatch_audits": %s,\n' "$legacy_window_mismatch_count"
  printf '  "stable_comparable_reports_checked": %s,\n' "$comparable_stable_checked"
  printf '  "stable_comparable_reports_passed": %s,\n' "$comparable_stable_passed"
  printf '  "stable_comparable_reports_failed": %s,\n' "$comparable_stable_failed"
  printf '  "validation_log": "%s",\n' "$validation_log"
  printf '  "compatibility_report": "%s",\n' "$compatibility_report"
  printf '  "artifact_audit": "%s",\n' "$artifact_audit"
  printf '  "proof_checksums": "%s",\n' "$checksums_output"
  printf '  "proof_checksum_validation": "%s",\n' "$checksums_validation_output"
  printf '  "trend_report_validation": "%s",\n' "$trend_validation_output"
  printf '  "audit_status": [\n'
  for i in "${!status_lines[@]}"; do
    suffix=","
    if [[ "$i" -eq $(("${#status_lines[@]}" - 1)) ]]; then
      suffix=""
    fi
    status="${status_lines[$i]%%|*}"
    audit_root="${status_lines[$i]#*|}"
    comparable_flag="comparable"
    if [[ "${checked_counts[$i]}" != "$count" ]]; then
      comparable_flag="legacy-window-mismatch"
    fi
    printf '    {"status":"%s","audit_root":"%s","reports_checked":%s,"reports_passed":%s,"reports_failed":%s,"mode":"%s"}%s\n' \
      "$status" "$audit_root" "${checked_counts[$i]}" "${pass_counts[$i]}" "${fail_counts[$i]}" "$comparable_flag" "$suffix"
  done
  printf '  ]\n'
  printf '}\n'
} >"$summary_manifest"

{
  echo "AIReady release-readiness history trend artifact audit"
  echo "audit_root: $output_root"
  echo
  echo "validated_artifacts:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$compatibility_report" \
    "$artifact_audit" \
    "$checksums_output" \
    "$checksums_validation_output" \
    "$trend_validation_output"
  echo
  echo "validated_history_audits:"
  printf '  - %s\n' "${audit_roots[@]}"
} >"$artifact_audit"

{
  echo "AIReady release-readiness history trend report validated"
  echo "audit_root: $output_root"
  echo "requested_history_window: $count"
  echo "history_audits_checked: $((validated_count + failed_count))"
  echo "history_audits_passed: $validated_count"
  echo "history_audits_failed: $failed_count"
  echo "stable_reports_checked: $stable_checked"
  echo "stable_reports_passed: $stable_passed"
  echo "stable_reports_failed: $stable_failed"
  echo "comparable_history_audits_checked: $comparable_count"
  echo "comparable_history_audits_passed: $comparable_passed"
  echo "comparable_history_audits_failed: $comparable_failed"
  echo "legacy_window_mismatch_audits: $legacy_window_mismatch_count"
  echo "stable_comparable_reports_checked: $comparable_stable_checked"
  echo "stable_comparable_reports_passed: $comparable_stable_passed"
  echo "stable_comparable_reports_failed: $comparable_stable_failed"
} >"$trend_validation_output"

{
  echo "# AIReady Release Readiness History Trend Proof Checksums"
  echo
  echo "audit_root: $output_root"
  echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  sha256sum \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$compatibility_report" \
    "$artifact_audit" \
    "$trend_validation_output"
} >"$checksums_output"

{
  echo "AIReady release-readiness history trend proof checksum validation"
  echo "audit_root: $output_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
} | tee "$checksums_validation_output"

"$trend_validator" "$output_root"

for path in \
  "$summary_readme" \
  "$summary_manifest" \
  "$validation_log" \
  "$compatibility_report" \
  "$artifact_audit" \
  "$checksums_output" \
  "$checksums_validation_output" \
  "$trend_validation_output"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty output artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady release-readiness history trend audit completed"
echo "audit_root: $output_root"
echo "history_audits_checked: $((validated_count + failed_count))"
echo "history_audits_passed: $validated_count"
echo "history_audits_failed: $failed_count"
echo "stable_reports_checked: $stable_checked"
echo "stable_reports_passed: $stable_passed"
echo "stable_reports_failed: $stable_failed"
echo "comparable_history_audits_checked: $comparable_count"
echo "comparable_history_audits_passed: $comparable_passed"
echo "comparable_history_audits_failed: $comparable_failed"
echo "legacy_window_mismatch_audits: $legacy_window_mismatch_count"
echo "stable_comparable_reports_checked: $comparable_stable_checked"
echo "stable_comparable_reports_passed: $comparable_stable_passed"
echo "stable_comparable_reports_failed: $comparable_stable_failed"

if [[ "$comparable_failed" -gt 0 ]]; then
  exit 1
fi
