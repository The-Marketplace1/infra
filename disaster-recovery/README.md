# Disaster recovery

The recovery plan is in `plan.md`. Cloud resources are reproducible from Terraform, Kubernetes resources from Helm, and persistent data from RDS/ElastiCache/S3 backup systems. Recovery access is restricted to the production break-glass role and must be audited.
