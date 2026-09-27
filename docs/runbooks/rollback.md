# Rollback runbook

For an application-only regression:

```bash
helm history marketplace -n marketplace-production
helm rollback marketplace <REVISION> -n marketplace-production --wait --timeout 15m
```

For infrastructure changes, restore the previous approved Terraform plan rather than manually deleting resources. For database changes, follow the database repository's migration rollback policy; this repository does not contain schema definitions.
