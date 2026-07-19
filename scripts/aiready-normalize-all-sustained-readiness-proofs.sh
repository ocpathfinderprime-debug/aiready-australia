#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-all-sustained-readiness-proofs.sh [reports_root]

Find stale AIReady sustained-readiness report roots that predate the current
requested-history-window contract and rebuild them in place.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reports_root="${1:-$workspace_root/reports}"
normalizer="$workspace_root/scripts/aiready-normalize-sustained-readiness-proof.sh"

if [[ ! -d "$reports_root" ]]; then
  echo "Reports root not found: $reports_root" >&2
  exit 1
fi

if [[ ! -f "$normalizer" ]]; then
  echo "Missing normalizer: $normalizer" >&2
  exit 1
fi

mapfile -t report_roots < <(find "$reports_root" -maxdepth 1 -type d -name 'aiready-sustained-readiness-*-AWST' | sort)

if [[ "${#report_roots[@]}" -eq 0 ]]; then
  echo "No sustained-readiness report roots found under $reports_root"
  exit 0
fi

stale_roots=()

for report_root in "${report_roots[@]}"; do
  manifest="$report_root/manifest.json"
  readme="$report_root/README.md"

  if [[ ! -s "$manifest" || ! -s "$readme" ]]; then
    stale_roots+=("$report_root")
    continue
  fi

  if ! jq -e 'has("requested_history_window")' "$manifest" >/dev/null 2>&1; then
    stale_roots+=("$report_root")
    continue
  fi

  if ! rg -Fq 'Requested history window:' "$readme"; then
    stale_roots+=("$report_root")
    continue
  fi
done

if [[ "${#stale_roots[@]}" -eq 0 ]]; then
  echo "No stale sustained-readiness report roots found"
  exit 0
fi

printf 'Normalizing %s stale sustained-readiness report root(s)\n' "${#stale_roots[@]}"
printf '%s\n' "${stale_roots[@]}"

"$normalizer" "${stale_roots[@]}"

echo
printf 'Normalized stale sustained-readiness report root(s): %s\n' "${#stale_roots[@]}"
