#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-standby-readiness-check.sh [output_root] [history_count]

Runs the full local AIReady standby-for-first-intake gate as one disposable
proof packet:
1. fresh sustained-readiness pass
2. release-readiness history trend audit
3. sustained-readiness history trend audit

Defaults:
  output_root   -> reports/aiready-standby-readiness-<timestamp>
  history_count -> 5
EOF
}

if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$workspace_root/reports/aiready-standby-readiness-$(date +%Y-%m-%d-%H%M-AWST)}"
history_count="${2:-5}"
sustained_script="$workspace_root/scripts/aiready-sustained-readiness-check.sh"
release_trend_script="$workspace_root/scripts/aiready-validate-release-readiness-history-trend.sh"
sustained_trend_script="$workspace_root/scripts/aiready-validate-sustained-readiness-history-trend.sh"
report_validator="$workspace_root/scripts/aiready-validate-standby-readiness-report.sh"

if ! [[ "$history_count" =~ ^[1-9][0-9]*$ ]]; then
  echo "History count must be a positive integer: $history_count" >&2
  exit 1
fi

for path in \
  "$sustained_script" \
  "$release_trend_script" \
  "$sustained_trend_script" \
  "$report_validator"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required script: $path" >&2
    exit 1
  fi
done

if [[ -e "$output_root" ]]; then
  echo "Output root already exists: $output_root" >&2
  exit 1
fi

mkdir -p "$output_root"

sustained_root="$output_root/sustained-readiness"
release_trend_root="$output_root/release-history-trend"
sustained_trend_root="$output_root/sustained-history-trend"
sustained_output="$output_root/sustained-readiness-output.txt"
release_trend_output="$output_root/release-history-trend-output.txt"
sustained_trend_output="$output_root/sustained-history-trend-output.txt"
summary_readme="$output_root/README.md"
summary_manifest="$output_root/manifest.json"
artifact_audit="$output_root/artifact-audit.txt"
summary_validation="$output_root/standby-readiness-validation.txt"
checksums_output="$output_root/proof-sha256.txt"
checksums_validation_output="$output_root/proof-sha256-validation.txt"
report_validation_output="$output_root/standby-readiness-report-validation.txt"
report_validation_tmp="$output_root/.standby-readiness-report-validation.tmp"

"$sustained_script" "$sustained_root" "$history_count" | tee "$sustained_output"
"$release_trend_script" "$release_trend_root" "$history_count" | tee "$release_trend_output"
"$sustained_trend_script" "$sustained_trend_root" "$history_count" | tee "$sustained_trend_output"

for path in \
  "$sustained_root/manifest.json" \
  "$release_trend_root/manifest.json" \
  "$sustained_trend_root/manifest.json"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing nested manifest: $path" >&2
    exit 1
  fi
done

sustained_history_reports_failed="$(sed -n 's/.*"history_reports_failed": \([0-9][0-9]*\).*/\1/p' "$sustained_root/manifest.json" | head -n 1)"
release_trend_failed="$(sed -n 's/.*"history_audits_failed": \([0-9][0-9]*\).*/\1/p' "$release_trend_root/manifest.json" | head -n 1)"
release_trend_comparable_failed="$(sed -n 's/.*"comparable_history_audits_failed": \([0-9][0-9]*\).*/\1/p' "$release_trend_root/manifest.json" | head -n 1)"
release_trend_legacy_mismatch="$(sed -n 's/.*"legacy_window_mismatch_audits": \([0-9][0-9]*\).*/\1/p' "$release_trend_root/manifest.json" | head -n 1)"
sustained_trend_failed="$(sed -n 's/.*"history_audits_failed": \([0-9][0-9]*\).*/\1/p' "$sustained_trend_root/manifest.json" | head -n 1)"
sustained_trend_comparable_failed="$(sed -n 's/.*"comparable_history_audits_failed": \([0-9][0-9]*\).*/\1/p' "$sustained_trend_root/manifest.json" | head -n 1)"
sustained_trend_window_mismatch="$(sed -n 's/.*"requested_window_mismatch_audits": \([0-9][0-9]*\).*/\1/p' "$sustained_trend_root/manifest.json" | head -n 1)"

for value_name in \
  sustained_history_reports_failed \
  release_trend_failed \
  release_trend_comparable_failed \
  release_trend_legacy_mismatch \
  sustained_trend_failed \
  sustained_trend_comparable_failed \
  sustained_trend_window_mismatch; do
  value="${!value_name}"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "Missing numeric result in nested manifest: $value_name" >&2
    exit 1
  fi
done

if [[ "$sustained_history_reports_failed" != "0" ]]; then
  echo "Sustained readiness reported failed history items: $sustained_history_reports_failed" >&2
  exit 1
fi

if [[ "$release_trend_failed" != "0" ]]; then
  echo "Release history trend failures: $release_trend_failed" >&2
  exit 1
fi

if [[ "$release_trend_comparable_failed" != "0" ]]; then
  echo "Release history trend comparable-set failures: $release_trend_comparable_failed" >&2
  exit 1
fi

if [[ "$release_trend_legacy_mismatch" != "0" ]]; then
  echo "Release history trend legacy-window mismatches: $release_trend_legacy_mismatch" >&2
  exit 1
fi

if [[ "$sustained_trend_failed" != "0" ]]; then
  echo "Sustained history trend failures: $sustained_trend_failed" >&2
  exit 1
fi

if [[ "$sustained_trend_comparable_failed" != "0" ]]; then
  echo "Sustained history trend comparable-set failures: $sustained_trend_comparable_failed" >&2
  exit 1
fi

if [[ "$sustained_trend_window_mismatch" != "0" ]]; then
  echo "Sustained history trend requested-window mismatches: $sustained_trend_window_mismatch" >&2
  exit 1
fi

cat >"$summary_readme" <<EOF
# AIReady Standby Readiness Check

- Audit root: \`$output_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`
- Requested history window: \`$history_count\`
- Sustained history failures: \`$sustained_history_reports_failed\`
- Release-history trend failures: \`$release_trend_failed\`
- Release-history comparable failures: \`$release_trend_comparable_failed\`
- Release-history legacy-window mismatches: \`$release_trend_legacy_mismatch\`
- Sustained-history trend failures: \`$sustained_trend_failed\`
- Sustained-history comparable failures: \`$sustained_trend_comparable_failed\`
- Sustained-history requested-window mismatches: \`$sustained_trend_window_mismatch\`

## Current readiness lane

- Sustained-readiness root: [sustained-readiness/](./sustained-readiness/)
- Sustained-readiness summary: [sustained-readiness/README.md](./sustained-readiness/README.md)
- Sustained-readiness manifest: [sustained-readiness/manifest.json](./sustained-readiness/manifest.json)
- Sustained-readiness command output: [sustained-readiness-output.txt](./sustained-readiness-output.txt)

## Trend lanes

- Release-history trend root: [release-history-trend/](./release-history-trend/)
- Release-history trend summary: [release-history-trend/README.md](./release-history-trend/README.md)
- Release-history trend manifest: [release-history-trend/manifest.json](./release-history-trend/manifest.json)
- Release-history trend command output: [release-history-trend-output.txt](./release-history-trend-output.txt)
- Sustained-history trend root: [sustained-history-trend/](./sustained-history-trend/)
- Sustained-history trend summary: [sustained-history-trend/README.md](./sustained-history-trend/README.md)
- Sustained-history trend manifest: [sustained-history-trend/manifest.json](./sustained-history-trend/manifest.json)
- Sustained-history trend command output: [sustained-history-trend-output.txt](./sustained-history-trend-output.txt)

## Aggregate evidence

- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)
- Standby-readiness validation: [standby-readiness-validation.txt](./standby-readiness-validation.txt)
- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)
- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)
- Report validation: [standby-readiness-report-validation.txt](./standby-readiness-report-validation.txt)

## Outcome

This disposable root proves the local AIReady system is standing by for the
first real intake with:

1. one fresh sustained-readiness pass
2. a clean release-readiness history-trend packet
3. a clean sustained-readiness history-trend packet
EOF

cat >"$summary_manifest" <<EOF
{
  "audit_root": "$output_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "requested_history_window": $history_count,
  "sustained_readiness_root": "$sustained_root",
  "sustained_readiness_summary": "$sustained_root/README.md",
  "sustained_readiness_manifest": "$sustained_root/manifest.json",
  "sustained_readiness_output": "$sustained_output",
  "release_history_trend_root": "$release_trend_root",
  "release_history_trend_summary": "$release_trend_root/README.md",
  "release_history_trend_manifest": "$release_trend_root/manifest.json",
  "release_history_trend_output": "$release_trend_output",
  "sustained_history_trend_root": "$sustained_trend_root",
  "sustained_history_trend_summary": "$sustained_trend_root/README.md",
  "sustained_history_trend_manifest": "$sustained_trend_root/manifest.json",
  "sustained_history_trend_output": "$sustained_trend_output",
  "sustained_history_reports_failed": $sustained_history_reports_failed,
  "release_history_trend_failed": $release_trend_failed,
  "release_history_trend_comparable_failed": $release_trend_comparable_failed,
  "release_history_trend_legacy_window_mismatches": $release_trend_legacy_mismatch,
  "sustained_history_trend_failed": $sustained_trend_failed,
  "sustained_history_trend_comparable_failed": $sustained_trend_comparable_failed,
  "sustained_history_trend_requested_window_mismatches": $sustained_trend_window_mismatch,
  "artifact_audit": "$artifact_audit",
  "summary_validation": "$summary_validation",
  "proof_checksums": "$checksums_output",
  "proof_checksum_validation": "$checksums_validation_output",
  "report_validation": "$report_validation_output"
}
EOF

{
  echo "AIReady standby readiness artifact audit"
  echo "audit_root: $output_root"
  echo
  echo "validated_artifacts:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$sustained_output" \
    "$release_trend_output" \
    "$sustained_trend_output" \
    "$artifact_audit" \
    "$summary_validation" \
    "$checksums_output" \
    "$checksums_validation_output" \
    "$report_validation_output"
  echo
  echo "validated_nested_artifacts:"
  printf '  - %s\n' \
    "$sustained_root/README.md" \
    "$sustained_root/manifest.json" \
    "$sustained_root/sustained-readiness-report-validation.txt" \
    "$sustained_root/proof-sha256-validation.txt" \
    "$release_trend_root/README.md" \
    "$release_trend_root/manifest.json" \
    "$release_trend_root/history-trend-report-validation.txt" \
    "$release_trend_root/proof-sha256-validation.txt" \
    "$sustained_trend_root/README.md" \
    "$sustained_trend_root/manifest.json" \
    "$sustained_trend_root/history-trend-report-validation.txt" \
    "$sustained_trend_root/proof-sha256-validation.txt"
} >"$artifact_audit"

{
  echo "AIReady standby readiness summary validated"
  echo "audit_root: $output_root"
  echo "requested_history_window: $history_count"
  echo "sustained_history_reports_failed: $sustained_history_reports_failed"
  echo "release_history_trend_failed: $release_trend_failed"
  echo "release_history_trend_comparable_failed: $release_trend_comparable_failed"
  echo "release_history_trend_legacy_window_mismatches: $release_trend_legacy_mismatch"
  echo "sustained_history_trend_failed: $sustained_trend_failed"
  echo "sustained_history_trend_comparable_failed: $sustained_trend_comparable_failed"
  echo "sustained_history_trend_requested_window_mismatches: $sustained_trend_window_mismatch"
} >"$summary_validation"

"$report_validator" --preproof "$output_root" >"$report_validation_tmp"
mv "$report_validation_tmp" "$report_validation_output"

{
  echo "# AIReady Standby Readiness Proof Checksums"
  echo
  echo "audit_root: $output_root"
  echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  sha256sum \
    "$summary_readme" \
    "$summary_manifest" \
    "$sustained_output" \
    "$release_trend_output" \
    "$sustained_trend_output" \
    "$artifact_audit" \
    "$summary_validation" \
    "$report_validation_output"
} >"$checksums_output"

{
  echo "AIReady standby readiness proof checksum validation"
  echo "audit_root: $output_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
} | tee "$checksums_validation_output"

"$report_validator" "$output_root" >"$report_validation_tmp"
mv "$report_validation_tmp" "$report_validation_output"

for path in \
  "$summary_readme" \
  "$summary_manifest" \
  "$sustained_output" \
  "$release_trend_output" \
  "$sustained_trend_output" \
  "$artifact_audit" \
  "$summary_validation" \
  "$checksums_output" \
  "$checksums_validation_output" \
  "$report_validation_output"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty standby-readiness artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady standby readiness check completed"
echo "audit_root: $output_root"
echo "requested_history_window: $history_count"
echo "sustained_history_reports_failed: $sustained_history_reports_failed"
echo "release_history_trend_failed: $release_trend_failed"
echo "release_history_trend_comparable_failed: $release_trend_comparable_failed"
echo "release_history_trend_legacy_window_mismatches: $release_trend_legacy_mismatch"
echo "sustained_history_trend_failed: $sustained_trend_failed"
echo "sustained_history_trend_comparable_failed: $sustained_trend_comparable_failed"
echo "sustained_history_trend_requested_window_mismatches: $sustained_trend_window_mismatch"
