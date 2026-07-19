#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-release-readiness-history-trend-proof.sh /path/to/history-trend-audit-root

Rebuild a legacy AIReady release-readiness history trend audit packet so it
matches the current README/compatibility/checksum/validation contract without
inventing missing proof.
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
workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
trend_validator="$workspace_root/scripts/aiready-validate-release-readiness-history-trend-report.sh"
compatibility_classifier="$workspace_root/scripts/aiready-classify-release-readiness-proof-compatibility.sh"

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

if [[ ! -f "$trend_validator" ]]; then
  echo "Missing trend validator: $trend_validator" >&2
  exit 1
fi

if [[ ! -f "$compatibility_classifier" ]]; then
  echo "Missing compatibility classifier: $compatibility_classifier" >&2
  exit 1
fi

audit_roots=()
audit_status_values=()
checked_counts=()
pass_counts=()
fail_counts=()
failed_audit_roots=()
current_root=""
current_status="FAIL"

flush_current() {
  local checked passed failed

  if [[ -z "$current_root" ]]; then
    return
  fi

  if [[ ! "$current_root" =~ /reports/aiready-release-readiness-history-[0-9-]+-AWST$ ]]; then
    current_root=""
    current_status="FAIL"
    return
  fi

  if [[ ! -s "$current_root/manifest.json" ]]; then
    current_root=""
    current_status="FAIL"
    return
  fi

  checked="$(jq -r '.reports_checked' "$current_root/manifest.json")"
  passed="$(jq -r '.reports_passed' "$current_root/manifest.json")"
  failed="$(jq -r '.reports_failed' "$current_root/manifest.json")"

  audit_roots+=("$current_root")
  audit_status_values+=("$current_status")
  checked_counts+=("$checked")
  pass_counts+=("$passed")
  fail_counts+=("$failed")

  if [[ "$current_status" == "FAIL" ]]; then
    failed_audit_roots+=("$current_root")
  fi

  current_root=""
  current_status="FAIL"
}

while IFS= read -r line; do
  if [[ "$line" == "Validating: "* ]]; then
    flush_current
    current_root="${line#Validating: }"
    current_status="FAIL"
    continue
  fi

  if [[ -n "$current_root" && "$line" == "AIReady release-readiness history report validated" ]]; then
    current_status="PASS"
  fi
done <"$validation_log"

flush_current

if [[ "${#audit_roots[@]}" -eq 0 ]]; then
  echo "Could not reconstruct audit_status from $validation_log" >&2
  exit 1
fi

requested_history_window="${#audit_roots[@]}"
history_audits_checked="${#audit_roots[@]}"
history_audits_passed=0
history_audits_failed=0
comparable_history_audits_checked=0
comparable_history_audits_passed=0
comparable_history_audits_failed=0
legacy_window_mismatch_audits=0
stable_reports_checked=true
stable_reports_passed=true
stable_reports_failed=true
stable_comparable_reports_checked=true
stable_comparable_reports_passed=true
stable_comparable_reports_failed=true

for status in "${audit_status_values[@]}"; do
  if [[ "$status" == "PASS" ]]; then
    history_audits_passed=$((history_audits_passed + 1))
  else
    history_audits_failed=$((history_audits_failed + 1))
  fi
done

latest_checked="${checked_counts[0]}"
latest_passed="${pass_counts[0]}"
latest_failed="${fail_counts[0]}"

for value in "${checked_counts[@]}"; do
  if [[ "$value" != "$latest_checked" ]]; then
    stable_reports_checked=false
    break
  fi
done

for value in "${pass_counts[@]}"; do
  if [[ "$value" != "$latest_passed" ]]; then
    stable_reports_passed=false
    break
  fi
done

for value in "${fail_counts[@]}"; do
  if [[ "$value" != "$latest_failed" ]]; then
    stable_reports_failed=false
    break
  fi
done

comparable_latest_checked=""
comparable_latest_passed=""
comparable_latest_failed=""
for i in "${!audit_roots[@]}"; do
  if [[ "${checked_counts[$i]}" != "$requested_history_window" ]]; then
    legacy_window_mismatch_audits=$((legacy_window_mismatch_audits + 1))
    continue
  fi

  comparable_history_audits_checked=$((comparable_history_audits_checked + 1))
  if [[ -z "$comparable_latest_checked" ]]; then
    comparable_latest_checked="${checked_counts[$i]}"
    comparable_latest_passed="${pass_counts[$i]}"
    comparable_latest_failed="${fail_counts[$i]}"
  fi

  if [[ "${audit_status_values[$i]}" == "PASS" ]]; then
    comparable_history_audits_passed=$((comparable_history_audits_passed + 1))
  else
    comparable_history_audits_failed=$((comparable_history_audits_failed + 1))
  fi
done

if [[ "$comparable_history_audits_checked" -gt 0 ]]; then
  for i in "${!audit_roots[@]}"; do
    if [[ "${checked_counts[$i]}" != "$requested_history_window" ]]; then
      continue
    fi
    if [[ "${checked_counts[$i]}" != "$comparable_latest_checked" ]]; then
      stable_comparable_reports_checked=false
    fi
    if [[ "${pass_counts[$i]}" != "$comparable_latest_passed" ]]; then
      stable_comparable_reports_passed=false
    fi
    if [[ "${fail_counts[$i]}" != "$comparable_latest_failed" ]]; then
      stable_comparable_reports_failed=false
    fi
  done
fi

{
  echo "AIReady release-readiness history trend compatibility report"
  echo "audit_root: $audit_root"
  echo "requested_history_window: $requested_history_window"
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
        jq -r '.report_status[] | select(.status == "FAIL") | .report_root' "$failed_audit_root/manifest.json" 2>/dev/null | sort -u
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
  echo "- Audit root: \`$audit_root\`"
  echo "- Generated: \`$(jq -r '.generated_at' "$summary_manifest")\`"
  echo "- History audits checked: \`$history_audits_checked\`"
  echo "- History audits passed: \`$history_audits_passed\`"
  echo "- History audits failed: \`$history_audits_failed\`"
  echo "- Stable reports_checked across audits: \`$stable_reports_checked\`"
  echo "- Stable reports_passed across audits: \`$stable_reports_passed\`"
  echo "- Stable reports_failed across audits: \`$stable_reports_failed\`"
  echo "- Comparable audits with requested window \`$requested_history_window\`: \`$comparable_history_audits_checked\`"
  echo "- Comparable audits passed: \`$comparable_history_audits_passed\`"
  echo "- Comparable audits failed: \`$comparable_history_audits_failed\`"
  echo "- Legacy window mismatch audits excluded from comparable set: \`$legacy_window_mismatch_audits\`"
  echo "- Stable comparable reports_checked: \`$stable_comparable_reports_checked\`"
  echo "- Stable comparable reports_passed: \`$stable_comparable_reports_passed\`"
  echo "- Stable comparable reports_failed: \`$stable_comparable_reports_failed\`"
  echo
  echo "## Audit status"
  for i in "${!audit_roots[@]}"; do
    mode="comparable"
    if [[ "${checked_counts[$i]}" != "$requested_history_window" ]]; then
      mode="legacy-window-mismatch"
    fi
    printf -- '- `%s` — `%s` (checked=%s passed=%s failed=%s mode=%s)\n' \
      "${audit_status_values[$i]}" "${audit_roots[$i]}" "${checked_counts[$i]}" "${pass_counts[$i]}" "${fail_counts[$i]}" "$mode"
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

jq \
  --arg audit_root "$audit_root" \
  --arg compatibility_report "$compatibility_report" \
  --arg artifact_audit "$artifact_audit" \
  --arg proof_checksums "$proof_checksums" \
  --arg proof_checksums_validation "$proof_checksums_validation" \
  --arg trend_report_validation "$trend_report_validation" \
  --arg validation_log "$validation_log" \
  --argjson requested_history_window "$requested_history_window" \
  --argjson history_audits_checked "$history_audits_checked" \
  --argjson history_audits_passed "$history_audits_passed" \
  --argjson history_audits_failed "$history_audits_failed" \
  --argjson stable_reports_checked "$stable_reports_checked" \
  --argjson stable_reports_passed "$stable_reports_passed" \
  --argjson stable_reports_failed "$stable_reports_failed" \
  --argjson comparable_history_audits_checked "$comparable_history_audits_checked" \
  --argjson comparable_history_audits_passed "$comparable_history_audits_passed" \
  --argjson comparable_history_audits_failed "$comparable_history_audits_failed" \
  --argjson legacy_window_mismatch_audits "$legacy_window_mismatch_audits" \
  --argjson stable_comparable_reports_checked "$stable_comparable_reports_checked" \
  --argjson stable_comparable_reports_passed "$stable_comparable_reports_passed" \
  --argjson stable_comparable_reports_failed "$stable_comparable_reports_failed" \
  --argjson audit_roots_json "$(printf '%s\n' "${audit_roots[@]}" | jq -R . | jq -s .)" \
  --argjson audit_status_values_json "$(printf '%s\n' "${audit_status_values[@]}" | jq -R . | jq -s .)" \
  --argjson checked_counts_json "$(printf '%s\n' "${checked_counts[@]}" | jq -R 'tonumber' | jq -s .)" \
  --argjson pass_counts_json "$(printf '%s\n' "${pass_counts[@]}" | jq -R 'tonumber' | jq -s .)" \
  --argjson fail_counts_json "$(printf '%s\n' "${fail_counts[@]}" | jq -R 'tonumber' | jq -s .)" \
  '
  .audit_root = $audit_root
  | .generated_at = (.generated_at // now | tostring)
  | .requested_history_window = $requested_history_window
  | .history_audits_checked = $history_audits_checked
  | .history_audits_passed = $history_audits_passed
  | .history_audits_failed = $history_audits_failed
  | .stable_reports_checked = $stable_reports_checked
  | .stable_reports_passed = $stable_reports_passed
  | .stable_reports_failed = $stable_reports_failed
  | .comparable_history_audits_checked = $comparable_history_audits_checked
  | .comparable_history_audits_passed = $comparable_history_audits_passed
  | .comparable_history_audits_failed = $comparable_history_audits_failed
  | .legacy_window_mismatch_audits = $legacy_window_mismatch_audits
  | .stable_comparable_reports_checked = $stable_comparable_reports_checked
  | .stable_comparable_reports_passed = $stable_comparable_reports_passed
  | .stable_comparable_reports_failed = $stable_comparable_reports_failed
  | .validation_log = $validation_log
  | .compatibility_report = $compatibility_report
  | .artifact_audit = $artifact_audit
  | .proof_checksums = $proof_checksums
  | .proof_checksum_validation = $proof_checksums_validation
  | .trend_report_validation = $trend_report_validation
  | .audit_status = [
      range(0; $audit_roots_json | length) as $i
      | {
          status: $audit_status_values_json[$i],
          audit_root: $audit_roots_json[$i],
          reports_checked: $checked_counts_json[$i],
          reports_passed: $pass_counts_json[$i],
          reports_failed: $fail_counts_json[$i],
          mode: (if $checked_counts_json[$i] == $requested_history_window then "comparable" else "legacy-window-mismatch" end)
        }
    ]
  ' "$summary_manifest" >"$summary_manifest.tmp"
mv "$summary_manifest.tmp" "$summary_manifest"

{
  echo "AIReady release-readiness history trend artifact audit"
  echo "audit_root: $audit_root"
  echo
  echo "validated_artifacts:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$compatibility_report" \
    "$artifact_audit" \
    "$proof_checksums" \
    "$proof_checksums_validation" \
    "$trend_report_validation"
  echo
  echo "validated_history_audits:"
  printf '  - %s\n' "${audit_roots[@]}"
} >"$artifact_audit"

{
  echo "AIReady release-readiness history trend report validated"
  echo "audit_root: $audit_root"
  echo "requested_history_window: $requested_history_window"
  echo "history_audits_checked: $history_audits_checked"
  echo "history_audits_passed: $history_audits_passed"
  echo "history_audits_failed: $history_audits_failed"
  echo "stable_reports_checked: $stable_reports_checked"
  echo "stable_reports_passed: $stable_reports_passed"
  echo "stable_reports_failed: $stable_reports_failed"
  echo "comparable_history_audits_checked: $comparable_history_audits_checked"
  echo "comparable_history_audits_passed: $comparable_history_audits_passed"
  echo "comparable_history_audits_failed: $comparable_history_audits_failed"
  echo "legacy_window_mismatch_audits: $legacy_window_mismatch_audits"
  echo "stable_comparable_reports_checked: $stable_comparable_reports_checked"
  echo "stable_comparable_reports_passed: $stable_comparable_reports_passed"
  echo "stable_comparable_reports_failed: $stable_comparable_reports_failed"
} >"$trend_report_validation"

{
  echo "# AIReady Release Readiness History Trend Proof Checksums"
  echo
  echo "audit_root: $audit_root"
  echo "generated_at: $(jq -r '.generated_at' "$summary_manifest")"
  echo
  sha256sum \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log" \
    "$compatibility_report" \
    "$artifact_audit" \
    "$trend_report_validation"
} >"$proof_checksums"

{
  echo "AIReady release-readiness history trend proof checksum validation"
  echo "audit_root: $audit_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$proof_checksums" | sha256sum -c
} | tee "$proof_checksums_validation"

"$trend_validator" "$audit_root"

echo "AIReady release-readiness history trend proof normalized"
echo "audit_root: $audit_root"
echo "requested_history_window: $requested_history_window"
echo "history_audits_checked: $history_audits_checked"
echo "history_audits_passed: $history_audits_passed"
echo "history_audits_failed: $history_audits_failed"
