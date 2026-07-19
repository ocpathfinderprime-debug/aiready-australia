#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-release-readiness-proof.sh /path/to/release-readiness-report-root

Rebuild the top-level proof checksum files for an existing AIReady
release-readiness report root so older packet formats can be normalized to the
current checksum contract.
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

report_root="$1"
workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$workspace_root/scripts/aiready-validate-release-readiness-report.sh"

if [[ ! -d "$report_root" ]]; then
  echo "Report root not found: $report_root" >&2
  exit 1
fi

if [[ ! -f "$validator" ]]; then
  echo "Missing validator: $validator" >&2
  exit 1
fi

summary_readme="$report_root/README.md"
summary_manifest="$report_root/manifest.json"
artifact_audit_output="$report_root/artifact-audit.txt"
direct_invocation_output="$report_root/direct-invocation.txt"
doc_asset_output="$report_root/doc-asset-links.txt"
fail_closed_root="$report_root/fail-closed"
tier_matrix_root="$report_root/tier-matrix"
fail_closed_output="$report_root/fail-closed.txt"
tier_matrix_output="$report_root/tier-matrix.txt"
proof_checksums_output="$report_root/proof-sha256.txt"
proof_checksums_validation_output="$report_root/proof-sha256-validation.txt"
report_root_validation_output="$report_root/release-readiness-report-validation.txt"
fail_closed_report_validation_output="$fail_closed_root/fail-closed-report-validation.txt"
tier_matrix_report_validation_output="$tier_matrix_root/tier-matrix/tier-matrix-report-validation.txt"

required_files=(
  "$artifact_audit_output"
  "$direct_invocation_output"
  "$doc_asset_output"
  "$fail_closed_output"
  "$fail_closed_report_validation_output"
  "$tier_matrix_output"
  "$tier_matrix_root/tier-matrix-report-validation.txt"
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

for path in "${required_files[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Missing or empty required file: $path" >&2
    exit 1
  fi
done

tier_matrix_report_validation_output="$tier_matrix_root/tier-matrix-report-validation.txt"
generated_at="$(jq -r '.generated_at // empty' "$summary_manifest" 2>/dev/null || true)"
if [[ -z "$generated_at" ]]; then
  generated_at="$(date '+%Y-%m-%d %H:%M:%S %Z')"
fi

requested_history_window="$(jq -r '.requested_history_window // .history_window // empty' "$summary_manifest" 2>/dev/null || true)"
if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
  requested_history_window="$(jq -r '.reports_checked // empty' "$report_root/../history/manifest.json" 2>/dev/null || true)"
fi
if ! [[ "$requested_history_window" =~ ^[1-9][0-9]*$ ]]; then
  # Legacy exact roots predate the explicit field; the generator's historical default was 5.
  requested_history_window="5"
fi

if [[ ! -f "$summary_manifest" ]]; then
  printf '{\n  "report_root": "%s",\n  "generated_at": "%s",\n  "requested_history_window": %s,\n  "validated_gates": []\n}\n' \
    "$report_root" "$generated_at" "$requested_history_window" >"$summary_manifest"
fi

{
  echo "# AIReady Release Readiness Check"
  echo
  echo "- Report root: \`$report_root\`"
  echo "- Generated: \`$generated_at\`"
  echo "- Requested history window: \`$requested_history_window\`"
  echo
  echo "## Validated gates"
  echo
  echo "- Direct invocation: [direct-invocation.txt](./direct-invocation.txt)"
  echo "- Doc asset links: [doc-asset-links.txt](./doc-asset-links.txt)"
  echo "- Fail-closed smoke: [fail-closed.txt](./fail-closed.txt)"
  echo "- Fail-closed validation: [fail-closed/fail-closed-report-validation.txt](./fail-closed/fail-closed-report-validation.txt)"
  echo "- Tier matrix smoke: [tier-matrix.txt](./tier-matrix.txt)"
  echo "- Tier-matrix report validation: [tier-matrix/tier-matrix-report-validation.txt](./tier-matrix/tier-matrix-report-validation.txt)"
  echo "- Artifact audit: [artifact-audit.txt](./artifact-audit.txt)"
  echo "- Report-root validation: [release-readiness-report-validation.txt](./release-readiness-report-validation.txt)"
  echo "- Proof checksums: [proof-sha256.txt](./proof-sha256.txt)"
  echo "- Proof checksum validation: [proof-sha256-validation.txt](./proof-sha256-validation.txt)"
  echo
  echo "## Gate roots"
  echo
  echo "- Fail-closed artifacts: [fail-closed/](./fail-closed/)"
  echo "- Tier matrix artifacts: [tier-matrix/](./tier-matrix/)"
  echo
  echo "## Fail-closed detail"
  echo
  echo "- Fail-closed summary: [fail-closed/README.md](./fail-closed/README.md)"
  echo "- Fail-closed manifest: [fail-closed/manifest.json](./fail-closed/manifest.json)"
  echo "- Fail-closed validation: [fail-closed/fail-closed-report-validation.txt](./fail-closed/fail-closed-report-validation.txt)"
  echo
  echo "## Tier matrix detail"
  echo
  echo "- Tier matrix summary: [tier-matrix/README.md](./tier-matrix/README.md)"
  echo "- Tier matrix manifest: [tier-matrix/manifest.json](./tier-matrix/manifest.json)"
  echo "- Tier matrix validation: [tier-matrix/tier-matrix-report-validation.txt](./tier-matrix/tier-matrix-report-validation.txt)"
  for tier in starter business enterprise; do
    tier_label="$(tr '[:lower:]' '[:upper:]' <<<"${tier:0:1}")${tier:1}"
    echo "- $tier_label dry run: [tier-matrix/$tier/](./tier-matrix/$tier/)"
    echo "- $tier_label summary: [tier-matrix/$tier/README.md](./tier-matrix/$tier/README.md)"
    echo "- $tier_label manifest: [tier-matrix/$tier/manifest.json](./tier-matrix/$tier/manifest.json)"
    echo "- $tier_label validation: [tier-matrix/$tier/full-dry-run-report-validation.txt](./tier-matrix/$tier/full-dry-run-report-validation.txt)"
    echo "- $tier_label preflight summary: [tier-matrix/$tier/preflight/README.md](./tier-matrix/$tier/preflight/README.md)"
    echo "- $tier_label preflight manifest: [tier-matrix/$tier/preflight/manifest.json](./tier-matrix/$tier/preflight/manifest.json)"
    echo "- $tier_label preflight validation: [tier-matrix/$tier/preflight/preflight-report-validation.txt](./tier-matrix/$tier/preflight/preflight-report-validation.txt)"
    echo "- $tier_label receipts: \`preflight-output.txt\`, \`report-draft-validation.txt\`, \`intake-activation-record-validation.txt\`, \`research-dispatch-validation.txt\`, \`evidence-capture-validation.txt\`, \`scoring-pack-validation.txt\`, \`delivery-email-validation.txt\`, \`delivery-package-validation.txt\`, \`closeout-record-validation.txt\`"
  done
  echo
  echo "## Outcome"
  echo
  echo "This run validates the local AIReady production lane by checking:"
  echo
  echo "1. doc-to-script drift across live operator docs"
  echo "2. direct invocation across the AIReady wrapper chain"
  echo "3. fail-closed behavior on blocking bad inputs"
  echo "4. disposable dry-run coverage across Starter, Business, and Enterprise"
  echo "5. evidence packet completeness across the generated summaries and manifests"
} >"$summary_readme"

jq \
  --arg report_root "$report_root" \
  --arg generated_at "$generated_at" \
  --argjson requested_history_window "$requested_history_window" \
  --arg proof_checksums "$proof_checksums_output" \
  --arg proof_checksums_validation "$proof_checksums_validation_output" \
  --arg report_root_validation_output "$report_root_validation_output" \
  --arg artifact_audit "$artifact_audit_output" \
  --arg direct_invocation "$direct_invocation_output" \
  --arg doc_asset_links "$doc_asset_output" \
  --arg fail_closed_output "$fail_closed_output" \
  --arg fail_closed_report_validation "$fail_closed_report_validation_output" \
  --arg tier_matrix_output "$tier_matrix_output" \
  --arg tier_matrix_report_validation "$tier_matrix_report_validation_output" \
  '
  .report_root = $report_root
  | .generated_at = $generated_at
  | .requested_history_window = $requested_history_window
  | .validated_gates = [
    {name:"direct invocation", output_file:$direct_invocation},
    {name:"doc asset links", output_file:$doc_asset_links},
    {
      name:"fail-closed smoke",
      output_file:$fail_closed_output,
      artifact_root:($report_root + "/fail-closed"),
      summary_readme:($report_root + "/fail-closed/README.md"),
      summary_manifest:($report_root + "/fail-closed/manifest.json"),
      report_validation_output:$fail_closed_report_validation
    },
    {
      name:"tier matrix smoke",
      output_file:$tier_matrix_output,
      artifact_root:($report_root + "/tier-matrix"),
      summary_readme:($report_root + "/tier-matrix/README.md"),
      summary_manifest:($report_root + "/tier-matrix/manifest.json"),
      report_validation_output:$tier_matrix_report_validation,
      tiers:[
        {
          tier:"Starter",
          artifact_root:($report_root + "/tier-matrix/starter"),
          summary_readme:($report_root + "/tier-matrix/starter/README.md"),
          summary_manifest:($report_root + "/tier-matrix/starter/manifest.json"),
          report_validation_output:($report_root + "/tier-matrix/starter/full-dry-run-report-validation.txt"),
          preflight_summary_readme:($report_root + "/tier-matrix/starter/preflight/README.md"),
          preflight_summary_manifest:($report_root + "/tier-matrix/starter/preflight/manifest.json"),
          preflight_report_validation_output:($report_root + "/tier-matrix/starter/preflight/preflight-report-validation.txt"),
          receipt_outputs:[
            ($report_root + "/tier-matrix/starter/preflight-output.txt"),
            ($report_root + "/tier-matrix/starter/report-draft-validation.txt"),
            ($report_root + "/tier-matrix/starter/intake-activation-record-validation.txt"),
            ($report_root + "/tier-matrix/starter/research-dispatch-validation.txt"),
            ($report_root + "/tier-matrix/starter/evidence-capture-validation.txt"),
            ($report_root + "/tier-matrix/starter/scoring-pack-validation.txt"),
            ($report_root + "/tier-matrix/starter/delivery-email-validation.txt"),
            ($report_root + "/tier-matrix/starter/delivery-package-validation.txt"),
            ($report_root + "/tier-matrix/starter/closeout-record-validation.txt")
          ]
        },
        {
          tier:"Business",
          artifact_root:($report_root + "/tier-matrix/business"),
          summary_readme:($report_root + "/tier-matrix/business/README.md"),
          summary_manifest:($report_root + "/tier-matrix/business/manifest.json"),
          report_validation_output:($report_root + "/tier-matrix/business/full-dry-run-report-validation.txt"),
          preflight_summary_readme:($report_root + "/tier-matrix/business/preflight/README.md"),
          preflight_summary_manifest:($report_root + "/tier-matrix/business/preflight/manifest.json"),
          preflight_report_validation_output:($report_root + "/tier-matrix/business/preflight/preflight-report-validation.txt"),
          receipt_outputs:[
            ($report_root + "/tier-matrix/business/preflight-output.txt"),
            ($report_root + "/tier-matrix/business/report-draft-validation.txt"),
            ($report_root + "/tier-matrix/business/intake-activation-record-validation.txt"),
            ($report_root + "/tier-matrix/business/research-dispatch-validation.txt"),
            ($report_root + "/tier-matrix/business/evidence-capture-validation.txt"),
            ($report_root + "/tier-matrix/business/scoring-pack-validation.txt"),
            ($report_root + "/tier-matrix/business/delivery-email-validation.txt"),
            ($report_root + "/tier-matrix/business/delivery-package-validation.txt"),
            ($report_root + "/tier-matrix/business/closeout-record-validation.txt")
          ]
        },
        {
          tier:"Enterprise",
          artifact_root:($report_root + "/tier-matrix/enterprise"),
          summary_readme:($report_root + "/tier-matrix/enterprise/README.md"),
          summary_manifest:($report_root + "/tier-matrix/enterprise/manifest.json"),
          report_validation_output:($report_root + "/tier-matrix/enterprise/full-dry-run-report-validation.txt"),
          preflight_summary_readme:($report_root + "/tier-matrix/enterprise/preflight/README.md"),
          preflight_summary_manifest:($report_root + "/tier-matrix/enterprise/preflight/manifest.json"),
          preflight_report_validation_output:($report_root + "/tier-matrix/enterprise/preflight/preflight-report-validation.txt"),
          receipt_outputs:[
            ($report_root + "/tier-matrix/enterprise/preflight-output.txt"),
            ($report_root + "/tier-matrix/enterprise/report-draft-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/intake-activation-record-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/research-dispatch-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/evidence-capture-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/scoring-pack-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/delivery-email-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/delivery-package-validation.txt"),
            ($report_root + "/tier-matrix/enterprise/closeout-record-validation.txt")
          ]
        }
      ]
    },
    {
      name:"artifact audit",
      output_file:$artifact_audit,
      validated_artifacts:[
        $direct_invocation,
        $doc_asset_links,
        $fail_closed_output,
        $tier_matrix_output,
        $report_root_validation_output,
        $proof_checksums,
        $proof_checksums_validation,
        $fail_closed_report_validation,
        ($report_root + "/fail-closed/README.md"),
        ($report_root + "/fail-closed/manifest.json"),
        ($report_root + "/tier-matrix/README.md"),
        ($report_root + "/tier-matrix/manifest.json"),
        ($report_root + "/tier-matrix/starter/README.md"),
        ($report_root + "/tier-matrix/starter/manifest.json"),
        ($report_root + "/tier-matrix/starter/preflight/README.md"),
        ($report_root + "/tier-matrix/starter/preflight/manifest.json"),
        ($report_root + "/tier-matrix/starter/preflight-output.txt"),
        ($report_root + "/tier-matrix/starter/report-draft-validation.txt"),
        ($report_root + "/tier-matrix/starter/intake-activation-record-validation.txt"),
        ($report_root + "/tier-matrix/starter/research-dispatch-validation.txt"),
        ($report_root + "/tier-matrix/starter/evidence-capture-validation.txt"),
        ($report_root + "/tier-matrix/starter/scoring-pack-validation.txt"),
        ($report_root + "/tier-matrix/starter/delivery-email-validation.txt"),
        ($report_root + "/tier-matrix/starter/delivery-package-validation.txt"),
        ($report_root + "/tier-matrix/starter/closeout-record-validation.txt"),
        ($report_root + "/tier-matrix/business/README.md"),
        ($report_root + "/tier-matrix/business/manifest.json"),
        ($report_root + "/tier-matrix/business/preflight/README.md"),
        ($report_root + "/tier-matrix/business/preflight/manifest.json"),
        ($report_root + "/tier-matrix/business/preflight-output.txt"),
        ($report_root + "/tier-matrix/business/report-draft-validation.txt"),
        ($report_root + "/tier-matrix/business/intake-activation-record-validation.txt"),
        ($report_root + "/tier-matrix/business/research-dispatch-validation.txt"),
        ($report_root + "/tier-matrix/business/evidence-capture-validation.txt"),
        ($report_root + "/tier-matrix/business/scoring-pack-validation.txt"),
        ($report_root + "/tier-matrix/business/delivery-email-validation.txt"),
        ($report_root + "/tier-matrix/business/delivery-package-validation.txt"),
        ($report_root + "/tier-matrix/business/closeout-record-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/README.md"),
        ($report_root + "/tier-matrix/enterprise/manifest.json"),
        ($report_root + "/tier-matrix/enterprise/preflight/README.md"),
        ($report_root + "/tier-matrix/enterprise/preflight/manifest.json"),
        ($report_root + "/tier-matrix/enterprise/preflight-output.txt"),
        ($report_root + "/tier-matrix/enterprise/report-draft-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/intake-activation-record-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/research-dispatch-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/evidence-capture-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/scoring-pack-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/delivery-email-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/delivery-package-validation.txt"),
        ($report_root + "/tier-matrix/enterprise/closeout-record-validation.txt")
      ]
    },
    {name:"proof checksums", output_file:$proof_checksums},
    {name:"proof checksum validation", output_file:$proof_checksums_validation},
    {name:"report-root validation", output_file:$report_root_validation_output}
  ]
  ' "$summary_manifest" >"$summary_manifest.tmp"
mv "$summary_manifest.tmp" "$summary_manifest"

{
  echo "AIReady release readiness artifact audit"
  echo "report_root: $report_root"
  echo
  echo "validated_top_level_files:"
  printf '  - %s\n' \
    "$summary_readme" \
    "$summary_manifest" \
    "$artifact_audit_output" \
    "$proof_checksums_output" \
    "$proof_checksums_validation_output" \
    "$report_root_validation_output" \
    "$fail_closed_report_validation_output" \
    "$direct_invocation_output" \
    "$doc_asset_output" \
    "$fail_closed_output" \
    "$tier_matrix_output"
  echo
  echo "validated_tier_files:"
  printf '  - %s\n' \
    "$report_root/fail-closed/README.md" \
    "$report_root/fail-closed/manifest.json" \
    "$report_root/tier-matrix/README.md" \
    "$report_root/tier-matrix/manifest.json" \
    "$tier_matrix_report_validation_output" \
    "$report_root/tier-matrix/starter/README.md" \
    "$report_root/tier-matrix/starter/manifest.json" \
    "$report_root/tier-matrix/starter/full-dry-run-report-validation.txt" \
    "$report_root/tier-matrix/starter/preflight/preflight-report-validation.txt" \
    "$report_root/tier-matrix/business/README.md" \
    "$report_root/tier-matrix/business/manifest.json" \
    "$report_root/tier-matrix/business/full-dry-run-report-validation.txt" \
    "$report_root/tier-matrix/business/preflight/preflight-report-validation.txt" \
    "$report_root/tier-matrix/enterprise/README.md" \
    "$report_root/tier-matrix/enterprise/manifest.json" \
    "$report_root/tier-matrix/enterprise/full-dry-run-report-validation.txt" \
    "$report_root/tier-matrix/enterprise/preflight/preflight-report-validation.txt"
} >"$artifact_audit_output"

checksum_inputs=(
  "$summary_readme"
  "$summary_manifest"
  "$artifact_audit_output"
  "$direct_invocation_output"
  "$doc_asset_output"
  "$fail_closed_output"
  "$fail_closed_report_validation_output"
  "$tier_matrix_output"
  "$tier_matrix_root/tier-matrix-report-validation.txt"
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
"$validator" --preproof "$report_root" >"$report_validation_tmp"
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

"$validator" "$report_root" >"$report_validation_tmp"
if [[ ! -s "$report_validation_tmp" ]]; then
  echo "Missing or empty final validation output: $report_validation_tmp" >&2
  exit 1
fi
mv "$report_validation_tmp" "$report_root_validation_output"

echo "AIReady release-readiness proof normalized"
echo "report_root: $report_root"
