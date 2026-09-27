# Provider portability

Marketplace infrastructure is organized around capabilities rather than provider APIs:

| Capability | AWS implementation | Portable interface |
|---|---|---|
| Networking | VPC, subnets, route tables, NAT, security groups | Private network with controlled ingress and egress |
| Compute | EKS managed node groups | Container orchestration runtime |
| PostgreSQL | RDS PostgreSQL | Managed PostgreSQL endpoint with TLS, backups, and private access |
| PostGIS | RDS-compatible PostgreSQL extension contract | Geospatial PostgreSQL capability |
| Redis | ElastiCache replication group | Managed Redis with authentication and TLS |
| Object storage | S3 | S3-compatible object storage |
| Load balancing | Application Load Balancer | External L7/L4 load balancer |
| CDN | CloudFront | CDN distribution with HTTPS |
| WAF | AWS WAF managed rules | Web application firewall |
| DNS/certificates | Route53 and ACM | Managed DNS and certificate authority |
| Secrets | Secrets Manager and External Secrets | External secret manager projected into workloads |
| Observability | CloudWatch plus Prometheus/OpenTelemetry | Metrics, logs, traces, and alert interfaces |

Provider-specific resources stay inside the Terraform modules and environment composition. Service repositories only receive connection strings, service DNS names, object-storage interfaces, and runtime configuration through Kubernetes secrets/config maps. A future provider module can implement the same capability without changing application code.

## Known differences

Providers do not offer identical failover, IAM, WAF, object lifecycle, or managed PostGIS behavior. A replacement provider must document its recovery semantics and expose those differences in its environment module instead of silently emulating them.
