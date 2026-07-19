#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-normalize-all-release-readiness-history-trend-proofs.sh [reports_root]

Find stale AIReady release-readiness history trend audit packets that predate
the current requested-history-window/compatibility contract and rebuild the
repairable ones in place.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reports_root="${1:-$workspace_root/reports}"
normalizer="$workspace_root/scripts/aiready-normalize-release-readiness-history-trend-proof.sh"

if [[ ! -d "$reports_root" ]]; then
  echo "Reports root not found: $reports_root" >&2
  exit 1
fi

if [[ ! -f "$normalizer" ]]; then
  echo "Missing normalizer: $normalizer" >&2
  exit 1
fi

mapfile -t audit_roots < <(find "$reports_root" -maxdepth 1 -type d -name 'aiready-release-readiness-history-trend-*AWST' | sort)

if [[ "${#audit_roots[@]}" -eq 0 ]]; then
  echo "No release-readiness history trend audit roots found under $reports_root"
  exit 0
fi

stale_roots=()
skipped_roots=()

for audit_root in "${audit_roots[@]}"; do
  manifest="$audit_root/manifest.json"
  validation_log="$audit_root/history-trend-validation.txt"

  if [[ ! -s "$manifest" || ! -s "$validation_log" ]]; then
    skipped_roots+=("$audit_root")
    continue
  fi

  if jq -e 'has("requested_history_window") and has("compatibility_report") and has("comparable_history_audits_checked") and has("legacy_window_mismatch_audits")' "$manifest" >/dev/null 2>&1 && [[ -s "$audit_root/history-trend-compatibility.txt" ]]; then
    continue
  fi

  stale_roots+=("$audit_root")
done

if [[ "${#stale_roots[@]}" -eq 0 ]]; then
  echo "No stale release-readiness history trend audit roots found"
  if [[ "${#skipped_roots[@]}" -gt 0 ]]; then
    echo "Skipped structurally partial roots:"
    printf '%s\n' "${skipped_roots[@]}"
  fi
  exit 0
fi

printf 'Normalizing %s stale release-readiness history trend audit root(s)\n' "${#stale_roots[@]}"
printf '%s\n' "${stale_roots[@]}"

for audit_root in "${stale_roots[@]}"; do
  "$normalizer" "$audit_root"
done

echo
printf 'Normalized stale release-readiness history trend audit root(s): %s\n' "${#stale_roots[@]}"
if [[ "${#skipped_roots[@]}" -gt 0 ]]; then
  echo "Skipped structurally partial roots:"
  printf '%s\n' "${skipped_roots[@]}"
fi
