#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-sustained-readiness-history-proof.sh /path/to/history-audit-root [...]

Rebuild stale AIReady sustained-readiness history audit packets from their
recorded report_root set using the current single-report validator.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_validator="$workspace_root/scripts/aiready-validate-sustained-readiness-report.sh"
history_validator="$workspace_root/scripts/aiready-validate-sustained-readiness-history-report.sh"

if [[ ! -f "$report_validator" ]]; then
  echo "Missing report validator: $report_validator" >&2
  exit 1
fi

if [[ ! -f "$history_validator" ]]; then
  echo "Missing history validator: $history_validator" >&2
  exit 1
fi

for audit_root in "$@"; do
  if [[ ! -d "$audit_root" ]]; then
    echo "History audit root not found: $audit_root" >&2
    exit 1
  fi

  summary_readme="$audit_root/README.md"
  summary_manifest="$audit_root/manifest.json"
  validation_log="$audit_root/history-validation.txt"
  artifact_audit="$audit_root/artifact-audit.txt"
  checksums_output="$audit_root/proof-sha256.txt"
  checksums_validation_output="$audit_root/proof-sha256-validation.txt"
  history_report_validation="$audit_root/history-report-validation.txt"

  for path in \
    "$summary_readme" \
    "$summary_manifest" \
    "$validation_log"; do
    if [[ ! -s "$path" ]]; then
      echo "Missing or empty prerequisite artifact: $path" >&2
      exit 1
    fi
  done

  mapfile -t report_roots < <(jq -r '.report_status[].report_root' "$summary_manifest")
  if [[ "${#report_roots[@]}" -eq 0 ]]; then
    echo "No report roots recorded in $summary_manifest" >&2
    exit 1
  fi
  requested_window="${#report_roots[@]}"

  : >"$validation_log"

  validated_count=0
  failed_count=0
  status_lines=()
  for report_root in "${report_roots[@]}"; do
    echo "Validating: $report_root" | tee -a "$validation_log"
    if "$report_validator" "$report_root" | tee -a "$validation_log"; then
      status_lines+=("PASS|$report_root")
      validated_count=$((validated_count + 1))
    else
      status_lines+=("FAIL|$report_root")
      failed_count=$((failed_count + 1))
    fi
    echo | tee -a "$validation_log"
  done

  {
    echo "# AIReady Sustained Readiness History Audit"
    echo
    echo "- Audit root: \`$audit_root\`"
    echo "- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`"
    echo "- Requested history window: \`$requested_window\`"
    echo "- Reports checked: \`$((validated_count + failed_count))\`"
    echo "- Reports passed: \`$validated_count\`"
    echo "- Reports failed: \`$failed_count\`"
    echo "- Validated report packets: \`$(( ${#report_roots[@]} * 2 ))\`"
    echo
    echo "## Report status"
    for status_line in "${status_lines[@]}"; do
      status="${status_line%%|*}"
      report_root="${status_line#*|}"
      printf -- '- `%s` — `%s`\n' "$status" "$report_root"
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

  {
    printf '{\n'
    printf '  "audit_root": "%s",\n' "$audit_root"
    printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '  "requested_history_window": %s,\n' "$requested_window"
    printf '  "reports_checked": %s,\n' "$((validated_count + failed_count))"
    printf '  "reports_passed": %s,\n' "$validated_count"
    printf '  "reports_failed": %s,\n' "$failed_count"
    printf '  "validation_log": "%s",\n' "$validation_log"
    printf '  "artifact_audit": "%s",\n' "$artifact_audit"
    printf '  "validated_report_packet_count": %s,\n' "$(( ${#report_roots[@]} * 2 ))"
    printf '  "proof_checksums": "%s",\n' "$checksums_output"
    printf '  "proof_checksum_validation": "%s",\n' "$checksums_validation_output"
    printf '  "history_report_validation": "%s",\n' "$history_report_validation"
    printf '  "report_status": [\n'
    for i in "${!status_lines[@]}"; do
      suffix=","
      if [[ "$i" -eq $(("${#status_lines[@]}" - 1)) ]]; then
        suffix=""
      fi
      status="${status_lines[$i]%%|*}"
      report_root="${status_lines[$i]#*|}"
      printf '    {"status":"%s","report_root":"%s"}%s\n' "$status" "$report_root" "$suffix"
    done
    printf '  ]\n'
    printf '}\n'
  } >"$summary_manifest"

  {
    echo "AIReady sustained-readiness history artifact audit"
    echo "audit_root: $audit_root"
    echo
    echo "validated_artifacts:"
    printf '  - %s\n' \
      "$summary_readme" \
      "$summary_manifest" \
      "$validation_log" \
      "$history_report_validation" \
      "$checksums_output" \
      "$checksums_validation_output"
    echo
    echo "validated_report_roots:"
    printf '  - %s\n' "${report_roots[@]}"
    echo
    echo "validated_report_packets:"
    for report_root in "${report_roots[@]}"; do
      printf '  - %s\n' "$report_root/sustained-readiness-report-validation.txt"
      printf '  - %s\n' "$report_root/proof-sha256-validation.txt"
    done
    echo
    echo "validated_report_packet_count: $(( ${#report_roots[@]} * 2 ))"
  } >"$artifact_audit"

  {
    echo "# AIReady Sustained Readiness History Proof Checksums"
    echo
    echo "audit_root: $audit_root"
    echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
    sha256sum \
      "$summary_readme" \
      "$summary_manifest" \
      "$validation_log" \
      "$artifact_audit" \
      "$history_report_validation"
  } >"$checksums_output"

  {
    echo "AIReady sustained-readiness history proof checksum validation"
    echo "audit_root: $audit_root"
    echo
    grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
  } | tee "$checksums_validation_output"

  "$history_validator" "$audit_root" >/dev/null

  echo "Normalized sustained-readiness history proof"
  echo "audit_root: $audit_root"
  echo "reports_checked: $((validated_count + failed_count))"
  echo "reports_passed: $validated_count"
  echo "reports_failed: $failed_count"
done
