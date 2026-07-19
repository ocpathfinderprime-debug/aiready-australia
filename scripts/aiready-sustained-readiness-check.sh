#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-sustained-readiness-check.sh [output_root] [history_count]

Runs one fresh AIReady release-readiness check, then validates the latest
release-readiness history window so the operator can confirm both a current
pass and recent stability from one disposable evidence root.

Defaults:
  output_root   -> reports/aiready-sustained-readiness-<timestamp>
  history_count -> 5
EOF
}

if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$workspace_root/reports/aiready-sustained-readiness-$(date +%Y-%m-%d-%H%M-AWST)}"
history_count="${2:-5}"
release_readiness_script="$workspace_root/scripts/aiready-release-readiness-check.sh"
history_script="$workspace_root/scripts/aiready-validate-release-readiness-history.sh"
sustained_validator="$workspace_root/scripts/aiready-validate-sustained-readiness-report.sh"

if ! [[ "$history_count" =~ ^[1-9][0-9]*$ ]]; then
  echo "History count must be a positive integer: $history_count" >&2
  exit 1
fi

for path in "$release_readiness_script" "$history_script" "$sustained_validator"; do
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

release_readiness_root="$output_root/release-readiness"
history_root="$output_root/history"
release_readiness_output="$output_root/release-readiness-output.txt"
history_output="$output_root/history-output.txt"
summary_readme="$output_root/README.md"
summary_manifest="$output_root/manifest.json"
artifact_audit="$output_root/artifact-audit.txt"
checksums_output="$output_root/proof-sha256.txt"
checksums_validation_output="$output_root/proof-sha256-validation.txt"
summary_validation_output="$output_root/sustained-readiness-validation.txt"
report_validation_output="$output_root/sustained-readiness-report-validation.txt"
report_validation_tmp="$output_root/.sustained-readiness-report-validation.tmp"

"$release_readiness_script" "$release_readiness_root" "$history_count" | tee "$release_readiness_output"
"$history_script" "$history_root" "$history_count" | tee "$history_output"

if [[ ! -f "$release_readiness_root/manifest.json" ]]; then
  echo "Missing release-readiness manifest: $release_readiness_root/manifest.json" >&2
  exit 1
fi

if [[ ! -f "$history_root/manifest.json" ]]; then
  echo "Missing history manifest: $history_root/manifest.json" >&2
  exit 1
fi

history_reports_checked="$(sed -n 's/.*"reports_checked": \([0-9][0-9]*\).*/\1/p' "$history_root/manifest.json" | head -n 1)"
history_reports_passed="$(sed -n 's/.*"reports_passed": \([0-9][0-9]*\).*/\1/p' "$history_root/manifest.json" | head -n 1)"
history_reports_failed="$(sed -n 's/.*"reports_failed": \([0-9][0-9]*\).*/\1/p' "$history_root/manifest.json" | head -n 1)"

for value_name in history_reports_checked history_reports_passed history_reports_failed; do
  value="${!value_name}"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "Missing numeric history value: $value_name" >&2
    exit 1
  fi
done

if [[ "$history_reports_checked" != "$history_count" ]]; then
  echo "History reports_checked does not match requested window: $history_reports_checked vs $history_count" >&2
  exit 1
fi

if [[ "$history_reports_failed" != "0" ]]; then
  echo "History audit reported failures: $history_reports_failed" >&2
  exit 1
fi

cat >"$summary_readme" <<EOF
# AIReady Sustained Readiness Check

- Audit root: \`$output_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`
- Requested history window: \`$history_count\`
- History window: \`$history_count\`
- History reports checked: \`$history_reports_checked\`
- History reports passed: \`$history_reports_passed\`
- History reports failed: \`$history_reports_failed\`

## Fresh release-readiness pass

- Fresh release-readiness root: [release-readiness/](./release-readiness/)
- Fresh release-readiness summary: [release-readiness/README.md](./release-readiness/README.md)
- Fresh release-readiness manifest: [release-readiness/manifest.json](./release-readiness/manifest.json)
- Fresh release-readiness command output: [release-readiness-output.txt](./release-readiness-output.txt)

## Recent stability window

- History audit root: [history/](./history/)
- History audit summary: [history/README.md](./history/README.md)
- History audit manifest: [history/manifest.json](./history/manifest.json)
- History audit command output: [history-output.txt](./history-output.txt)

## Aggregate evidence

- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)
- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)
- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)
- Sustained-readiness validation: [sustained-readiness-validation.txt](./sustained-readiness-validation.txt)

## Outcome

This disposable root proves both:

1. the latest local AIReady release-readiness gate passed end to end
2. the latest \`$history_count\` release-readiness roots validate cleanly as a stability window
EOF

cat >"$summary_manifest" <<EOF
{
  "audit_root": "$output_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "requested_history_window": $history_count,
  "history_window": $history_count,
  "fresh_release_readiness_root": "$release_readiness_root",
  "fresh_release_readiness_summary": "$release_readiness_root/README.md",
  "fresh_release_readiness_manifest": "$release_readiness_root/manifest.json",
  "fresh_release_readiness_output": "$release_readiness_output",
  "history_audit_root": "$history_root",
  "history_audit_summary": "$history_root/README.md",
  "history_audit_manifest": "$history_root/manifest.json",
  "history_audit_output": "$history_output",
  "history_reports_checked": $history_reports_checked,
  "history_reports_passed": $history_reports_passed,
  "history_reports_failed": $history_reports_failed,
  "artifact_audit": "$artifact_audit",
  "proof_checksums": "$checksums_output",
  "proof_checksum_validation": "$checksums_validation_output",
  "summary_validation": "$summary_validation_output",
  "report_validation": "$report_validation_output"
}
EOF

{
  echo "AIReady sustained readiness artifact audit"
  echo "audit_root: $output_root"
  echo
  echo "validated_artifacts:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$release_readiness_output" \
    "$history_output" \
    "$artifact_audit" \
    "$checksums_output" \
    "$checksums_validation_output" \
    "$summary_validation_output" \
    "$report_validation_output"
  echo
  echo "validated_nested_artifacts:"
  printf '  - %s\n' \
    "$release_readiness_root/README.md" \
    "$release_readiness_root/manifest.json" \
    "$release_readiness_root/release-readiness-report-validation.txt" \
    "$release_readiness_root/proof-sha256-validation.txt" \
    "$history_root/README.md" \
    "$history_root/manifest.json" \
    "$history_root/history-report-validation.txt" \
    "$history_root/proof-sha256-validation.txt"
} >"$artifact_audit"

{
  echo "AIReady sustained readiness summary validated"
  echo "audit_root: $output_root"
  echo "history_window: $history_count"
  echo "history_reports_checked: $history_reports_checked"
  echo "history_reports_passed: $history_reports_passed"
  echo "history_reports_failed: $history_reports_failed"
} >"$summary_validation_output"

"$sustained_validator" --preproof "$output_root" >"$report_validation_tmp"
mv "$report_validation_tmp" "$report_validation_output"

{
  echo "# AIReady Sustained Readiness Proof Checksums"
  echo
  echo "audit_root: $output_root"
  echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  sha256sum \
    "$summary_readme" \
    "$summary_manifest" \
    "$release_readiness_output" \
    "$history_output" \
    "$artifact_audit" \
    "$summary_validation_output" \
    "$report_validation_output"
} >"$checksums_output"

{
  echo "AIReady sustained readiness proof checksum validation"
  echo "audit_root: $output_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$checksums_output" | sha256sum -c
} | tee "$checksums_validation_output"

"$sustained_validator" "$output_root" >"$report_validation_tmp"
mv "$report_validation_tmp" "$report_validation_output"

for path in \
  "$summary_readme" \
  "$summary_manifest" \
  "$release_readiness_output" \
  "$history_output" \
  "$artifact_audit" \
  "$checksums_output" \
  "$checksums_validation_output" \
  "$summary_validation_output" \
  "$report_validation_output"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty sustained-readiness artifact: $path" >&2
    exit 1
  fi
done

echo "AIReady sustained readiness check completed"
echo "audit_root: $output_root"
echo "history_window: $history_count"
echo "history_reports_checked: $history_reports_checked"
echo "history_reports_passed: $history_reports_passed"
echo "history_reports_failed: $history_reports_failed"
