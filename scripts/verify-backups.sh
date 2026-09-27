#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BACKUP_VAULT="${BACKUP_VAULT:-marketplace-${ENVIRONMENT}-rds}"
BACKUP_BUCKET="${BACKUP_BUCKET:-}"

if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
  echo "Usage: $0 <development|staging|production>" >&2
  exit 2
fi

command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }

aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name "$BACKUP_VAULT" \
  --region "$AWS_REGION" \
  --query 'RecoveryPoints[?Status==`COMPLETED`]|[0].{Arn:RecoveryPointArn,Created:CreationDate}' \
  --output table

if [[ -n "$BACKUP_BUCKET" ]]; then
  status="$(aws s3api get-bucket-versioning --bucket "$BACKUP_BUCKET" --query Status --output text)"
  [[ "$status" == "Enabled" ]] || { echo "Backup bucket versioning is not enabled" >&2; exit 1; }
  aws s3api head-bucket --bucket "$BACKUP_BUCKET"
fi

echo "Backup verification checks passed for ${ENVIRONMENT}."
