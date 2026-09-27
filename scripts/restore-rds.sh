#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT_ID="${1:-}"
TARGET_IDENTIFIER="${2:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -z "$SNAPSHOT_ID" || -z "$TARGET_IDENTIFIER" ]]; then
  echo "Usage: $0 <snapshot-id> <target-db-identifier>" >&2
  exit 2
fi

echo "This operation creates a new RDS instance and does not overwrite the source."
read -r -p "Type RESTORE to continue: " confirmation
[[ "$confirmation" == "RESTORE" ]] || { echo "Restore cancelled."; exit 1; }

aws rds restore-db-instance-from-db-snapshot \
  --region "$AWS_REGION" \
  --db-instance-identifier "$TARGET_IDENTIFIER" \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --no-publicly-accessible

aws rds wait db-instance-available \
  --region "$AWS_REGION" \
  --db-instance-identifier "$TARGET_IDENTIFIER"
echo "RDS restore is available: ${TARGET_IDENTIFIER}"
