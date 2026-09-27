# Scaling runbook

HPA is the default scaling path. Inspect `kubectl describe hpa`, pod resource requests, and node capacity before changing replica counts. For sustained cluster pressure, adjust the EKS application node group through Terraform and deploy the plan through the normal review path.
