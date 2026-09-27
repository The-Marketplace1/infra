# Backups

RDS automated backups are configured in `modules/database`. This directory adds an encrypted AWS Backup vault and daily retention policy. When `object_storage_arns` is supplied, the same plan protects the approved S3 resources; the optional selection is omitted when no object-storage ARNs are configured. S3 versioning and lifecycle rules are configured in `modules/storage`.

Terraform state is bootstrapped separately by `state-backend.tf` with versioned, encrypted S3 storage and a point-in-time-recoverable DynamoDB lock table. State bootstrap must be completed before an environment backend is initialized.

## Change and restore procedure

Before a production migration:

1. Create a manual RDS snapshot and record its identifier in the deployment change.
2. Confirm the latest recovery point in the environment backup vault is `COMPLETED`.
3. Confirm the planned change has no unexpected destructive actions.

Run `scripts/verify-backups.sh <environment>` on a schedule and after backup policy changes. A restore drill must use a new RDS identifier, a non-production recovery namespace, and read-only application verification. Never overwrite the source database during a restore test.

Cross-region vault copy and recovery-region resource creation are operational follow-up work described in `disaster-recovery/plan.md`; recovery credentials and secret values remain out of Git and Terraform state.
