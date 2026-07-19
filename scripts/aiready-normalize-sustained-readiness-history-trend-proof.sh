#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-sustained-readiness-history-trend-proof.sh /path/to/history-trend-audit-root [...]

Rebuild stale AIReady sustained-readiness history trend audit packets from
their recorded history-audit roots using the current validator contract.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
history_validator="$workspace_root/scripts/aiready-validate-sustained-readiness-history-report.sh"
trend_validator="$workspace_root/scripts/aiready-validate-sustained-readiness-history-trend-report.sh"

if [[ ! -f "$history_validator" ]]; then
  echo "Missing history validator: $history_validator" >&2
  exit 1
fi

if [[ ! -f "$trend_validator" ]]; then
  echo "Missing trend validator: $trend_validator" >&2
  exit 1
fi

for audit_root in "$@"; do
  if [[ ! -d "$audit_root" ]]; then
    echo "Trend audit root not found: $audit_root" >&2
    exit 1
  fi

  summary_readme="$audit_root/README.md"
  summary_manifest="$audit_root/manifest.json"
  validation_log="$audit_root/history-trend-validation.txt"
  artifact_audit="$audit_root/artifact-audit.txt"
  checksums_output="$audit_root/proof-sha256.txt"
  checksums_validation_output="$audit_root/proof-sha256-validation.txt"
  trend_validation_output="$audit_root/history-trend-report-validation.txt"

  for path in \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log"; do
    if [[ ! -s "$path" ]]; then
      echo "Missing or empty prerequisite artifact: $path" >&2
      exit 1
    fi
  done

  mapfile -t audit_roots < <(jq -r '.audit_status[].audit_root' "$summary_manifest")
  if [[ "${#audit_roots[@]}" -eq 0 ]]; then
    echo "No history audit roots recorded in $summary_manifest" >&2
    exit 1
  fi

  requested_window="$(jq -r '.requested_history_window // empty' "$summary_manifest")"
  if ! [[ "$requested_window" =~ ^[1-9][0-9]*$ ]]; then
    requested_window="$(jq -r '.audit_status[0].reports_checked // empty' "$summary_manifest")"
  fi
  if ! [[ "$requested_window" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid requested_history_window in $summary_manifest: ${requested_window:-null}" >&2
    exit 1
  fi

  : >"$validation_log"

  validated_count=0
  failed_count=0
  status_lines=()
  pass_counts=()
  fail_counts=()
  checked_counts=()
  comparable_count=0
  comparable_passed=0
  comparable_failed=0
  requested_window_mismatch_count=0
  requested_window_mismatch_present=false
  authoritative_stability_basis="all-audits"

  for history_root in "${audit_roots[@]}"; do
    echo "Validating: $history_root" | tee -a "$validation_log"
    if "$history_validator" "$history_root" | tee -a "$validation_log"; then
      status_lines+=("PASS|$history_root")
      validated_count=$((validated_count + 1))
    else
      status_lines+=("FAIL|$history_root")
      failed_count=$((failed_count + 1))
    fi
    checked_counts+=("$(jq -r '.reports_checked' "$history_root/manifest.json")")
    pass_counts+=("$(jq -r '.reports_passed' "$history_root/manifest.json")")
    fail_counts+=("$(jq -r '.reports_failed' "$history_root/manifest.json")")
    echo | tee -a "$validation_log"
  done

  latest_checked="${checked_counts[0]}"
  latest_passed="${pass_counts[0]}"
  latest_failed="${fail_counts[0]}"
  stable_checked=true
  stable_passed=true
  stable_failed=true
  stable_comparable_checked=true
  stable_comparable_passed=true
  stable_comparable_failed=true

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

  for i in "${!audit_roots[@]}"; do
    if [[ "${checked_counts[$i]}" != "$requested_window" ]]; then
      requested_window_mismatch_count=$((requested_window_mismatch_count + 1))
      continue
    fi

    comparable_count=$((comparable_count + 1))
    if [[ "${status_lines[$i]%%|*}" == "PASS" ]]; then
      comparable_passed=$((comparable_passed + 1))
    else
      comparable_failed=$((comparable_failed + 1))
    fi
  done

  if [[ "$requested_window_mismatch_count" -gt 0 ]]; then
    requested_window_mismatch_present=true
    authoritative_stability_basis="comparable-set"
  fi

  if [[ "$comparable_count" -gt 0 ]]; then
    comparable_latest_index=""
    for i in "${!audit_roots[@]}"; do
      if [[ "${checked_counts[$i]}" == "$requested_window" ]]; then
        comparable_latest_index="$i"
        break
      fi
    done

    comparable_latest_checked="${checked_counts[$comparable_latest_index]}"
    comparable_latest_passed="${pass_counts[$comparable_latest_index]}"
    comparable_latest_failed="${fail_counts[$comparable_latest_index]}"

    for i in "${!audit_roots[@]}"; do
      if [[ "${checked_counts[$i]}" != "$requested_window" ]]; then
        continue
      fi
      if [[ "${checked_counts[$i]}" != "$comparable_latest_checked" ]]; then
        stable_comparable_checked=false
      fi
      if [[ "${pass_counts[$i]}" != "$comparable_latest_passed" ]]; then
        stable_comparable_passed=false
      fi
      if [[ "${fail_counts[$i]}" != "$comparable_latest_failed" ]]; then
        stable_comparable_failed=false
      fi
    done
  fi

  {
    echo "# AIReady Sustained Readiness History Trend Audit"
    echo
    echo "- Audit root: \`$audit_root\`"
    echo "- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`"
    echo "- Requested history window: \`$requested_window\`"
    echo "- History audits checked: \`$((validated_count + failed_count))\`"
    echo "- History audits passed: \`$validated_count\`"
    echo "- History audits failed: \`$failed_count\`"
    echo "- Stable reports_checked across audits: \`$stable_checked\`"
    echo "- Stable reports_passed across audits: \`$stable_passed\`"
    echo "- Stable reports_failed across audits: \`$stable_failed\`"
    echo "- Comparable audits with requested window \`$requested_window\`: \`$comparable_count\`"
    echo "- Comparable audits passed: \`$comparable_passed\`"
    echo "- Comparable audits failed: \`$comparable_failed\`"
    echo "- Requested-window mismatch audits excluded from comparable set: \`$requested_window_mismatch_count\`"
    echo "- Requested-window mismatch present: \`$requested_window_mismatch_present\`"
    echo "- Authoritative stability basis: \`$authoritative_stability_basis\`"
    echo "- Stable comparable reports_checked: \`$stable_comparable_checked\`"
    echo "- Stable comparable reports_passed: \`$stable_comparable_passed\`"
    echo "- Stable comparable reports_failed: \`$stable_comparable_failed\`"
    echo
    echo "## Audit status"
    for i in "${!status_lines[@]}"; do
      status="${status_lines[$i]%%|*}"
      history_root="${status_lines[$i]#*|}"
      checked="${checked_counts[$i]}"
      passed="${pass_counts[$i]}"
      failed="${fail_counts[$i]}"
      mode="comparable"
      if [[ "$checked" != "$requested_window" ]]; then
        mode="requested-window-mismatch"
      fi
      printf -- '- `%s` — `%s` (checked=%s passed=%s failed=%s mode=%s)\n' \
        "$status" "$history_root" "$checked" "$passed" "$failed" "$mode"
    done
    echo
    echo "## Aggregate evidence"
    echo
    echo "- Validation log: [history-trend-validation.txt](./history-trend-validation.txt)"
    echo "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
    echo "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
    echo "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
    echo "- Trend report validation: [history-trend-report-validation.txt](./history-trend-report-validation.txt)"
  } >"$summary_readme"

  {
    printf '{\n'
    printf '  "audit_root": "%s",\n' "$audit_root"
    printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '  "requested_history_window": %s,\n' "$requested_window"
    printf '  "history_audits_checked": %s,\n' "$((validated_count + failed_count))"
    printf '  "history_audits_passed": %s,\n' "$validated_count"
    printf '  "history_audits_failed": %s,\n' "$failed_count"
    printf '  "stable_reports_checked": %s,\n' "$stable_checked"
    printf '  "stable_reports_passed": %s,\n' "$stable_passed"
    printf '  "stable_reports_failed": %s,\n' "$stable_failed"
    printf '  "comparable_history_audits_checked": %s,\n' "$comparable_count"
    printf '  "comparable_history_audits_passed": %s,\n' "$comparable_passed"
    printf '  "comparable_history_audits_failed": %s,\n' "$comparable_failed"
    printf '  "requested_window_mismatch_audits": %s,\n' "$requested_window_mismatch_count"
    printf '  "requested_window_mismatch_present": %s,\n' "$requested_window_mismatch_present"
    printf '  "authoritative_stability_basis": "%s",\n' "$authoritative_stability_basis"
    printf '  "stable_comparable_reports_checked": %s,\n' "$stable_comparable_checked"
    printf '  "stable_comparable_reports_passed": %s,\n' "$stable_comparable_passed"
    printf '  "stable_comparable_reports_failed": %s,\n' "$stable_comparable_failed"
    printf '  "validation_log": "%s",\n' "$validation_log"
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
      history_root="${status_lines[$i]#*|}"
      mode="comparable"
      if [[ "${checked_counts[$i]}" != "$requested_window" ]]; then
        mode="requested-window-mismatch"
      fi
      printf '    {"status":"%s","audit_root":"%s","reports_checked":%s,"reports_passed":%s,"reports_failed":%s,"mode":"%s"}%s\n' \
        "$status" "$history_root" "${checked_counts[$i]}" "${pass_counts[$i]}" "${fail_counts[$i]}" "$mode" "$suffix"
    done
    printf '  ]\n'
    printf '}\n'
  } >"$summary_manifest"

  {
    echo "AIReady sustained-readiness history trend artifact audit"
    echo "audit_root: $audit_root"
    echo
    echo "validated_artifacts:"
    printf '  - %s\n' \
      "$summary_readme" \
      "$summary_manifest" \
      "$validation_log" \
      "$artifact_audit" \
      "$checksums_output" \
      "$checksums_validation_output" \
      "$trend_validation_output"
    echo
    echo "validated_history_audits:"
    printf '  - %s\n' "${audit_roots[@]}"
  } >"$artifact_audit"

  {
    echo "AIReady sustained-readiness history trend report validated"
    echo "audit_root: $audit_root"
    echo "history_audits_checked: $((validated_count + failed_count))"
    echo "history_audits_passed: $validated_count"
    echo "history_audits_failed: $failed_count"
    echo "requested_history_window: $requested_window"
    echo "comparable_history_audits_checked: $comparable_count"
    echo "comparable_history_audits_passed: $comparable_passed"
    echo "comparable_history_audits_failed: $comparable_failed"
    echo "requested_window_mismatch_audits: $requested_window_mismatch_count"
    echo "requested_window_mismatch_present: $requested_window_mismatch_present"
    echo "authoritative_stability_basis: $authoritative_stability_basis"
  } >"$trend_validation_output"

  {
    echo "# AIReady Sustained Readiness History Trend Proof Checksums"
    echo
    echo "audit_root: $audit_root"
    echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
    sha256sum \
      "$summary_readme" \
      "$summary_manifest" \
      "$validation_log" \
      "$artifact_audit" \
      "$trend_validation_output"
  } >"$checksums_output"

  {
    echo "AIReady sustained-readiness history trend proof checksum validation"
    echo "audit_root: $audit_root"
    echo
    grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
  } | tee "$checksums_validation_output"

  "$trend_validator" "$audit_root" >/dev/null

  echo "Normalized sustained-readiness history trend proof"
  echo "audit_root: $audit_root"
  echo "history_audits_checked: $((validated_count + failed_count))"
  echo "history_audits_passed: $validated_count"
  echo "history_audits_failed: $failed_count"
done
