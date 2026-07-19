#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-direct-invocation.sh

Validates that AIReady wrapper scripts do not invoke other AIReady scripts via
`bash ...`. This protects the direct-command operator lane.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t scripts < <(find "$workspace_root/scripts" -maxdepth 1 -type f -name 'aiready-*.sh' | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "No AIReady scripts found under: $workspace_root/scripts" >&2
  exit 1
fi

pattern='(^|[^[:alnum:]_])bash ("?\$[A-Za-z_][A-Za-z0-9_]*"?|scripts/aiready-[^ ]+\.sh|'"$workspace_root"'/scripts/aiready-[^ ]+\.sh)|bash[[:space:]]+"\$'

if ! results="$(rg -n "$pattern" "${scripts[@]}" || true)"; then
  echo "Failed to scan AIReady scripts" >&2
  exit 1
fi

if [[ -n "$results" ]]; then
  echo "Nested bash invocation detected in AIReady script lane:" >&2
  echo "$results" >&2
  exit 1
fi

echo "AIReady direct invocation validated"
echo "scripts_checked: ${#scripts[@]}"
printf '%s\n' "${scripts[@]}" | sed 's#^#validated_script: #'
