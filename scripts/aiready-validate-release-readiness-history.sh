#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-release-readiness-history.sh [output_root] [count]

Validate the latest N AIReady release-readiness report roots using the
single-report validator and capture one aggregate history audit packet.

Defaults:
  output_root -> reports/aiready-release-readiness-history-<timestamp>
  count       -> 5
EOF
}

if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$workspace_root/reports/aiready-release-readiness-history-$(date +%Y-%m-%d-%H%M-AWST)}"
count="${2:-5}"
validator="$workspace_root/scripts/aiready-validate-release-readiness-report.sh"
history_validator="$workspace_root/scripts/aiready-validate-release-readiness-history-report.sh"
compatibility_classifier="$workspace_root/scripts/aiready-classify-release-readiness-proof-compatibility.sh"
normalizer="$workspace_root/scripts/aiready-normalize-release-readiness-proof.sh"

if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
  echo "Count must be a positive integer: $count" >&2
  exit 1
fi

if [[ ! -f "$validator" ]]; then
  echo "Missing required validator: $validator" >&2
  exit 1
fi

if [[ ! -f "$history_validator" ]]; then
  echo "Missing history validator: $history_validator" >&2
  exit 1
fi

if [[ ! -f "$compatibility_classifier" ]]; then
  echo "Missing compatibility classifier: $compatibility_classifier" >&2
  exit 1
fi

if [[ ! -f "$normalizer" ]]; then
  echo "Missing normalizer: $normalizer" >&2
  exit 1
fi

if [[ -e "$output_root" ]]; then
  echo "Output root already exists: $output_root" >&2
  exit 1
fi

mapfile -t candidate_report_roots < <(
  compgen -G "$workspace_root/reports/aiready-release-readiness-[0-9]*-AWST" |
    sort -r
)

if [[ "${#candidate_report_roots[@]}" -eq 0 ]]; then
  echo "No release-readiness report roots found under $workspace_root/reports" >&2
  exit 1
fi

report_roots=()
skipped_structurally_partial_roots=()
normalized_legacy_roots=()

for candidate_root in "${candidate_report_roots[@]}"; do
  if [[ "${#report_roots[@]}" -ge "$count" ]]; then
    break
  fi

  if "$validator" "$candidate_root" >/dev/null 2>&1; then
    report_roots+=("$candidate_root")
    continue
  fi

  classification_output="$("$compatibility_classifier" "$candidate_root")"
  classification="$(printf '%s\n' "$classification_output" | sed -n 's/^classification: //p' | head -n 1)"

  case "$classification" in
    normalizable-legacy)
      "$normalizer" "$candidate_root" >/dev/null
      if "$validator" "$candidate_root" >/dev/null 2>&1; then
        normalized_legacy_roots+=("$candidate_root")
        report_roots+=("$candidate_root")
        continue
      fi
      skipped_structurally_partial_roots+=("$candidate_root")
      ;;
    structurally-partial)
      skipped_structurally_partial_roots+=("$candidate_root")
      ;;
  esac
done

if [[ "${#report_roots[@]}" -lt "$count" ]]; then
  echo "Could not assemble $count validator-compatible release-readiness roots under $workspace_root/reports" >&2
  echo "Validator-compatible roots found: ${#report_roots[@]}" >&2
  if [[ "${#skipped_structurally_partial_roots[@]}" -gt 0 ]]; then
    echo "Skipped structurally partial roots:" >&2
    printf '%s\n' "${skipped_structurally_partial_roots[@]}" >&2
  fi
  exit 1
fi

mkdir -p "$output_root"

summary_readme="$output_root/README.md"
summary_manifest="$output_root/manifest.json"
validation_log="$output_root/history-validation.txt"
artifact_audit="$output_root/artifact-audit.txt"
checksums_output="$output_root/proof-sha256.txt"
checksums_validation_output="$output_root/proof-sha256-validation.txt"
history_report_validation="$output_root/history-report-validation.txt"

: >"$validation_log"

validated_count=0
failed_count=0
status_lines=()
for report_root in "${report_roots[@]}"; do
  echo "Validating: $report_root" | tee -a "$validation_log"
  if "$validator" "$report_root" | tee -a "$validation_log"; then
    status_lines+=("PASS|$report_root")
    validated_count=$((validated_count + 1))
  else
    status_lines+=("FAIL|$report_root")
    failed_count=$((failed_count + 1))
  fi
  echo | tee -a "$validation_log"
done

{
  echo "# AIReady Release Readiness History Audit"
  echo
  echo "- Audit root: \`$output_root\`"
  echo "- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`"
  echo "- Requested history window: \`$count\`"
  echo "- Reports checked: \`$((validated_count + failed_count))\`"
  echo "- Reports passed: \`$validated_count\`"
  echo "- Reports failed: \`$failed_count\`"
  echo "- Validated report packets: \`$(( ${#report_roots[@]} * 2 ))\`"
  echo "- Normalized legacy roots used: \`${#normalized_legacy_roots[@]}\`"
  echo "- Skipped structurally partial roots while filling window: \`${#skipped_structurally_partial_roots[@]}\`"
  echo
  echo "## Report status"
  for status_line in "${status_lines[@]}"; do
    status="${status_line%%|*}"
    report_root="${status_line#*|}"
    printf -- '- `%s` — `%s`\n' "$status" "$report_root"
  done
  if [[ "${#normalized_legacy_roots[@]}" -gt 0 ]]; then
    echo
    echo "## Normalized legacy roots"
    for report_root in "${normalized_legacy_roots[@]}"; do
      printf -- '- `%s`\n' "$report_root"
    done
  fi
  if [[ "${#skipped_structurally_partial_roots[@]}" -gt 0 ]]; then
    echo
    echo "## Skipped structurally partial roots"
    for report_root in "${skipped_structurally_partial_roots[@]}"; do
      printf -- '- `%s`\n' "$report_root"
    done
  fi
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
  printf '  "audit_root": "%s",\n' "$output_root"
  printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '  "requested_history_window": %s,\n' "$count"
  printf '  "reports_checked": %s,\n' "$((validated_count + failed_count))"
  printf '  "reports_passed": %s,\n' "$validated_count"
  printf '  "reports_failed": %s,\n' "$failed_count"
  printf '  "validation_log": "%s",\n' "$validation_log"
  printf '  "artifact_audit": "%s",\n' "$artifact_audit"
  printf '  "validated_report_packet_count": %s,\n' "$(( ${#report_roots[@]} * 2 ))"
  printf '  "normalized_legacy_roots": [\n'
  for i in "${!normalized_legacy_roots[@]}"; do
    suffix=","
    if [[ "$i" -eq $(("${#normalized_legacy_roots[@]}" - 1)) ]]; then
      suffix=""
    fi
    printf '    "%s"%s\n' "${normalized_legacy_roots[$i]}" "$suffix"
  done
  printf '  ],\n'
  printf '  "skipped_structurally_partial_roots": [\n'
  for i in "${!skipped_structurally_partial_roots[@]}"; do
    suffix=","
    if [[ "$i" -eq $(("${#skipped_structurally_partial_roots[@]}" - 1)) ]]; then
      suffix=""
    fi
    printf '    "%s"%s\n' "${skipped_structurally_partial_roots[$i]}" "$suffix"
  done
  printf '  ],\n'
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

pass_log_count="$(rg -c '^- `PASS`' "$summary_readme" 2>/dev/null || printf '0\n')"
fail_log_count="$(rg -c '^- `FAIL`' "$summary_readme" 2>/dev/null || printf '0\n')"

if [[ "$validated_count" != "$pass_log_count" ]]; then
  echo "reports_passed does not match README PASS count" >&2
  exit 1
fi

if [[ "$failed_count" != "$fail_log_count" ]]; then
  echo "reports_failed does not match README FAIL count" >&2
  exit 1
fi

{
  echo "AIReady release-readiness history report validated"
  echo "audit_root: $output_root"
  echo "reports_checked: $((validated_count + failed_count))"
  echo "reports_passed: $validated_count"
  echo "reports_failed: $failed_count"
} >"$history_report_validation"

{
  echo "AIReady release-readiness history artifact audit"
  echo "audit_root: $output_root"
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
  if [[ "${#normalized_legacy_roots[@]}" -gt 0 ]]; then
    echo
    echo "normalized_legacy_roots:"
    printf '  - %s\n' "${normalized_legacy_roots[@]}"
  fi
  if [[ "${#skipped_structurally_partial_roots[@]}" -gt 0 ]]; then
    echo
    echo "skipped_structurally_partial_roots:"
    printf '  - %s\n' "${skipped_structurally_partial_roots[@]}"
  fi
  echo
  echo "validated_report_packets:"
  for report_root in "${report_roots[@]}"; do
    printf '  - %s\n' "$report_root/release-readiness-report-validation.txt"
    printf '  - %s\n' "$report_root/proof-sha256-validation.txt"
  done
  echo
  echo "validated_report_packet_count: $(( ${#report_roots[@]} * 2 ))"
} >"$artifact_audit"

{
  echo "# AIReady Release Readiness History Proof Checksums"
  echo
  echo "audit_root: $output_root"
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
  echo "AIReady release-readiness history proof checksum validation"
  echo "audit_root: $output_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
} | tee "$checksums_validation_output"

"$history_validator" "$output_root"

for path in \
  "$summary_readme" \
  "$summary_manifest" \
  "$validation_log" \
  "$artifact_audit" \
  "$checksums_output" \
  "$checksums_validation_output" \
  "$history_report_validation"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty output artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady release-readiness history audit completed"
echo "audit_root: $output_root"
echo "reports_checked: $((validated_count + failed_count))"
echo "reports_passed: $validated_count"
echo "reports_failed: $failed_count"

if [[ "$failed_count" -gt 0 ]]; then
  exit 1
fi
