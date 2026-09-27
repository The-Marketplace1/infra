# Deployment runbook

1. Open a pull request for Terraform, Helm, or Kubernetes changes.
2. Review the Terraform plan and security scan output.
3. Merge to `main` for staging deployment.
4. Run staging smoke tests and review dashboards.
5. Create a release tag for production.
6. Approve the production GitHub Environment.
7. Confirm the Helm rollout and external health checks.
8. Record the release tag and Terraform plan in the change record.
