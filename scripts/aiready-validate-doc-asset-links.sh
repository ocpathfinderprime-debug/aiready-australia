#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-validate-doc-asset-links.sh
  aiready-validate-doc-asset-links.sh <doc_path> [doc_path ...]

Validates that AIReady docs only reference existing, directly runnable local
`scripts/aiready-*.sh` commands. This is a doc-to-script drift check for the
first-intake lane.
EOF
}

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -eq 0 ]]; then
  docs=(
    "$workspace_root/ops/AIREADY-FIRST-INTAKE-RUNBOOK.md"
    "$workspace_root/ops/AIREADY-DELIVERY-WORKFLOW-AND-PACKS.md"
    "$workspace_root/ops/AIREADY-SYSTEM-INTEGRATION.md"
    "$workspace_root/ops/AIREADY-ZOHO-CRM-WORKFLOW-SPEC.md"
  )
else
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi
  docs=("$@")
fi

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

for doc in "${docs[@]}"; do
  require_file "$doc"
done

total_refs=0
declare -A seen_refs=()
declare -A seen_docs=()

for doc in "${docs[@]}"; do
  mapfile -t refs < <(grep -oE 'scripts/aiready-[a-z0-9-]+\.sh' "$doc" | sort -u)
  if [[ ${#refs[@]} -eq 0 ]]; then
    echo "No AIReady script references found in: $doc" >&2
    exit 1
  fi

  for ref in "${refs[@]}"; do
    path="$workspace_root/$ref"
    if [[ ! -f "$path" ]]; then
      echo "Missing referenced script: $ref (from $doc)" >&2
      exit 1
    fi
    if [[ ! -x "$path" ]]; then
      echo "Referenced script is not executable: $ref (from $doc)" >&2
      exit 1
    fi
    seen_refs["$ref"]=1
    seen_docs["$doc"]=1
    total_refs=$((total_refs + 1))
  done

  echo "validated_doc: $doc"
  printf '  referenced_scripts: %s\n' "${#refs[@]}"
done

echo "AIReady doc asset link validation completed"
echo "documents_checked: ${#seen_docs[@]}"
echo "total_doc_references: $total_refs"
echo "unique_scripts_referenced: ${#seen_refs[@]}"
