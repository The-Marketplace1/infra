################################################################################
# Environment: Staging
################################################################################

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
    tls    = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

locals {
  environment = "staging"
  common_tags = {
    Project     = var.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Repository  = "marketplace-infrastructure"
  }
}

module "vpc" {
  source             = "../../modules/networking"
  project            = var.project
  environment        = local.environment
  vpc_cidr           = "10.20.0.0/16"
  az_count           = 2
  single_nat_gateway = false
  tags               = local.common_tags
}

module "eks" {
  source                     = "../../modules/compute"
  project                    = var.project
  environment                = local.environment
  kubernetes_version         = "1.29"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  node_security_group_id     = module.vpc.node_security_group_id
  endpoint_public_access     = true
  system_node_instance_types = ["t3.medium"]
  system_node_desired        = 2
  system_node_min            = 2
  system_node_max            = 4
  app_node_instance_types    = ["t3.large"]
  app_node_capacity_type     = "ON_DEMAND"
  app_node_desired           = 3
  app_node_min               = 2
  app_node_max               = 10
  tags                       = local.common_tags
}

module "rds" {
  source                  = "../../modules/database"
  project                 = var.project
  environment             = local.environment
  private_subnet_ids      = module.vpc.private_subnet_ids
  rds_security_group_id   = module.vpc.rds_security_group_id
  instance_class          = "db.t3.medium"
  required_extensions     = ["postgis", "postgis_topology", "pg_stat_statements"]
  allocated_storage       = 50
  multi_az                = true
  deletion_protection     = true
  skip_final_snapshot     = false
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 7
  tags                    = local.common_tags
}

module "redis" {
  source                  = "../../modules/redis"
  project                 = var.project
  environment             = local.environment
  private_subnet_ids      = module.vpc.private_subnet_ids
  redis_security_group_id = module.vpc.redis_security_group_id
  node_type               = "cache.t3.small"
  num_cache_clusters      = 2
  tags                    = local.common_tags
}

module "s3" {
  source         = "../../modules/storage"
  project        = var.project
  environment    = local.environment
  aws_account_id = var.aws_account_id
  force_destroy  = false
  tags           = local.common_tags
}

module "secrets" {
  source            = "../../secrets"
  project           = var.project
  environment       = local.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  namespace         = "marketplace-staging"
  tags              = local.common_tags
}

module "security" {
  source           = "../../modules/security"
  project          = var.project
  environment      = local.environment
  config_s3_bucket = module.s3.logs_bucket_id
  tags             = local.common_tags
}

module "load_balancer" {
  source             = "../../modules/load-balancer"
  project            = var.project
  environment        = local.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.vpc.alb_security_group_id
  certificate_arn    = var.certificate_arn
  deletion_protection = false
  tags               = local.common_tags
}

module "cdn" {
  source           = "../../modules/cdn"
  project          = var.project
  environment      = local.environment
  domain_name      = var.domain_name
  s3_bucket_domain = module.s3.public_assets_bucket_domain
  alb_dns_name     = module.load_balancer.dns_name
  alb_zone_id      = module.load_balancer.zone_id
  waf_web_acl_arn  = module.security.waf_web_acl_arn
  tags             = local.common_tags
}

module "monitoring" {
  source                     = "../../modules/monitoring"
  project                    = var.project
  environment                = local.environment
  aws_region                 = var.aws_region
  rds_instance_id            = module.rds.instance_id
  redis_replication_group_id = module.redis.replication_group_id
  alert_email                = var.alert_email
  log_retention_days         = 30
  tags                       = local.common_tags
}

