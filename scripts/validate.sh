#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRE_EXTERNAL_TOOLS="${REQUIRE_EXTERNAL_TOOLS:-0}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    if [[ "$REQUIRE_EXTERNAL_TOOLS" == "1" ]]; then
      echo "ERROR: required command '$1' is not installed" >&2
      exit 1
    fi
    echo "WARN: '$1' not installed; skipped" >&2
    return 1
  fi
  return 0
}

echo "Checking repository structure..."
"$ROOT/tests/structure.sh"

if require_cmd terraform; then
  terraform -chdir="$ROOT/environments/development" fmt -check -recursive
  terraform -chdir="$ROOT/environments/development" init -backend=false -input=false
  terraform -chdir="$ROOT/environments/development" validate
  terraform -chdir="$ROOT/environments/staging" fmt -check -recursive
  terraform -chdir="$ROOT/environments/staging" init -backend=false -input=false
  terraform -chdir="$ROOT/environments/staging" validate
  terraform -chdir="$ROOT/environments/production" fmt -check -recursive
  terraform -chdir="$ROOT/environments/production" init -backend=false -input=false
  terraform -chdir="$ROOT/environments/production" validate
fi

if require_cmd helm; then
  for values in values-development.yaml values-staging.yaml values-production.yaml; do
    helm lint "$ROOT/helm/marketplace" --values "$ROOT/helm/marketplace/$values" --strict
    helm template marketplace "$ROOT/helm/marketplace" --values "$ROOT/helm/marketplace/$values" >/dev/null
  done
fi

if require_cmd kubeconform; then
  find "$ROOT/kubernetes" -type f -name '*.yaml' -print0 |
    xargs -0 kubeconform -strict -ignore-missing-schemas -kubernetes-version 1.29.0
fi

if require_cmd docker; then
  docker compose -f "$ROOT/docker-compose.yml" config >/dev/null
fi

for script in "$ROOT"/scripts/*.sh "$ROOT"/tests/*.sh; do
  bash -n "$script"
done

echo "Infrastructure validation complete."
