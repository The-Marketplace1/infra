# Disaster Recovery Plan

## Recovery objectives

| Component | RPO | RTO | Recovery source |
|---|---:|---:|---|
| PostgreSQL | 5 minutes | 60 minutes | RDS point-in-time restore or cross-region snapshot |
| Redis | 6 hours | 30 minutes | ElastiCache snapshot |
| Private/public assets | 15 minutes | 60 minutes | S3 versioning and encrypted backup bucket |
| Kubernetes | 15 minutes | 60 minutes | Terraform and Helm from Git |

## Procedure

1. Declare the incident and freeze production deployments.
2. Select the latest verified backup in the recovery region.
3. Recreate networking, KMS, IAM, secrets containers, storage, and compute from Terraform in that order.
4. Restore RDS into private subnets and rotate the database secret.
5. Restore Redis from the latest snapshot when cache state is required; treat cache loss as acceptable where the service contract permits it.
6. Restore critical object storage from the encrypted backup bucket and preserve private/public prefixes.
7. Install the Helm release and wait for service health checks.
8. Restore DNS records only after ALB, ingress, database, Redis, secrets, and object storage checks pass from an external probe.
9. Verify service-to-service connectivity, read/write health, queues, and object storage.
10. Record recovery timestamps, backup identifiers, and unresolved data loss.

## Verification

Backup verification is a scheduled operational task using `scripts/verify-backups.sh`. A restore is considered verified only when the restored database passes the database repository's migration check, object versions are readable from the recovery account, secrets can be rehydrated without exposing values, and a read-only application smoke test passes.

DNS recovery depends on the authoritative zone and certificate provider being available. If the primary region is unavailable, use the documented recovery-region records and certificate mapping rather than pointing production DNS at an unverified endpoint.
