################################################################################
# Environment: Development
################################################################################

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment  = "development"
  common_tags = {
    Project     = var.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Repository  = "marketplace-infrastructure"
  }
}

################################################################################
# VPC
################################################################################
module "vpc" {
  source = "../../modules/networking"

  project            = var.project
  environment        = local.environment
  vpc_cidr           = "10.10.0.0/16"
  az_count           = 2
  single_nat_gateway = true   # cost saving in dev
  tags               = local.common_tags
}

################################################################################
# EKS
################################################################################
module "eks" {
  source = "../../modules/compute"

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
  system_node_min            = 1
  system_node_max            = 3
  app_node_instance_types    = ["t3.large"]
  app_node_capacity_type     = "SPOT"
  app_node_desired           = 2
  app_node_min               = 1
  app_node_max               = 6
  tags                       = local.common_tags
}

################################################################################
# RDS
################################################################################
module "rds" {
  source = "../../modules/database"

  project               = var.project
  environment           = local.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  instance_class        = "db.t3.small"
  required_extensions   = ["postgis", "postgis_topology", "pg_stat_statements"]
  allocated_storage     = 20
  multi_az              = false
  deletion_protection   = false
  skip_final_snapshot   = true
  master_username       = var.db_username
  master_password       = var.db_password
  backup_retention_period = 1
  tags                  = local.common_tags
}

################################################################################
# Redis
################################################################################
module "redis" {
  source = "../../modules/redis"

  project                 = var.project
  environment             = local.environment
  private_subnet_ids      = module.vpc.private_subnet_ids
  redis_security_group_id = module.vpc.redis_security_group_id
  node_type               = "cache.t3.micro"
  num_cache_clusters      = 1
  tags                    = local.common_tags
}

################################################################################
# S3
################################################################################
module "s3" {
  source = "../../modules/storage"

  project        = var.project
  environment    = local.environment
  aws_account_id = var.aws_account_id
  force_destroy  = true
  tags           = local.common_tags
}

################################################################################
# Secrets
################################################################################
module "secrets" {
  source = "../../secrets"

  project           = var.project
  environment       = local.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  namespace         = "marketplace-dev"
  tags              = local.common_tags
}

################################################################################
# Monitoring
################################################################################
module "monitoring" {
  source = "../../modules/monitoring"

  project                    = var.project
  environment                = local.environment
  aws_region                 = var.aws_region
  rds_instance_id            = module.rds.instance_id
  redis_replication_group_id = module.redis.replication_group_id
  alert_email                = var.alert_email
  log_retention_days         = 7
  tags                       = local.common_tags
}

