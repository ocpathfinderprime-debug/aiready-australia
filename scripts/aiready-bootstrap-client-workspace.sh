#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  aiready-bootstrap-client-workspace.sh "Business Name" [clients_root]

Creates a live AIReady client workspace from the template pack and renames
business-slug placeholder files to the derived business slug.

Arguments:
  "Business Name"  Required. Used to derive the business slug.
  clients_root     Optional. Defaults to ./Clients
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

business_name="$1"
clients_root="${2:-./Clients}"
template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/templates/aiready-client-workspace"

slug="$(
  printf '%s' "$business_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
)"

if [[ -z "$slug" ]]; then
  echo "Could not derive a valid business slug from: $business_name" >&2
  exit 1
fi

target_root="${clients_root%/}/${slug}"

if [[ ! -d "$template_root" ]]; then
  echo "Template root not found: $template_root" >&2
  exit 1
fi

if [[ -e "$target_root" ]]; then
  echo "Target already exists: $target_root" >&2
  exit 1
fi

mkdir -p "$(dirname "$target_root")"
cp -R "$template_root" "$target_root"

rename_placeholder_file() {
  local from="$1"
  local to="$2"
  if [[ -e "$from" ]]; then
    mv "$from" "$to"
  fi
}

rename_placeholder_file \
  "$target_root/04_Report_Draft/business-slug-aiready-starter-report-draft.md" \
  "$target_root/04_Report_Draft/${slug}-aiready-starter-report-draft.md"

rename_placeholder_file \
  "$target_root/04_Report_Draft/business-slug-aiready-business-report-draft.md" \
  "$target_root/04_Report_Draft/${slug}-aiready-business-report-draft.md"

rename_placeholder_file \
  "$target_root/04_Report_Draft/business-slug-aiready-enterprise-report-draft.md" \
  "$target_root/04_Report_Draft/${slug}-aiready-enterprise-report-draft.md"

rename_placeholder_file \
  "$target_root/06_Delivery/business-slug-delivery-email-draft.md" \
  "$target_root/06_Delivery/${slug}-delivery-email-draft.md"

cat <<EOF
AIReady client workspace created
business_name: $business_name
business_slug: $slug
target_root: $target_root
EOF
