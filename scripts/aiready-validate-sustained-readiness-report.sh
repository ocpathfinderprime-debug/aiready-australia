#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-sustained-readiness-report.sh [--preproof] /path/to/sustained-readiness-root

Validates that an AIReady sustained-readiness root captures both the fresh
release-readiness pass and the recent release-readiness history window, plus
the expected top-level proof packet for the combined audit.
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
release_readiness_output="$report_root/release-readiness-output.txt"
history_output="$report_root/history-output.txt"
summary_validation="$report_root/sustained-readiness-validation.txt"
report_validation="$report_root/sustained-readiness-report-validation.txt"
release_readiness_root="$report_root/release-readiness"
history_root="$report_root/history"

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
  "$release_readiness_output" \
  "$history_output" \
  "$summary_validation" \
  "$release_readiness_root/README.md" \
  "$release_readiness_root/manifest.json" \
  "$release_readiness_root/release-readiness-report-validation.txt" \
  "$release_readiness_root/proof-sha256-validation.txt" \
  "$history_root/README.md" \
  "$history_root/manifest.json" \
  "$history_root/history-report-validation.txt" \
  "$history_root/proof-sha256-validation.txt"; do
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
history_reports_checked="$(jq -r '.history_reports_checked' "$summary_manifest")"
history_reports_passed="$(jq -r '.history_reports_passed' "$summary_manifest")"
history_reports_failed="$(jq -r '.history_reports_failed' "$summary_manifest")"

required_readme_strings=(
  "# AIReady Sustained Readiness Check"
  "- Audit root: \`$report_root\`"
  "- Requested history window: \`$requested_history_window\`"
  "- History reports checked: \`$history_reports_checked\`"
  "- History reports passed: \`$history_reports_passed\`"
  "- History reports failed: \`$history_reports_failed\`"
  "## Fresh release-readiness pass"
  "- Fresh release-readiness root: [release-readiness/](./release-readiness/)"
  "- Fresh release-readiness summary: [release-readiness/README.md](./release-readiness/README.md)"
  "- Fresh release-readiness manifest: [release-readiness/manifest.json](./release-readiness/manifest.json)"
  "- Fresh release-readiness command output: [release-readiness-output.txt](./release-readiness-output.txt)"
  "## Recent stability window"
  "- History audit root: [history/](./history/)"
  "- History audit summary: [history/README.md](./history/README.md)"
  "- History audit manifest: [history/manifest.json](./history/manifest.json)"
  "- History audit command output: [history-output.txt](./history-output.txt)"
  "## Aggregate evidence"
  "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "- Sustained-readiness validation: [sustained-readiness-validation.txt](./sustained-readiness-validation.txt)"
  "1. the latest local AIReady release-readiness gate passed end to end"
  "2. the latest \`"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"audit_root\": \"$report_root\""
  '"requested_history_window":'
  '"history_reports_checked":'
  '"history_reports_passed":'
  '"history_reports_failed":'
  "\"fresh_release_readiness_root\": \"$release_readiness_root\""
  "\"fresh_release_readiness_summary\": \"$release_readiness_root/README.md\""
  "\"fresh_release_readiness_manifest\": \"$release_readiness_root/manifest.json\""
  "\"fresh_release_readiness_output\": \"$release_readiness_output\""
  "\"history_audit_root\": \"$history_root\""
  "\"history_audit_summary\": \"$history_root/README.md\""
  "\"history_audit_manifest\": \"$history_root/manifest.json\""
  "\"history_audit_output\": \"$history_output\""
  "\"artifact_audit\": \"$artifact_audit\""
  "\"proof_checksums\": \"$proof_checksums\""
  "\"proof_checksum_validation\": \"$proof_checksums_validation\""
  "\"summary_validation\": \"$summary_validation\""
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

for value_name in \
  requested_history_window \
  history_reports_checked \
  history_reports_passed \
  history_reports_failed; do
  value="${!value_name}"
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "Non-numeric manifest value: $value_name=$value" >&2
    exit 1
  fi
done

if [[ "$history_reports_checked" != "$requested_history_window" ]]; then
  echo "history_reports_checked does not match requested_history_window: $history_reports_checked vs $requested_history_window" >&2
  exit 1
fi

if [[ "$history_reports_failed" != "0" ]]; then
  echo "history_reports_failed must be zero, found: $history_reports_failed" >&2
  exit 1
fi

required_artifact_audit_strings=(
  "AIReady sustained readiness artifact audit"
  "audit_root: $report_root"
  "$summary_readme"
  "$summary_manifest"
  "$release_readiness_output"
  "$history_output"
  "$artifact_audit"
  "$proof_checksums"
  "$proof_checksums_validation"
  "$summary_validation"
  "$release_readiness_root/README.md"
  "$release_readiness_root/manifest.json"
  "$release_readiness_root/release-readiness-report-validation.txt"
  "$release_readiness_root/proof-sha256-validation.txt"
  "$history_root/README.md"
  "$history_root/manifest.json"
  "$history_root/history-report-validation.txt"
  "$history_root/proof-sha256-validation.txt"
)

for expected in "${required_artifact_audit_strings[@]}"; do
  require_literal "$expected" "$artifact_audit"
done

if [[ "$preproof_mode" != "true" ]]; then
  required_proof_checksum_strings=(
    "# AIReady Sustained Readiness Proof Checksums"
    "audit_root: $report_root"
    "  $summary_readme"
    "  $summary_manifest"
    "  $release_readiness_output"
    "  $history_output"
    "  $artifact_audit"
    "  $summary_validation"
    "  $report_validation"
  )

  for expected in "${required_proof_checksum_strings[@]}"; do
    require_literal "$expected" "$proof_checksums"
  done

  required_proof_checksum_validation_strings=(
    "AIReady sustained readiness proof checksum validation"
    "audit_root: $report_root"
    "$summary_readme: OK"
    "$summary_manifest: OK"
    "$release_readiness_output: OK"
    "$history_output: OK"
    "$artifact_audit: OK"
    "$summary_validation: OK"
    "$report_validation: OK"
  )

  for expected in "${required_proof_checksum_validation_strings[@]}"; do
    require_literal "$expected" "$proof_checksums_validation"
  done
fi

required_release_readiness_output_strings=(
  "AIReady release readiness check completed"
  "report_root: $release_readiness_root"
)

for expected in "${required_release_readiness_output_strings[@]}"; do
  require_literal "$expected" "$release_readiness_output"
done

required_history_output_strings=(
  "AIReady release-readiness history audit completed"
  "audit_root: $history_root"
  "reports_failed: 0"
)

for expected in "${required_history_output_strings[@]}"; do
  require_literal "$expected" "$history_output"
done

echo "AIReady sustained readiness report validated"
echo "report_root: $report_root"
echo
echo "validated_top_level_files:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$artifact_audit" \
  "$proof_checksums" \
  "$proof_checksums_validation" \
  "$release_readiness_output" \
  "$history_output" \
  "$summary_validation" \
  "$report_validation"
echo
echo "validated_nested_roots:"
printf '  - %s\n' \
  "$release_readiness_root" \
  "$history_root"
