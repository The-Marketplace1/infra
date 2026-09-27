# Infrastructure architecture

AWS resources are split by environment. Each environment composes the shared modules for networking, EKS compute, RDS, ElastiCache, S3, secrets, security, monitoring, CDN, and the public ALB.

The service repositories own container images and application behavior. This repository only references those images and supplies runtime configuration, network policy, routing, and scaling. PostgreSQL schemas and migrations remain in the database repository.

## Traffic

Route53 points public names to the ALB. The ALB terminates TLS and forwards to the Kubernetes ingress layer. CloudFront fronts object storage for attachments and media. Pods use ClusterIP services for internal discovery.

## Trust boundaries

- Public subnets contain only internet-facing load balancers and NAT gateways.
- EKS nodes, RDS, Redis, and object-storage access remain private.
- Kubernetes namespaces enforce pod security and network policy.
- Secrets are fetched from AWS Secrets Manager through IRSA/External Secrets.
