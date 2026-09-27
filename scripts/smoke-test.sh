#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
BASE_URL="${SMOKE_BASE_URL:-}"
NAMESPACE="${KUBE_NAMESPACE:-marketplace-${ENVIRONMENT}}"

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Usage: $0 <development|staging|production>" >&2
  exit 2
fi

if command -v kubectl >/dev/null 2>&1; then
  kubectl get namespace "$NAMESPACE" >/dev/null
  kubectl get deployment -n "$NAMESPACE" -l app.kubernetes.io/part-of=marketplace
fi

if [[ -n "$BASE_URL" ]]; then
  curl --fail --silent --show-error --max-time 15 "$BASE_URL/healthz" >/dev/null
fi

echo "Smoke test passed for ${ENVIRONMENT}."
