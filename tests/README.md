# Infrastructure tests

`structure.sh` checks required modules, environments, service coverage, and accidental credential patterns. CI adds Terraform validation, Helm rendering, Kubernetes schema validation, Docker Compose parsing, Trivy IaC scanning, Checkov policy checks, and a destructive-action guard for saved Terraform plans.
