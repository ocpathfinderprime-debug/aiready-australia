#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-sustained-readiness-proof.sh /path/to/sustained-readiness-root [...]

Rebuild missing or stale top-level proof artifacts for one or more existing
AIReady sustained-readiness report roots without changing the nested evidence.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$workspace_root/scripts/aiready-validate-sustained-readiness-report.sh"

if [[ ! -f "$validator" ]]; then
  echo "Missing validator: $validator" >&2
  exit 1
fi

for report_root in "$@"; do
  if [[ ! -d "$report_root" ]]; then
    echo "Report root not found: $report_root" >&2
    exit 1
  fi

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
  report_validation_tmp="$report_root/.sustained-readiness-report-validation.tmp"

  for path in \
    "$summary_readme" \
    "$summary_manifest" \
    "$release_readiness_output" \
    "$history_output" \
    "$release_readiness_root/README.md" \
    "$release_readiness_root/manifest.json" \
    "$release_readiness_root/release-readiness-report-validation.txt" \
    "$release_readiness_root/proof-sha256-validation.txt" \
    "$history_root/README.md" \
    "$history_root/manifest.json" \
    "$history_root/history-report-validation.txt" \
    "$history_root/proof-sha256-validation.txt"; do
    if [[ ! -s "$path" ]]; then
      echo "Missing or empty prerequisite artifact: $path" >&2
      exit 1
    fi
  done

  requested_history_window="$(jq -r '.requested_history_window // .history_window // empty' "$summary_manifest")"
  if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
    requested_history_window="$(jq -r '.requested_history_window // empty' "$history_root/manifest.json")"
  fi
  if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
    requested_history_window="$(jq -r '.reports_checked // empty' "$history_root/manifest.json")"
  fi
  if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
    echo "Could not determine requested_history_window for $report_root" >&2
    exit 1
  fi

  history_reports_checked="$(jq -r '.reports_checked' "$history_root/manifest.json")"
  history_reports_passed="$(jq -r '.reports_passed' "$history_root/manifest.json")"
  history_reports_failed="$(jq -r '.reports_failed' "$history_root/manifest.json")"

  {
    echo "# AIReady Sustained Readiness Check"
    echo
    echo "- Audit root: \`$report_root\`"
    echo "- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`"
    echo "- Requested history window: \`$requested_history_window\`"
    echo "- History reports checked: \`$history_reports_checked\`"
    echo "- History reports passed: \`$history_reports_passed\`"
    echo "- History reports failed: \`$history_reports_failed\`"
    echo
    echo "## Fresh release-readiness pass"
    echo
    echo "- Fresh release-readiness root: [release-readiness/](./release-readiness/)"
    echo "- Fresh release-readiness summary: [release-readiness/README.md](./release-readiness/README.md)"
    echo "- Fresh release-readiness manifest: [release-readiness/manifest.json](./release-readiness/manifest.json)"
    echo "- Fresh release-readiness command output: [release-readiness-output.txt](./release-readiness-output.txt)"
    echo
    echo "## Recent stability window"
    echo
    echo "- History audit root: [history/](./history/)"
    echo "- History audit summary: [history/README.md](./history/README.md)"
    echo "- History audit manifest: [history/manifest.json](./history/manifest.json)"
    echo "- History audit command output: [history-output.txt](./history-output.txt)"
    echo
    echo "## Aggregate evidence"
    echo
    echo "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
    echo "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
    echo "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
    echo "- Sustained-readiness validation: [sustained-readiness-validation.txt](./sustained-readiness-validation.txt)"
    echo
    echo "## Outcome"
    echo
    echo "This disposable root proves both:"
    echo
    echo "1. the latest local AIReady release-readiness gate passed end to end"
    echo "2. the latest \`$requested_history_window\` release-readiness roots validate cleanly as a stability window"
  } >"$summary_readme"

  {
    printf '{\n'
    printf '  "audit_root": "%s",\n' "$report_root"
    printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '  "requested_history_window": %s,\n' "$requested_history_window"
    printf '  "fresh_release_readiness_root": "%s",\n' "$release_readiness_root"
    printf '  "fresh_release_readiness_summary": "%s",\n' "$release_readiness_root/README.md"
    printf '  "fresh_release_readiness_manifest": "%s",\n' "$release_readiness_root/manifest.json"
    printf '  "fresh_release_readiness_output": "%s",\n' "$release_readiness_output"
    printf '  "history_audit_root": "%s",\n' "$history_root"
    printf '  "history_audit_summary": "%s",\n' "$history_root/README.md"
    printf '  "history_audit_manifest": "%s",\n' "$history_root/manifest.json"
    printf '  "history_audit_output": "%s",\n' "$history_output"
    printf '  "history_reports_checked": %s,\n' "$history_reports_checked"
    printf '  "history_reports_passed": %s,\n' "$history_reports_passed"
    printf '  "history_reports_failed": %s,\n' "$history_reports_failed"
    printf '  "artifact_audit": "%s",\n' "$artifact_audit"
    printf '  "proof_checksums": "%s",\n' "$proof_checksums"
    printf '  "proof_checksum_validation": "%s",\n' "$proof_checksums_validation"
    printf '  "summary_validation": "%s",\n' "$summary_validation"
    printf '  "report_validation": "%s"\n' "$report_validation"
    printf '}\n'
  } >"$summary_manifest"

  {
    echo "AIReady sustained readiness summary validated"
    echo "audit_root: $report_root"
    echo "history_window: $requested_history_window"
    echo "history_reports_checked: $history_reports_checked"
    echo "history_reports_passed: $history_reports_passed"
    echo "history_reports_failed: $history_reports_failed"
  } >"$summary_validation"

  {
    echo "AIReady sustained readiness artifact audit"
    echo "audit_root: $report_root"
    echo
    echo "validated_artifacts:"
    printf '  - %s\n' \
      "$summary_readme" \
      "$summary_manifest" \
      "$release_readiness_output" \
      "$history_output" \
      "$artifact_audit" \
      "$proof_checksums" \
      "$proof_checksums_validation" \
      "$summary_validation" \
      "$report_validation"
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

  "$validator" --preproof "$report_root" >"$report_validation_tmp"
  mv "$report_validation_tmp" "$report_validation"

  {
    echo "# AIReady Sustained Readiness Proof Checksums"
    echo
    echo "audit_root: $report_root"
    echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
    sha256sum \
      "$summary_readme" \
      "$summary_manifest" \
      "$release_readiness_output" \
      "$history_output" \
      "$artifact_audit" \
      "$summary_validation" \
      "$report_validation"
  } >"$proof_checksums"

  {
    echo "AIReady sustained readiness proof checksum validation"
    echo "audit_root: $report_root"
    echo
    grep -E '^[0-9a-f]{64}  .+' "$proof_checksums" | sha256sum -c
  } | tee "$proof_checksums_validation"

  "$validator" "$report_root" >"$report_validation_tmp"
  mv "$report_validation_tmp" "$report_validation"

  for path in \
    "$artifact_audit" \
    "$proof_checksums" \
    "$proof_checksums_validation" \
    "$report_validation"; do
    if [[ ! -s "$path" ]]; then
      echo "Failed to rebuild proof artifact: $path" >&2
      exit 1
    fi
  done

  echo "Normalized sustained-readiness proof"
  echo "report_root: $report_root"
  echo "proof_checksums: $proof_checksums"
  echo "proof_checksum_validation: $proof_checksums_validation"
  echo "report_validation: $report_validation"
done
