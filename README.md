# Marketplace Infrastructure

AWS infrastructure as code for the Marketplace platform. This repository provisions and operates the runtime foundation for development, staging, and production. Application and business logic live in the service repositories.

## Responsibilities

- VPC networking, public/private subnets, route tables, NAT gateways, security groups, and service connectivity
- EKS compute and Kubernetes deployment infrastructure
- PostgreSQL on RDS, Redis on ElastiCache, S3 object and backup storage
- Load balancing, DNS, CloudFront, ACM certificates, and WAF
- IAM, KMS, AWS Secrets Manager, monitoring, backups, and disaster recovery
- Deployment validation and controlled environment promotion through GitHub Actions

AWS is the initial provider implementation. Application repositories depend on the portable capabilities exposed by these modules — managed PostgreSQL, managed Redis, object storage, load balancing, CDN, WAF, DNS, secrets, IAM, and observability — rather than on AWS SDKs or AWS resource names.

## Repository layout

```text
.
├── environments/{development,staging,production}/
├── modules/{networking,compute,database,redis,storage,load-balancer,cdn,security,monitoring}/
├── iam/
├── secrets/
├── dns/
├── backups/
├── disaster-recovery/
├── scripts/
├── tests/
├── docs/
├── .github/workflows/infrastructure-deploy.yml
├── .env.example
├── .gitignore
├── docker-compose.yml
├── README.md
└── LICENSE
```

## Prerequisites

- Terraform >= 1.7
- AWS CLI v2
- kubectl >= 1.29
- Helm >= 3.14
- Docker >= 24
- `aws`, `terraform`, `kubectl`, `helm`, and `docker` available in `PATH`

Authenticate with an IAM role or short-lived AWS credentials. Do not place credentials in this repository.

## Environment workflow

Each environment has an independent Terraform state backend and configuration. CI always creates a saved plan, rejects destructive actions unless the protected environment explicitly sets `ALLOW_DESTRUCTIVE_CHANGES=true`, and applies that exact reviewed plan:

```bash
cd environments/staging
terraform init
terraform fmt -check -recursive ../..
terraform validate
terraform plan -lock-timeout=10m -out=tfplan
terraform show -json tfplan > tfplan.json
bash ../../scripts/check-plan.sh tfplan.json
terraform apply -lock-timeout=10m tfplan
```

The production workflow requires an approved GitHub Environment and a release tag. Development uses smaller, cost-controlled capacity; staging mirrors high availability; production uses three Availability Zones, multi-AZ RDS, Redis failover, deletion protection, encrypted state, and longer retention.

The database module provisions PostgreSQL with TLS enforcement, encryption, backups, monitoring, and private network access. The required PostGIS and `pg_stat_statements` extensions are declared as an infrastructure contract and enabled by the database repository's migration process; this repository does not contain schemas, migrations, indexes, triggers, or application database policy.

## Secrets

Terraform creates the AWS Secrets Manager resources and IAM access policy, but secret values are supplied out of band. Kubernetes consumes them through External Secrets. See `docs/secrets-management.md`.

Never commit:

- Database credentials
- JWT signing keys
- Payment, Twilio, SMTP, or provider credentials
- AWS access keys, tokens, kubeconfigs, or Terraform state

## Kubernetes and Helm

Kubernetes manifests are grouped by resource kind under `kubernetes/`. The Helm chart in `helm/marketplace` is the deployment package used by CI. Namespaces, service accounts, pod security settings, health checks, rolling updates, HPA, and default-deny network policies are included.

## Validation

Run the same checks used by CI:

```bash
./scripts/validate.sh
```

This checks Terraform formatting and validation, Helm lint/template rendering, Kubernetes schema validation when `kubeconform` is installed, YAML syntax, secret scanning, and shell syntax.

## Disaster recovery

RDS automated backups, manual pre-deployment snapshots, S3 versioning/lifecycle policies, Redis snapshots, and cross-region backup procedures are documented in `disaster-recovery/plan.md` and `backups/README.md`.

## Scope boundary

This repository does not implement authentication, bookings, payments, notifications, chat, realtime behavior, API controllers, frontend code, database schemas, or UI assets. It only creates and configures the runtime that those repositories use.
