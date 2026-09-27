#!/usr/bin/env bash
set -euo pipefail

PLAN_JSON="${1:-}"

if [[ -z "$PLAN_JSON" ]]; then
  echo "Usage: $0 <terraform-plan-json>" >&2
  exit 2
fi

[[ -f "$PLAN_JSON" ]] || {
  echo "Terraform plan JSON not found: $PLAN_JSON" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "jq is required to inspect Terraform plan JSON" >&2
  exit 1
}

mapfile -t destructive_addresses < <(
  jq -r '
    [
      .resource_changes[]?
      | select((.change.actions // []) | index("delete"))
      | .address
    ] | .[]
  ' "$PLAN_JSON"
)

if (( ${#destructive_addresses[@]} == 0 )); then
  echo "Terraform plan contains no destructive resource actions."
  exit 0
fi

echo "Terraform plan contains destructive resource actions:" >&2
printf ' - %s\n' "${destructive_addresses[@]}" >&2

if [[ "${ALLOW_DESTRUCTIVE_CHANGES:-false}" != "true" ]]; then
  echo "Destructive changes are blocked. Set the protected environment variable" >&2
  echo "ALLOW_DESTRUCTIVE_CHANGES=true only after explicit change approval." >&2
  exit 1
fi

echo "Destructive changes explicitly approved by ALLOW_DESTRUCTIVE_CHANGES=true."
