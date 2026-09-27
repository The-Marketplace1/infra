#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-}"
NAMESPACE="${2:-marketplace-${ENVIRONMENT}}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-marketplace-${ENVIRONMENT}}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
  echo "Usage: $0 <development|staging|production> [namespace]" >&2
  exit 2
fi

command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }
command -v helm >/dev/null || { echo "helm is required" >&2; exit 1; }

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
helm upgrade --install marketplace "$ROOT/helm/marketplace" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$ROOT/helm/marketplace/values-${ENVIRONMENT}.yaml" \
  --set global.imageTag="$IMAGE_TAG" \
  --atomic \
  --timeout 15m \
  --wait

kubectl rollout status deployment -n "$NAMESPACE" --timeout=10m
"$ROOT/scripts/smoke-test.sh" "$ENVIRONMENT"
