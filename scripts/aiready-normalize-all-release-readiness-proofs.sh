#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-all-release-readiness-proofs.sh [reports_root]

Find stale AIReady release-readiness report roots that predate the current
requested-history-window contract and rebuild them in place.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reports_root="${1:-$workspace_root/reports}"
normalizer="$workspace_root/scripts/aiready-normalize-release-readiness-proof.sh"

if [[ ! -d "$reports_root" ]]; then
  echo "Reports root not found: $reports_root" >&2
  exit 1
fi

if [[ ! -f "$normalizer" ]]; then
  echo "Missing normalizer: $normalizer" >&2
  exit 1
fi

mapfile -t report_roots < <(find "$reports_root" -maxdepth 1 -type d -name 'aiready-release-readiness-[0-9]*-AWST' | sort)

if [[ "${#report_roots[@]}" -eq 0 ]]; then
  echo "No release-readiness report roots found under $reports_root"
  exit 0
fi

stale_roots=()
skipped_roots=()

for report_root in "${report_roots[@]}"; do
  manifest="$report_root/manifest.json"
  readme="$report_root/README.md"
  artifact_audit="$report_root/artifact-audit.txt"
  direct_invocation="$report_root/direct-invocation.txt"
  doc_asset_links="$report_root/doc-asset-links.txt"
  fail_closed_output="$report_root/fail-closed.txt"
  tier_matrix_output="$report_root/tier-matrix.txt"
  fail_closed_readme="$report_root/fail-closed/README.md"
  fail_closed_manifest="$report_root/fail-closed/manifest.json"
  fail_closed_validation="$report_root/fail-closed/fail-closed-report-validation.txt"
  tier_matrix_readme="$report_root/tier-matrix/README.md"
  tier_matrix_manifest="$report_root/tier-matrix/manifest.json"
  tier_matrix_validation="$report_root/tier-matrix/tier-matrix-report-validation.txt"
  starter_readme="$report_root/tier-matrix/starter/README.md"
  starter_manifest="$report_root/tier-matrix/starter/manifest.json"
  starter_preflight_readme="$report_root/tier-matrix/starter/preflight/README.md"
  starter_preflight_manifest="$report_root/tier-matrix/starter/preflight/manifest.json"
  business_readme="$report_root/tier-matrix/business/README.md"
  business_manifest="$report_root/tier-matrix/business/manifest.json"
  business_preflight_readme="$report_root/tier-matrix/business/preflight/README.md"
  business_preflight_manifest="$report_root/tier-matrix/business/preflight/manifest.json"
  enterprise_readme="$report_root/tier-matrix/enterprise/README.md"
  enterprise_manifest="$report_root/tier-matrix/enterprise/manifest.json"
  enterprise_preflight_readme="$report_root/tier-matrix/enterprise/preflight/README.md"
  enterprise_preflight_manifest="$report_root/tier-matrix/enterprise/preflight/manifest.json"

  if [[ ! -s "$manifest" || ! -s "$readme" || ! -s "$artifact_audit" || ! -s "$direct_invocation" || ! -s "$doc_asset_links" || ! -s "$fail_closed_output" || ! -s "$tier_matrix_output" || ! -s "$fail_closed_readme" || ! -s "$fail_closed_manifest" || ! -s "$fail_closed_validation" || ! -s "$tier_matrix_readme" || ! -s "$tier_matrix_manifest" || ! -s "$tier_matrix_validation" || ! -s "$starter_readme" || ! -s "$starter_manifest" || ! -s "$starter_preflight_readme" || ! -s "$starter_preflight_manifest" || ! -s "$business_readme" || ! -s "$business_manifest" || ! -s "$business_preflight_readme" || ! -s "$business_preflight_manifest" || ! -s "$enterprise_readme" || ! -s "$enterprise_manifest" || ! -s "$enterprise_preflight_readme" || ! -s "$enterprise_preflight_manifest" ]]; then
    skipped_roots+=("$report_root")
    continue
  fi

  if ! jq -e 'has("requested_history_window") or has("history_window")' "$manifest" >/dev/null 2>&1; then
    skipped_roots+=("$report_root")
    continue
  fi

  if ! rg -Fq 'Requested history window:' "$readme"; then
    stale_roots+=("$report_root")
    continue
  fi
done

if [[ "${#stale_roots[@]}" -eq 0 ]]; then
  echo "No stale release-readiness report roots found"
  if [[ "${#skipped_roots[@]}" -gt 0 ]]; then
    echo "Skipped structurally partial roots:"
    printf '%s\n' "${skipped_roots[@]}"
  fi
  exit 0
fi

printf 'Normalizing %s stale release-readiness report root(s)\n' "${#stale_roots[@]}"
printf '%s\n' "${stale_roots[@]}"

for report_root in "${stale_roots[@]}"; do
  "$normalizer" "$report_root"
done

echo
printf 'Normalized stale release-readiness report root(s): %s\n' "${#stale_roots[@]}"
if [[ "${#skipped_roots[@]}" -gt 0 ]]; then
  echo "Skipped structurally partial roots:"
  printf '%s\n' "${skipped_roots[@]}"
fi
