#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-release-readiness-check.sh [report_root] [requested_history_window]

Runs the top-level local readiness gates for AIReady:
1. doc-to-script drift check
2. fail-closed smoke on blocking bad inputs
3. tier-matrix smoke across Starter, Business, and Enterprise

This produces one disposable evidence root for a human release-readiness check.

Defaults:
  report_root               -> reports/aiready-release-readiness-<timestamp>
  requested_history_window  -> 5
EOF
}

if [[ $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_root="${1:-$workspace_root/reports/aiready-release-readiness-$(date +%Y-%m-%d-%H%M-AWST)}"
requested_history_window="${2:-5}"
direct_invocation_validator="$workspace_root/scripts/aiready-validate-direct-invocation.sh"
doc_asset_validator="$workspace_root/scripts/aiready-validate-doc-asset-links.sh"
fail_closed_script="$workspace_root/scripts/aiready-fail-closed-smoke.sh"
tier_matrix_script="$workspace_root/scripts/aiready-tier-matrix-smoke.sh"
report_root_validator="$workspace_root/scripts/aiready-validate-release-readiness-report.sh"

if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
  echo "Requested history window must be a positive integer: $requested_history_window" >&2
  exit 1
fi

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

require_file "$direct_invocation_validator"
require_file "$doc_asset_validator"
require_file "$fail_closed_script"
require_file "$tier_matrix_script"
require_file "$report_root_validator"

if [[ -e "$report_root" ]]; then
  echo "Report root already exists: $report_root" >&2
  exit 1
fi

mkdir -p "$report_root"

direct_invocation_output="$report_root/direct-invocation.txt"
doc_asset_output="$report_root/doc-asset-links.txt"
fail_closed_root="$report_root/fail-closed"
tier_matrix_root="$report_root/tier-matrix"
fail_closed_output="$report_root/fail-closed.txt"
tier_matrix_output="$report_root/tier-matrix.txt"
artifact_audit_output="$report_root/artifact-audit.txt"
report_root_validation_output="$report_root/release-readiness-report-validation.txt"
proof_checksums_output="$report_root/proof-sha256.txt"
proof_checksums_validation_output="$report_root/proof-sha256-validation.txt"
summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
tier_matrix_report_validation_output="$tier_matrix_root/tier-matrix-report-validation.txt"
fail_closed_report_validation_output="$fail_closed_root/fail-closed-report-validation.txt"

"$direct_invocation_validator" | tee "$direct_invocation_output"
"$doc_asset_validator" | tee "$doc_asset_output"
"$fail_closed_script" "$fail_closed_root" | tee "$fail_closed_output"
"$tier_matrix_script" "$tier_matrix_root" | tee "$tier_matrix_output"

required_artifacts=(
  "$direct_invocation_output"
  "$doc_asset_output"
  "$fail_closed_output"
  "$tier_matrix_output"
  "$report_root_validation_output"
  "$proof_checksums_output"
  "$proof_checksums_validation_output"
  "$fail_closed_report_validation_output"
  "$fail_closed_root/README.md"
  "$fail_closed_root/manifest.json"
  "$tier_matrix_root/README.md"
  "$tier_matrix_root/manifest.json"
  "$tier_matrix_report_validation_output"
  "$tier_matrix_root/starter/README.md"
  "$tier_matrix_root/starter/manifest.json"
  "$tier_matrix_root/starter/full-dry-run-report-validation.txt"
  "$tier_matrix_root/starter/preflight/README.md"
  "$tier_matrix_root/starter/preflight/manifest.json"
  "$tier_matrix_root/starter/preflight/preflight-report-validation.txt"
  "$tier_matrix_root/starter/preflight-output.txt"
  "$tier_matrix_root/starter/report-draft-validation.txt"
  "$tier_matrix_root/starter/intake-activation-record-validation.txt"
  "$tier_matrix_root/starter/research-dispatch-validation.txt"
  "$tier_matrix_root/starter/evidence-capture-validation.txt"
  "$tier_matrix_root/starter/scoring-pack-validation.txt"
  "$tier_matrix_root/starter/delivery-email-validation.txt"
  "$tier_matrix_root/starter/delivery-package-validation.txt"
  "$tier_matrix_root/starter/closeout-record-validation.txt"
  "$tier_matrix_root/business/README.md"
  "$tier_matrix_root/business/manifest.json"
  "$tier_matrix_root/business/full-dry-run-report-validation.txt"
  "$tier_matrix_root/business/preflight/README.md"
  "$tier_matrix_root/business/preflight/manifest.json"
  "$tier_matrix_root/business/preflight/preflight-report-validation.txt"
  "$tier_matrix_root/business/preflight-output.txt"
  "$tier_matrix_root/business/report-draft-validation.txt"
  "$tier_matrix_root/business/intake-activation-record-validation.txt"
  "$tier_matrix_root/business/research-dispatch-validation.txt"
  "$tier_matrix_root/business/evidence-capture-validation.txt"
  "$tier_matrix_root/business/scoring-pack-validation.txt"
  "$tier_matrix_root/business/delivery-email-validation.txt"
  "$tier_matrix_root/business/delivery-package-validation.txt"
  "$tier_matrix_root/business/closeout-record-validation.txt"
  "$tier_matrix_root/enterprise/README.md"
  "$tier_matrix_root/enterprise/manifest.json"
  "$tier_matrix_root/enterprise/full-dry-run-report-validation.txt"
  "$tier_matrix_root/enterprise/preflight/README.md"
  "$tier_matrix_root/enterprise/preflight/manifest.json"
  "$tier_matrix_root/enterprise/preflight/preflight-report-validation.txt"
  "$tier_matrix_root/enterprise/preflight-output.txt"
  "$tier_matrix_root/enterprise/report-draft-validation.txt"
  "$tier_matrix_root/enterprise/intake-activation-record-validation.txt"
  "$tier_matrix_root/enterprise/research-dispatch-validation.txt"
  "$tier_matrix_root/enterprise/evidence-capture-validation.txt"
  "$tier_matrix_root/enterprise/scoring-pack-validation.txt"
  "$tier_matrix_root/enterprise/delivery-email-validation.txt"
  "$tier_matrix_root/enterprise/delivery-package-validation.txt"
  "$tier_matrix_root/enterprise/closeout-record-validation.txt"
)

write_artifact_audit() {
  local strict_report_root_validation="$1"
  local strict_proof_checksums="${2:-false}"

  {
    echo "AIReady release readiness artifact audit"
    echo "report_root: $report_root"
    echo
    echo "validated_artifacts:"
    for path in "${required_artifacts[@]}"; do
      if [[ "$path" == "$report_root_validation_output" && "$strict_report_root_validation" != "true" ]]; then
        printf '  - %s\n' "$path"
        continue
      fi
      if [[ "$path" == "$proof_checksums_output" && "$strict_proof_checksums" != "true" ]]; then
        printf '  - %s\n' "$path"
        continue
      fi
      if [[ "$path" == "$proof_checksums_validation_output" && "$strict_proof_checksums" != "true" ]]; then
        printf '  - %s\n' "$path"
        continue
      fi

      if [[ ! -s "$path" ]]; then
        echo "Missing or empty required artifact: $path" >&2
        exit 1
      fi
      printf '  - %s\n' "$path"
    done
  } | tee "$artifact_audit_output"
}

write_artifact_audit false false

cat >"$summary_readme" <<EOF
# AIReady Release Readiness Check

- Report root: \`$report_root\`
- Generated: \`$(date '+%Y-%m-%d %H:%M:%S %Z')\`
- Requested history window: \`$requested_history_window\`

## Validated gates

- Direct invocation: [direct-invocation.txt](./direct-invocation.txt)
- Doc asset links: [doc-asset-links.txt](./doc-asset-links.txt)
- Fail-closed smoke: [fail-closed.txt](./fail-closed.txt)
- Fail-closed validation: [fail-closed/fail-closed-report-validation.txt](./fail-closed/fail-closed-report-validation.txt)
- Tier matrix smoke: [tier-matrix.txt](./tier-matrix.txt)
- Tier-matrix report validation: [tier-matrix/tier-matrix-report-validation.txt](./tier-matrix/tier-matrix-report-validation.txt)
- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)
- Report-root validation: [release-readiness-report-validation.txt](./release-readiness-report-validation.txt)
- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)
- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)

## Gate roots

- Fail-closed artifacts: [fail-closed/](./fail-closed/)
- Tier matrix artifacts: [tier-matrix/](./tier-matrix/)

## Fail-closed detail

- Fail-closed summary: [fail-closed/README.md](./fail-closed/README.md)
- Fail-closed manifest: [fail-closed/manifest.json](./fail-closed/manifest.json)
- Fail-closed validation: [fail-closed/fail-closed-report-validation.txt](./fail-closed/fail-closed-report-validation.txt)

## Tier matrix detail

- Tier matrix summary: [tier-matrix/README.md](./tier-matrix/README.md)
- Tier matrix manifest: [tier-matrix/manifest.json](./tier-matrix/manifest.json)
- Tier matrix validation: [tier-matrix/tier-matrix-report-validation.txt](./tier-matrix/tier-matrix-report-validation.txt)
- Starter dry run: [tier-matrix/starter/](./tier-matrix/starter/)
- Starter summary: [tier-matrix/starter/README.md](./tier-matrix/starter/README.md)
- Starter manifest: [tier-matrix/starter/manifest.json](./tier-matrix/starter/manifest.json)
- Starter validation: [tier-matrix/starter/full-dry-run-report-validation.txt](./tier-matrix/starter/full-dry-run-report-validation.txt)
- Starter preflight summary: [tier-matrix/starter/preflight/README.md](./tier-matrix/starter/preflight/README.md)
- Starter preflight manifest: [tier-matrix/starter/preflight/manifest.json](./tier-matrix/starter/preflight/manifest.json)
- Starter preflight validation: [tier-matrix/starter/preflight/preflight-report-validation.txt](./tier-matrix/starter/preflight/preflight-report-validation.txt)
- Starter receipts: \`preflight-output.txt\`, \`report-draft-validation.txt\`, \`intake-activation-record-validation.txt\`, \`research-dispatch-validation.txt\`, \`evidence-capture-validation.txt\`, \`scoring-pack-validation.txt\`, \`delivery-email-validation.txt\`, \`delivery-package-validation.txt\`, \`closeout-record-validation.txt\`
- Business dry run: [tier-matrix/business/](./tier-matrix/business/)
- Business summary: [tier-matrix/business/README.md](./tier-matrix/business/README.md)
- Business manifest: [tier-matrix/business/manifest.json](./tier-matrix/business/manifest.json)
- Business validation: [tier-matrix/business/full-dry-run-report-validation.txt](./tier-matrix/business/full-dry-run-report-validation.txt)
- Business preflight summary: [tier-matrix/business/preflight/README.md](./tier-matrix/business/preflight/README.md)
- Business preflight manifest: [tier-matrix/business/preflight/manifest.json](./tier-matrix/business/preflight/manifest.json)
- Business preflight validation: [tier-matrix/business/preflight/preflight-report-validation.txt](./tier-matrix/business/preflight/preflight-report-validation.txt)
- Business receipts: \`preflight-output.txt\`, \`report-draft-validation.txt\`, \`intake-activation-record-validation.txt\`, \`research-dispatch-validation.txt\`, \`evidence-capture-validation.txt\`, \`scoring-pack-validation.txt\`, \`delivery-email-validation.txt\`, \`delivery-package-validation.txt\`, \`closeout-record-validation.txt\`
- Enterprise dry run: [tier-matrix/enterprise/](./tier-matrix/enterprise/)
- Enterprise summary: [tier-matrix/enterprise/README.md](./tier-matrix/enterprise/README.md)
- Enterprise manifest: [tier-matrix/enterprise/manifest.json](./tier-matrix/enterprise/manifest.json)
- Enterprise validation: [tier-matrix/enterprise/full-dry-run-report-validation.txt](./tier-matrix/enterprise/full-dry-run-report-validation.txt)
- Enterprise preflight summary: [tier-matrix/enterprise/preflight/README.md](./tier-matrix/enterprise/preflight/README.md)
- Enterprise preflight manifest: [tier-matrix/enterprise/preflight/manifest.json](./tier-matrix/enterprise/preflight/manifest.json)
- Enterprise preflight validation: [tier-matrix/enterprise/preflight/preflight-report-validation.txt](./tier-matrix/enterprise/preflight/preflight-report-validation.txt)
- Enterprise receipts: \`preflight-output.txt\`, \`report-draft-validation.txt\`, \`intake-activation-record-validation.txt\`, \`research-dispatch-validation.txt\`, \`evidence-capture-validation.txt\`, \`scoring-pack-validation.txt\`, \`delivery-email-validation.txt\`, \`delivery-package-validation.txt\`, \`closeout-record-validation.txt\`

## Outcome

This run validates the local AIReady production lane by checking:

1. doc-to-script drift across live operator docs
2. direct invocation across the AIReady wrapper chain
3. fail-closed behavior on blocking bad inputs
4. disposable dry-run coverage across Starter, Business, and Enterprise
5. evidence packet completeness across the generated summaries and manifests
EOF

cat >"$summary_manifest" <<EOF
{
  "report_root": "$report_root",
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S %Z')",
  "requested_history_window": $requested_history_window,
  "validated_gates": [
    {
      "name": "direct invocation",
      "output_file": "$direct_invocation_output"
    },
    {
      "name": "doc asset links",
      "output_file": "$doc_asset_output"
    },
    {
      "name": "fail-closed smoke",
      "output_file": "$fail_closed_output",
      "artifact_root": "$fail_closed_root",
      "summary_readme": "$fail_closed_root/README.md",
      "summary_manifest": "$fail_closed_root/manifest.json",
      "report_validation_output": "$fail_closed_report_validation_output"
    },
    {
      "name": "tier matrix smoke",
      "output_file": "$tier_matrix_output",
      "artifact_root": "$tier_matrix_root",
      "summary_readme": "$tier_matrix_root/README.md",
      "summary_manifest": "$tier_matrix_root/manifest.json",
      "report_validation_output": "$tier_matrix_report_validation_output",
      "tiers": [
        {
          "tier": "Starter",
          "artifact_root": "$tier_matrix_root/starter",
          "summary_readme": "$tier_matrix_root/starter/README.md",
          "summary_manifest": "$tier_matrix_root/starter/manifest.json",
          "report_validation_output": "$tier_matrix_root/starter/full-dry-run-report-validation.txt",
          "preflight_summary_readme": "$tier_matrix_root/starter/preflight/README.md",
          "preflight_summary_manifest": "$tier_matrix_root/starter/preflight/manifest.json",
          "preflight_report_validation_output": "$tier_matrix_root/starter/preflight/preflight-report-validation.txt",
          "receipt_outputs": [
            "$tier_matrix_root/starter/preflight-output.txt",
            "$tier_matrix_root/starter/report-draft-validation.txt",
            "$tier_matrix_root/starter/intake-activation-record-validation.txt",
            "$tier_matrix_root/starter/research-dispatch-validation.txt",
            "$tier_matrix_root/starter/evidence-capture-validation.txt",
            "$tier_matrix_root/starter/scoring-pack-validation.txt",
            "$tier_matrix_root/starter/delivery-email-validation.txt",
            "$tier_matrix_root/starter/delivery-package-validation.txt",
            "$tier_matrix_root/starter/closeout-record-validation.txt"
          ]
        },
        {
          "tier": "Business",
          "artifact_root": "$tier_matrix_root/business",
          "summary_readme": "$tier_matrix_root/business/README.md",
          "summary_manifest": "$tier_matrix_root/business/manifest.json",
          "report_validation_output": "$tier_matrix_root/business/full-dry-run-report-validation.txt",
          "preflight_summary_readme": "$tier_matrix_root/business/preflight/README.md",
          "preflight_summary_manifest": "$tier_matrix_root/business/preflight/manifest.json",
          "preflight_report_validation_output": "$tier_matrix_root/business/preflight/preflight-report-validation.txt",
          "receipt_outputs": [
            "$tier_matrix_root/business/preflight-output.txt",
            "$tier_matrix_root/business/report-draft-validation.txt",
            "$tier_matrix_root/business/intake-activation-record-validation.txt",
            "$tier_matrix_root/business/research-dispatch-validation.txt",
            "$tier_matrix_root/business/evidence-capture-validation.txt",
            "$tier_matrix_root/business/scoring-pack-validation.txt",
            "$tier_matrix_root/business/delivery-email-validation.txt",
            "$tier_matrix_root/business/delivery-package-validation.txt",
            "$tier_matrix_root/business/closeout-record-validation.txt"
          ]
        },
        {
          "tier": "Enterprise",
          "artifact_root": "$tier_matrix_root/enterprise",
          "summary_readme": "$tier_matrix_root/enterprise/README.md",
          "summary_manifest": "$tier_matrix_root/enterprise/manifest.json",
          "report_validation_output": "$tier_matrix_root/enterprise/full-dry-run-report-validation.txt",
          "preflight_summary_readme": "$tier_matrix_root/enterprise/preflight/README.md",
          "preflight_summary_manifest": "$tier_matrix_root/enterprise/preflight/manifest.json",
          "preflight_report_validation_output": "$tier_matrix_root/enterprise/preflight/preflight-report-validation.txt",
          "receipt_outputs": [
            "$tier_matrix_root/enterprise/preflight-output.txt",
            "$tier_matrix_root/enterprise/report-draft-validation.txt",
            "$tier_matrix_root/enterprise/intake-activation-record-validation.txt",
            "$tier_matrix_root/enterprise/research-dispatch-validation.txt",
            "$tier_matrix_root/enterprise/evidence-capture-validation.txt",
            "$tier_matrix_root/enterprise/scoring-pack-validation.txt",
            "$tier_matrix_root/enterprise/delivery-email-validation.txt",
            "$tier_matrix_root/enterprise/delivery-package-validation.txt",
            "$tier_matrix_root/enterprise/closeout-record-validation.txt"
          ]
        }
      ]
    },
    {
      "name": "artifact audit",
      "output_file": "$artifact_audit_output",
      "validated_artifacts": [
        "$direct_invocation_output",
        "$doc_asset_output",
        "$fail_closed_output",
        "$tier_matrix_output",
        "$report_root_validation_output",
        "$proof_checksums_output",
        "$proof_checksums_validation_output",
        "$fail_closed_report_validation_output",
        "$fail_closed_root/README.md",
        "$fail_closed_root/manifest.json",
        "$tier_matrix_root/README.md",
        "$tier_matrix_root/manifest.json",
        "$tier_matrix_root/starter/README.md",
        "$tier_matrix_root/starter/manifest.json",
        "$tier_matrix_root/starter/preflight/README.md",
        "$tier_matrix_root/starter/preflight/manifest.json",
        "$tier_matrix_root/starter/preflight-output.txt",
        "$tier_matrix_root/starter/report-draft-validation.txt",
        "$tier_matrix_root/starter/intake-activation-record-validation.txt",
        "$tier_matrix_root/starter/research-dispatch-validation.txt",
        "$tier_matrix_root/starter/evidence-capture-validation.txt",
        "$tier_matrix_root/starter/scoring-pack-validation.txt",
        "$tier_matrix_root/starter/delivery-email-validation.txt",
        "$tier_matrix_root/starter/delivery-package-validation.txt",
        "$tier_matrix_root/starter/closeout-record-validation.txt",
        "$tier_matrix_root/business/README.md",
        "$tier_matrix_root/business/manifest.json",
        "$tier_matrix_root/business/preflight/README.md",
        "$tier_matrix_root/business/preflight/manifest.json",
        "$tier_matrix_root/business/preflight-output.txt",
        "$tier_matrix_root/business/report-draft-validation.txt",
        "$tier_matrix_root/business/intake-activation-record-validation.txt",
        "$tier_matrix_root/business/research-dispatch-validation.txt",
        "$tier_matrix_root/business/evidence-capture-validation.txt",
        "$tier_matrix_root/business/scoring-pack-validation.txt",
        "$tier_matrix_root/business/delivery-email-validation.txt",
        "$tier_matrix_root/business/delivery-package-validation.txt",
        "$tier_matrix_root/business/closeout-record-validation.txt",
        "$tier_matrix_root/enterprise/README.md",
        "$tier_matrix_root/enterprise/manifest.json",
        "$tier_matrix_root/enterprise/preflight/README.md",
        "$tier_matrix_root/enterprise/preflight/manifest.json",
        "$tier_matrix_root/enterprise/preflight-output.txt",
        "$tier_matrix_root/enterprise/report-draft-validation.txt",
        "$tier_matrix_root/enterprise/intake-activation-record-validation.txt",
        "$tier_matrix_root/enterprise/research-dispatch-validation.txt",
        "$tier_matrix_root/enterprise/evidence-capture-validation.txt",
        "$tier_matrix_root/enterprise/scoring-pack-validation.txt",
        "$tier_matrix_root/enterprise/delivery-email-validation.txt",
        "$tier_matrix_root/enterprise/delivery-package-validation.txt",
        "$tier_matrix_root/enterprise/closeout-record-validation.txt"
      ]
    },
    {
      "name": "proof checksums",
      "output_file": "$proof_checksums_output"
    },
    {
      "name": "proof checksum validation",
      "output_file": "$proof_checksums_validation_output"
    },
    {
      "name": "report-root validation",
      "output_file": "$report_root_validation_output"
    }
  ]
}
EOF

checksum_inputs=(
  "$summary_readme"
  "$summary_manifest"
  "$artifact_audit_output"
  "$direct_invocation_output"
  "$doc_asset_output"
  "$fail_closed_output"
  "$fail_closed_report_validation_output"
  "$tier_matrix_output"
  "$tier_matrix_report_validation_output"
  "$report_root_validation_output"
  "$fail_closed_root/README.md"
  "$fail_closed_root/manifest.json"
  "$tier_matrix_root/README.md"
  "$tier_matrix_root/manifest.json"
  "$tier_matrix_root/starter/README.md"
  "$tier_matrix_root/starter/manifest.json"
  "$tier_matrix_root/starter/preflight/README.md"
  "$tier_matrix_root/starter/preflight/manifest.json"
  "$tier_matrix_root/business/README.md"
  "$tier_matrix_root/business/manifest.json"
  "$tier_matrix_root/business/preflight/README.md"
  "$tier_matrix_root/business/preflight/manifest.json"
  "$tier_matrix_root/enterprise/README.md"
  "$tier_matrix_root/enterprise/manifest.json"
  "$tier_matrix_root/enterprise/preflight/README.md"
  "$tier_matrix_root/enterprise/preflight/manifest.json"
)

report_validation_tmp="$report_root/.release-readiness-report-validation.tmp"
"$report_root_validator" --preproof "$report_root" >"$report_validation_tmp"
if [[ ! -s "$report_validation_tmp" ]]; then
  echo "Missing or empty preproof validation output: $report_validation_tmp" >&2
  exit 1
fi
mv "$report_validation_tmp" "$report_root_validation_output"

{
  echo "# AIReady Release Readiness Proof Checksums"
  echo
  echo "report_root: $report_root"
  echo "generated_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  sha256sum "${checksum_inputs[@]}"
} >"$proof_checksums_output"

{
  echo "AIReady release-readiness proof checksum validation"
  echo "report_root: $report_root"
  echo
  grep -E '^[0-9a-f]{64}  .+' "$proof_checksums_output" | sha256sum -c
} | tee "$proof_checksums_validation_output"

"$report_root_validator" "$report_root" >"$report_validation_tmp"
if [[ ! -s "$report_validation_tmp" ]]; then
  echo "Missing or empty final validation output: $report_validation_tmp" >&2
  exit 1
fi
mv "$report_validation_tmp" "$report_root_validation_output"
write_artifact_audit true true

final_outputs=(
  "$summary_readme"
  "$summary_manifest"
  "$artifact_audit_output"
  "$proof_checksums_output"
  "$proof_checksums_validation_output"
  "$report_root_validation_output"
)

for path in "${final_outputs[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty final release artifact: $path" >&2
    exit 1
  fi
done

required_readme_strings=(
  "## Validated gates"
  "Direct invocation: [direct-invocation.txt](./direct-invocation.txt)"
  "Doc asset links: [doc-asset-links.txt](./doc-asset-links.txt)"
  "Fail-closed smoke: [fail-closed.txt](./fail-closed.txt)"
  "Tier matrix smoke: [tier-matrix.txt](./tier-matrix.txt)"
  "Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  "Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  "Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  "Report-root validation: [release-readiness-report-validation.txt](./release-readiness-report-validation.txt)"
  "Starter dry run: [tier-matrix/starter/](./tier-matrix/starter/)"
  "Business dry run: [tier-matrix/business/](./tier-matrix/business/)"
  "Enterprise dry run: [tier-matrix/enterprise/](./tier-matrix/enterprise/)"
)

for expected in "${required_readme_strings[@]}"; do
  if ! grep -Fq "$expected" "$summary_readme"; then
    echo "Top-level release README missing expected content: $expected" >&2
    exit 1
  fi
done

required_manifest_strings=(
  '"name": "direct invocation"'
  '"name": "doc asset links"'
  '"name": "fail-closed smoke"'
  '"name": "tier matrix smoke"'
  '"name": "artifact audit"'
  '"name": "report-root validation"'
  '"tier": "Starter"'
  '"tier": "Business"'
  '"tier": "Enterprise"'
)

for expected in "${required_manifest_strings[@]}"; do
  if ! grep -Fq "$expected" "$summary_manifest"; then
    echo "Top-level release manifest missing expected content: $expected" >&2
    exit 1
  fi
done

echo "AIReady release readiness check completed"
echo "report_root: $report_root"
echo
echo "validated_gates:"
printf '  - %s\n' \
  "direct invocation" \
  "doc asset links" \
  "fail-closed smoke" \
  "tier matrix smoke" \
  "artifact audit" \
  "report-root validation"
