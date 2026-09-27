# Storage boundaries

| Asset class | Location | CDN eligible | Default access |
|---|---|---:|---|
| Verification documents | Private assets bucket, `verification/` | No | Workload role only |
| Profile assets | Private assets bucket, `profiles/` | No | Workload role or signed application flow |
| Service assets | Private assets bucket, `services/` | No | Workload role or signed application flow |
| Communication attachments | Private assets bucket, `communication/` | No | Workload role or signed application flow |
| Approved application/static assets | Public assets bucket | Yes | CloudFront only |
| Backups | Dedicated backups bucket | No | Backup and recovery roles only |

All application buckets block public access, enforce bucket-owner ownership, require TLS, use KMS encryption, enable versioning, and apply lifecycle policies. The log destination uses SSE-S3 because S3 server access log delivery does not receive an application KMS grant; its bucket policy restricts writes to the three configured source buckets and their exact prefixes. The CDN origin is deliberately limited to the public-assets bucket; authenticated or sensitive responses are not routed through CloudFront.
