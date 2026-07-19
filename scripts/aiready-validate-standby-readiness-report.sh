#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-standby-readiness-report.sh [--preproof] /path/to/standby-readiness-root

Validate that an AIReady standby-readiness root captures the sustained lane,
both trend lanes, and the expected top-level proof packet for the combined
standby gate.
EOF
}

preproof_mode="false"

if [[ $# -eq 2 && "$1" == "--preproof" ]]; then
  preproof_mode="true"
  shift
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
artifact_audit="$report_root/artifact-audit.txt"
proof_checksums="$report_root/proof-sha256.txt"
proof_checksums_validation="$report_root/proof-sha256-validation.txt"
sustained_output="$report_root/sustained-readiness-output.txt"
release_trend_output="$report_root/release-history-trend-output.txt"
sustained_trend_output="$report_root/sustained-history-trend-output.txt"
summary_validation="$report_root/standby-readiness-validation.txt"
report_validation="$report_root/standby-readiness-report-validation.txt"
sustained_root="$report_root/sustained-readiness"
release_trend_root="$report_root/release-history-trend"
sustained_trend_root="$report_root/sustained-history-trend"

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

if [[ ! -d "$report_root" ]]; then
  echo "Report root not found: $report_root" >&2
  exit 1
fi

for path in \
  "$summary_readme" \
  "$summary_manifest" \
  "$artifact_audit" \
  "$sustained_output" \
  "$release_trend_output" \
  "$sustained_trend_output" \
  "$summary_validation" \
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
  "$sustained_trend_root/proof-sha256-validation.txt"; do
  require_nonempty_file "$path"
done

if [[ "$preproof_mode" != "true" ]]; then
  for path in \
    "$proof_checksums" \
    "$proof_checksums_validation" \
    "$report_validation"; do
    require_nonempty_file "$path"
  done
fi

requested_history_window="$(jq -r '.requested_history_window' "$summary_manifest")"
release_history_trend_failed="$(jq -r '.release_history_trend_failed' "$summary_manifest")"
release_history_trend_comparable_failed="$(jq -r '.release_history_trend_comparable_failed' "$summary_manifest")"
release_history_trend_legacy_window_mismatches="$(jq -r '.release_history_trend_legacy_window_mismatches' "$summary_manifest")"
sustained_history_trend_failed="$(jq -r '.sustained_history_trend_failed' "$summary_manifest")"
sustained_history_trend_comparable_failed="$(jq -r '.sustained_history_trend_comparable_failed' "$summary_manifest")"
sustained_history_trend_requested_window_mismatches="$(jq -r '.sustained_history_trend_requested_window_mismatches' "$summary_manifest")"

required_readme_strings=(
  "# AIReady Standby Readiness Check"
  "- Audit root: \`$report_root\`"
  "- Requested history window: \`$requested_history_window\`"
  "- Release-history trend failures: \`$release_history_trend_failed\`"
  "- Release-history comparable failures: \`$release_history_trend_comparable_failed\`"
  "- Release-history legacy-window mismatches: \`$release_history_trend_legacy_window_mismatches\`"
  "- Sustained-history trend failures: \`$sustained_history_trend_failed\`"
  "- Sustained-history comparable failures: \`$sustained_history_trend_comparable_failed\`"
  "- Sustained-history requested-window mismatches: \`$sustained_history_trend_requested_window_mismatches\`"
  "## Current readiness lane"
  "- Sustained-readiness root: [sustained-readiness/](./sustained-readiness/)"
  "- Sustained-readiness summary: [sustained-readiness/README.md](./sustained-readiness/README.md)"
  "- Sustained-readiness manifest: [sustained-readiness/manifest.json](./sustained-readiness/manifest.json)"
  "- Sustained-readiness command output: [sustained-readiness-output.txt](./sustained-readiness-output.txt)"
  "## Trend lanes"
  "- Release-history trend root: [release-history-trend/](./release-history-trend/)"
  "- Release-history trend summary: [release-history-trend/README.md](./release-history-trend/README.md)"
  "- Release-history trend manifest: [release-history-trend/manifest.json](./release-history-trend/manifest.json)"
  "- Release-history trend command output: [release-history-trend-output.txt](./release-history-trend-output.txt)"
  "- Sustained-history trend root: [sustained-history-trend/](./sustained-history-trend/)"
  "- Sustained-history trend summary: [sustained-history-trend/README.md](./sustained-history-trend/README.md)"
  "- Sustained-history trend manifest: [sustained-history-trend/manifest.json](./sustained-history-trend/manifest.json)"
  "- Sustained-history trend command output: [sustained-history-trend-output.txt](./sustained-history-trend-output.txt)"
  "## Aggregate evidence"
  "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "- Standby-readiness validation: [standby-readiness-validation.txt](./standby-readiness-validation.txt)"
  "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "- Report validation: [standby-readiness-report-validation.txt](./standby-readiness-report-validation.txt)"
  "1. one fresh sustained-readiness pass"
  "2. a clean release-readiness history-trend packet"
  "3. a clean sustained-readiness history-trend packet"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"audit_root\": \"$report_root\""
  '"requested_history_window":'
  "\"sustained_readiness_root\": \"$sustained_root\""
  "\"sustained_readiness_summary\": \"$sustained_root/README.md\""
  "\"sustained_readiness_manifest\": \"$sustained_root/manifest.json\""
  "\"sustained_readiness_output\": \"$sustained_output\""
  "\"release_history_trend_root\": \"$release_trend_root\""
  "\"release_history_trend_summary\": \"$release_trend_root/README.md\""
  "\"release_history_trend_manifest\": \"$release_trend_root/manifest.json\""
  "\"release_history_trend_output\": \"$release_trend_output\""
  '"release_history_trend_comparable_failed":'
  '"release_history_trend_legacy_window_mismatches":'
  "\"sustained_history_trend_root\": \"$sustained_trend_root\""
  "\"sustained_history_trend_summary\": \"$sustained_trend_root/README.md\""
  "\"sustained_history_trend_manifest\": \"$sustained_trend_root/manifest.json\""
  "\"sustained_history_trend_output\": \"$sustained_trend_output\""
  '"sustained_history_trend_comparable_failed":'
  '"sustained_history_trend_requested_window_mismatches":'
  "\"artifact_audit\": \"$artifact_audit\""
  "\"summary_validation\": \"$summary_validation\""
  "\"proof_checksums\": \"$proof_checksums\""
  "\"proof_checksum_validation\": \"$proof_checksums_validation\""
  "\"report_validation\": \"$report_validation\""
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

for value_name in \
  requested_history_window \
  release_history_trend_failed \
  release_history_trend_comparable_failed \
  release_history_trend_legacy_window_mismatches \
  sustained_history_trend_failed \
  sustained_history_trend_comparable_failed \
  sustained_history_trend_requested_window_mismatches; do
  value="${!value_name}"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "Non-numeric manifest value: $value_name=$value" >&2
    exit 1
  fi
done

for zero_value_name in \
  release_history_trend_failed \
  release_history_trend_comparable_failed \
  release_history_trend_legacy_window_mismatches \
  sustained_history_trend_failed \
  sustained_history_trend_comparable_failed \
  sustained_history_trend_requested_window_mismatches; do
  value="${!zero_value_name}"
  if [[ "$value" != "0" ]]; then
    echo "Standby readiness manifest must report zero for $zero_value_name, found: $value" >&2
    exit 1
  fi
done

required_artifact_audit_strings=(
  "AIReady standby readiness artifact audit"
  "audit_root: $report_root"
  "$summary_readme"
  "$summary_manifest"
  "$sustained_output"
  "$release_trend_output"
  "$sustained_trend_output"
  "$artifact_audit"
  "$summary_validation"
  "$proof_checksums"
  "$proof_checksums_validation"
  "$report_validation"
  "$sustained_root/README.md"
  "$sustained_root/manifest.json"
  "$sustained_root/sustained-readiness-report-validation.txt"
  "$sustained_root/proof-sha256-validation.txt"
  "$release_trend_root/README.md"
  "$release_trend_root/manifest.json"
  "$release_trend_root/history-trend-report-validation.txt"
  "$release_trend_root/proof-sha256-validation.txt"
  "$sustained_trend_root/README.md"
  "$sustained_trend_root/manifest.json"
  "$sustained_trend_root/history-trend-report-validation.txt"
  "$sustained_trend_root/proof-sha256-validation.txt"
)

for expected in "${required_artifact_audit_strings[@]}"; do
  require_literal "$expected" "$artifact_audit"
done

if [[ "$preproof_mode" != "true" ]]; then
  required_proof_checksum_strings=(
    "# AIReady Standby Readiness Proof Checksums"
    "audit_root: $report_root"
    "  $summary_readme"
    "  $summary_manifest"
    "  $sustained_output"
    "  $release_trend_output"
    "  $sustained_trend_output"
    "  $artifact_audit"
    "  $summary_validation"
    "  $report_validation"
  )

  for expected in "${required_proof_checksum_strings[@]}"; do
    require_literal "$expected" "$proof_checksums"
  done

  required_proof_checksum_validation_strings=(
    "AIReady standby readiness proof checksum validation"
    "audit_root: $report_root"
    "$summary_readme: OK"
    "$summary_manifest: OK"
    "$sustained_output: OK"
    "$release_trend_output: OK"
    "$sustained_trend_output: OK"
    "$artifact_audit: OK"
    "$summary_validation: OK"
    "$report_validation: OK"
  )

  for expected in "${required_proof_checksum_validation_strings[@]}"; do
    require_literal "$expected" "$proof_checksums_validation"
  done
fi

required_sustained_output_strings=(
  "AIReady sustained readiness check completed"
  "audit_root: $sustained_root"
  "history_reports_failed: 0"
)

for expected in "${required_sustained_output_strings[@]}"; do
  require_literal "$expected" "$sustained_output"
done

required_release_trend_output_strings=(
  "AIReady release-readiness history trend audit completed"
  "audit_root: $release_trend_root"
  "comparable_history_audits_failed: 0"
)

for expected in "${required_release_trend_output_strings[@]}"; do
  require_literal "$expected" "$release_trend_output"
done

required_sustained_trend_output_strings=(
  "AIReady sustained-readiness history trend audit completed"
  "audit_root: $sustained_trend_root"
  "comparable_history_audits_failed: 0"
)

for expected in "${required_sustained_trend_output_strings[@]}"; do
  require_literal "$expected" "$sustained_trend_output"
done

echo "AIReady standby readiness report validated"
echo "report_root: $report_root"
echo
echo "validated_top_level_files:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$artifact_audit" \
  "$proof_checksums" \
  "$proof_checksums_validation" \
  "$sustained_output" \
  "$release_trend_output" \
  "$sustained_trend_output" \
  "$summary_validation" \
  "$report_validation"
echo
echo "validated_nested_roots:"
printf '  - %s\n' \
  "$sustained_root" \
  "$release_trend_root" \
  "$sustained_trend_root"
