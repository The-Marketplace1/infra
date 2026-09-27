# Secrets management

Secret values are created and rotated in AWS Secrets Manager. Terraform provisions encrypted secret containers, the External Secrets Operator IRSA role, and narrowly scoped read permissions; it does not receive secret values from source control or create placeholder versions.

## Secret names

```text
marketplace/<environment>/database
marketplace/<environment>/jwt
marketplace/<environment>/payment
marketplace/<environment>/twilio
marketplace/<environment>/smtp
marketplace/<environment>/redis
marketplace/<environment>/api-keys
```

The values are JSON objects whose property names are part of the application/repository contract. The Helm ExternalSecret maps only approved properties into Kubernetes Secrets; this repository owns the secret store plumbing, not the application credential format.

## Provisioning flow

1. Apply the environment Terraform configuration. This creates empty, encrypted Secrets Manager containers and the External Secrets Operator role.
2. Populate each secret out of band using the approved security/deployment process.
3. Confirm the Kubernetes `ClusterSecretStore` can assume the IRSA role and that the ExternalSecret becomes `Ready`.
4. Verify that only the intended namespace and workload service accounts can consume the resulting Kubernetes Secret.

Secret values must not be passed as Terraform variables, stored in Terraform state, or placed in Helm values. If a secret is not required by an environment, do not add a wildcard read permission to compensate.

## Rotation

1. Write the new value to the environment's secret manager entry.
2. Confirm External Secrets reports a successful refresh.
3. Roll workloads with `kubectl rollout restart deployment -n <namespace>` if the application reads secrets only at startup.
4. Verify health checks and the service's provider connectivity.
5. Revoke the old credential after the new value is confirmed.

Never paste secret values into pull requests, Terraform variables, Kubernetes manifests, logs, or chat. Do not print `SecretString`, Kubernetes Secret data, or rendered secret manifests in CI logs.
