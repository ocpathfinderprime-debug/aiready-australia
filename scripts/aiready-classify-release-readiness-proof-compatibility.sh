#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-classify-release-readiness-proof-compatibility.sh /path/to/release-readiness-root [...]

Classify AIReady release-readiness roots against the current proof contract as:
  - current-contract
  - normalizable-legacy
  - structurally-partial
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validator="$workspace_root/scripts/aiready-validate-release-readiness-report.sh"

if [[ ! -f "$validator" ]]; then
  echo "Missing validator: $validator" >&2
  exit 1
fi

for report_root in "$@"; do
  if [[ ! -d "$report_root" ]]; then
    echo "root: $report_root"
    echo "classification: structurally-partial"
    echo "reason: report root not found"
    echo
    continue
  fi

  if "$validator" "$report_root" >/dev/null 2>&1; then
    echo "root: $report_root"
    echo "classification: current-contract"
    echo "reason: passes aiready-validate-release-readiness-report.sh"
    echo
    continue
  fi

  missing=()
  normalizable_requirements=(
    "$report_root/direct-invocation.txt"
    "$report_root/doc-asset-links.txt"
    "$report_root/fail-closed.txt"
    "$report_root/tier-matrix.txt"
    "$report_root/fail-closed/README.md"
    "$report_root/fail-closed/manifest.json"
    "$report_root/fail-closed/fail-closed-report-validation.txt"
    "$report_root/tier-matrix/README.md"
    "$report_root/tier-matrix/manifest.json"
    "$report_root/tier-matrix/tier-matrix-report-validation.txt"
    "$report_root/tier-matrix/starter/README.md"
    "$report_root/tier-matrix/starter/manifest.json"
    "$report_root/tier-matrix/starter/full-dry-run-report-validation.txt"
    "$report_root/tier-matrix/starter/preflight/README.md"
    "$report_root/tier-matrix/starter/preflight/manifest.json"
    "$report_root/tier-matrix/starter/preflight/preflight-report-validation.txt"
    "$report_root/tier-matrix/business/README.md"
    "$report_root/tier-matrix/business/manifest.json"
    "$report_root/tier-matrix/business/full-dry-run-report-validation.txt"
    "$report_root/tier-matrix/business/preflight/README.md"
    "$report_root/tier-matrix/business/preflight/manifest.json"
    "$report_root/tier-matrix/business/preflight/preflight-report-validation.txt"
    "$report_root/tier-matrix/enterprise/README.md"
    "$report_root/tier-matrix/enterprise/manifest.json"
    "$report_root/tier-matrix/enterprise/full-dry-run-report-validation.txt"
    "$report_root/tier-matrix/enterprise/preflight/README.md"
    "$report_root/tier-matrix/enterprise/preflight/manifest.json"
    "$report_root/tier-matrix/enterprise/preflight/preflight-report-validation.txt"
  )

  for path in "${normalizable_requirements[@]}"; do
    if [[ ! -s "$path" ]]; then
      missing+=("$path")
    fi
  done

  echo "root: $report_root"
  if [[ "${#missing[@]}" -eq 0 ]]; then
    echo "classification: normalizable-legacy"
    echo "reason: surviving gate artifacts are sufficient to rebuild the current top-level proof packet"
  else
    echo "classification: structurally-partial"
    echo "reason: missing gate artifacts prevent reconstruction without inventing evidence"
    echo "missing_artifacts:"
    printf '  - %s\n' "${missing[@]}"
  fi
  echo
done
