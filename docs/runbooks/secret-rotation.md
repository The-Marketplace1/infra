# Secret rotation runbook

Rotate one provider at a time. Update AWS Secrets Manager, wait for External Secrets synchronization, restart only workloads that need the new value, verify the provider API, then revoke the old credential. Keep the previous value available only for the documented overlap window.
