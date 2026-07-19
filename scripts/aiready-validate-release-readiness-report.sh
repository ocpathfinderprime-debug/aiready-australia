#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-release-readiness-report.sh [--preproof] /path/to/release-readiness-report-root

Validates that an AIReady release-readiness report root contains the expected
top-level proof packet, references the expected gates and tier surfaces, and
captures the artifact-audit lane used by the release-readiness check.
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
direct_invocation_output="$report_root/direct-invocation.txt"
doc_asset_output="$report_root/doc-asset-links.txt"
fail_closed_output="$report_root/fail-closed.txt"
tier_matrix_output="$report_root/tier-matrix.txt"
tier_matrix_report_validation="$report_root/tier-matrix/tier-matrix-report-validation.txt"
fail_closed_report_validation="$report_root/fail-closed/fail-closed-report-validation.txt"
report_root_validation_output="$report_root/release-readiness-report-validation.txt"

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

require_nonempty_file "$summary_readme"
require_nonempty_file "$summary_manifest"
require_nonempty_file "$artifact_audit"
require_nonempty_file "$direct_invocation_output"
require_nonempty_file "$doc_asset_output"
require_nonempty_file "$fail_closed_output"
require_nonempty_file "$tier_matrix_output"
require_nonempty_file "$tier_matrix_report_validation"
require_nonempty_file "$fail_closed_report_validation"

if [[ "$preproof_mode" != "true" ]]; then
  require_nonempty_file "$proof_checksums"
  require_nonempty_file "$proof_checksums_validation"
  require_nonempty_file "$report_root_validation_output"
fi

required_readme_strings=(
  "# AIReady Release Readiness Check"
  "- Report root: \`$report_root\`"
  "- Requested history window: \`$(jq -r '.requested_history_window' "$summary_manifest")\`"
  "## Validated gates"
  "Direct invocation: [direct-invocation.txt](./direct-invocation.txt)"
  "Doc asset links: [doc-asset-links.txt](./doc-asset-links.txt)"
  "Fail-closed smoke: [fail-closed.txt](./fail-closed.txt)"
  "Fail-closed validation: [fail-closed/fail-closed-report-validation.txt](./fail-closed/fail-closed-report-validation.txt)"
  "Tier matrix smoke: [tier-matrix.txt](./tier-matrix.txt)"
  "Tier-matrix report validation: [tier-matrix/tier-matrix-report-validation.txt](./tier-matrix/tier-matrix-report-validation.txt)"
  "Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "Report-root validation: [release-readiness-report-validation.txt](./release-readiness-report-validation.txt)"
  "Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "Starter dry run: [tier-matrix/starter/](./tier-matrix/starter/)"
  "Business dry run: [tier-matrix/business/](./tier-matrix/business/)"
  "Enterprise dry run: [tier-matrix/enterprise/](./tier-matrix/enterprise/)"
)

for expected in "${required_readme_strings[@]}"; do
  require_literal "$expected" "$summary_readme"
done

required_manifest_strings=(
  "\"report_root\": \"$report_root\""
  '"requested_history_window":'
  '"name": "direct invocation"'
  "\"output_file\": \"$direct_invocation_output\""
  '"name": "doc asset links"'
  "\"output_file\": \"$doc_asset_output\""
  '"name": "fail-closed smoke"'
  "\"output_file\": \"$fail_closed_output\""
  "\"report_validation_output\": \"$fail_closed_report_validation\""
  '"name": "tier matrix smoke"'
  "\"output_file\": \"$tier_matrix_output\""
  "\"report_validation_output\": \"$tier_matrix_report_validation\""
  '"name": "artifact audit"'
  "\"output_file\": \"$artifact_audit\""
  "\"$direct_invocation_output\""
  "\"$doc_asset_output\""
  "\"$fail_closed_output\""
  "\"$tier_matrix_output\""
  "\"$report_root_validation_output\""
  "\"$proof_checksums\""
  "\"$proof_checksums_validation\""
  "\"$fail_closed_report_validation\""
  '"name": "proof checksums"'
  "\"output_file\": \"$proof_checksums\""
  '"name": "proof checksum validation"'
  "\"output_file\": \"$proof_checksums_validation\""
  '"name": "report-root validation"'
  "\"output_file\": \"$report_root_validation_output\""
  '"tier": "Starter"'
  '"tier": "Business"'
  '"tier": "Enterprise"'
)

for expected in "${required_manifest_strings[@]}"; do
  require_literal "$expected" "$summary_manifest"
done

required_artifact_audit_strings=(
  "AIReady release readiness artifact audit"
  "report_root: $report_root"
  "$report_root_validation_output"
  "$proof_checksums"
  "$proof_checksums_validation"
  "$fail_closed_report_validation"
  "$report_root/fail-closed/README.md"
  "$report_root/fail-closed/manifest.json"
  "$report_root/tier-matrix/README.md"
  "$report_root/tier-matrix/manifest.json"
  "$tier_matrix_report_validation"
  "$report_root/tier-matrix/starter/README.md"
  "$report_root/tier-matrix/starter/manifest.json"
  "$report_root/tier-matrix/starter/full-dry-run-report-validation.txt"
  "$report_root/tier-matrix/starter/preflight/preflight-report-validation.txt"
  "$report_root/tier-matrix/business/README.md"
  "$report_root/tier-matrix/business/manifest.json"
  "$report_root/tier-matrix/business/full-dry-run-report-validation.txt"
  "$report_root/tier-matrix/business/preflight/preflight-report-validation.txt"
  "$report_root/tier-matrix/enterprise/README.md"
  "$report_root/tier-matrix/enterprise/manifest.json"
  "$report_root/tier-matrix/enterprise/full-dry-run-report-validation.txt"
  "$report_root/tier-matrix/enterprise/preflight/preflight-report-validation.txt"
)

for expected in "${required_artifact_audit_strings[@]}"; do
  require_literal "$expected" "$artifact_audit"
done

required_proof_checksum_strings=(
  "# AIReady Release Readiness Proof Checksums"
  "report_root: $report_root"
  "  $summary_readme"
  "  $summary_manifest"
  "  $artifact_audit"
  "  $direct_invocation_output"
  "  $doc_asset_output"
  "  $fail_closed_output"
  "  $fail_closed_report_validation"
  "  $tier_matrix_output"
  "  $tier_matrix_report_validation"
  "  $report_root_validation_output"
)

if [[ "$preproof_mode" != "true" ]]; then
  for expected in "${required_proof_checksum_strings[@]}"; do
    require_literal "$expected" "$proof_checksums"
  done

  required_proof_checksum_validation_strings=(
    "AIReady release-readiness proof checksum validation"
    "report_root: $report_root"
    "$summary_readme: OK"
    "$summary_manifest: OK"
    "$artifact_audit: OK"
    "$direct_invocation_output: OK"
    "$doc_asset_output: OK"
    "$fail_closed_output: OK"
    "$fail_closed_report_validation: OK"
    "$tier_matrix_output: OK"
    "$tier_matrix_report_validation: OK"
    "$report_root_validation_output: OK"
  )

  for expected in "${required_proof_checksum_validation_strings[@]}"; do
    require_literal "$expected" "$proof_checksums_validation"
  done
fi

echo "AIReady release-readiness report validated"
echo "report_root: $report_root"
echo
echo "validated_top_level_files:"
printf '  - %s\n' \
  "$summary_readme" \
  "$summary_manifest" \
  "$artifact_audit" \
  "$proof_checksums" \
  "$proof_checksums_validation" \
  "$report_root_validation_output" \
  "$fail_closed_report_validation" \
  "$direct_invocation_output" \
  "$doc_asset_output" \
  "$fail_closed_output" \
  "$tier_matrix_output"
echo
echo "validated_tiers:"
printf '  - %s\n' \
  "Starter" \
  "Business" \
  "Enterprise"
