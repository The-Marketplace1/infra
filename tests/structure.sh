#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  environments/development
  environments/staging
  environments/production
  modules/networking
  modules/compute
  modules/database
  modules/redis
  modules/storage
  modules/load-balancer
  modules/cdn
  modules/security
  modules/monitoring
  iam
  secrets
  dns
  backups
  disaster-recovery
  scripts
  tests
  docs
  kubernetes
  helm/marketplace
  .github/workflows/infrastructure-deploy.yml
  .env.example
  .gitignore
  README.md
  LICENSE
)

for path in "${required[@]}"; do
  [[ -e "$ROOT/$path" ]] || { echo "Missing required path: $path" >&2; exit 1; }
done

services=(api-gateway auth-service backend-api payment-service notification-service realtime-service communication-service customer-app professional-app admin-dashboard)
for service in "${services[@]}"; do
  grep -q "name: $service" "$ROOT/kubernetes/deployments/marketplace-services.yaml" || {
    echo "Missing Kubernetes deployment: $service" >&2
    exit 1
  }
  grep -q "name: $service" "$ROOT/kubernetes/services/marketplace-services.yaml" || {
    echo "Missing Kubernetes service: $service" >&2
    exit 1
  }
done

scan_dirs=(
  "$ROOT/environments"
  "$ROOT/modules"
  "$ROOT/iam"
  "$ROOT/secrets"
  "$ROOT/dns"
  "$ROOT/backups"
  "$ROOT/disaster-recovery"
  "$ROOT/scripts"
  "$ROOT/tests"
  "$ROOT/docs"
  "$ROOT/kubernetes"
  "$ROOT/helm"
  "$ROOT/.github"
)
if grep -RInE '(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk_live_|whsec_)' \
  "${scan_dirs[@]}" --exclude-dir=.terraform --exclude='*.tfstate' \
  --exclude='.env.example' --exclude='structure.sh'; then
  echo "Potential credential detected in infrastructure source" >&2
  exit 1
fi

echo "Structure and secret checks passed."
