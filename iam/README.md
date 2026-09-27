# IAM

IAM policies in this directory are intentionally narrow. GitHub Actions receives access through OIDC and an approved role; workloads use EKS IRSA service accounts. Long-lived AWS access keys must not be placed in CI variables or pods.

Separate policies cover state/deployment, application asset access, approved secret reads, optional RDS IAM authentication, monitoring reads, and cluster autoscaling. State access is scoped to the environment-specific S3 state bucket and lock table. Autoscaling mutation access is omitted until approved Auto Scaling group ARNs are supplied. Administrative operations remain a separate break-glass concern and are never granted to normal application service accounts.

The policy files are reviewed with Terraform plan and Checkov before deployment. Optional workload policies are not created until their environment composition supplies explicit ARNs; this avoids invalid empty-resource IAM statements and prevents broad wildcard access.
