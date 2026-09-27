################################################################################
# Redis Module — ElastiCache (cluster mode disabled, multi-AZ)
################################################################################

locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${local.name}-redis-subnet-group"
  description = "ElastiCache subnet group for ${local.name}"
  subnet_ids  = var.private_subnet_ids
  tags        = merge(var.tags, { Name = "${local.name}-redis-subnet-group" })
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${local.name}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = ""
  }

  tags = var.tags
}

resource "random_password" "auth_token" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "marketplace/${var.environment}/redis"
  description             = "Redis auth token for ${local.name}"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    auth_token = random_password.auth_token.result
    host       = aws_elasticache_replication_group.this.primary_endpoint_address
    port       = 6379
  })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.name
  description          = "Redis cluster for ${local.name}"

  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.redis_security_group_id]

  engine_version              = var.engine_version
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token                  = random_password.auth_token.result
  automatic_failover_enabled  = var.num_cache_clusters > 1
  multi_az_enabled            = var.num_cache_clusters > 1

  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_window          = "04:00-05:00"
  snapshot_retention_limit = var.snapshot_retention_limit

  auto_minor_version_upgrade = true
  apply_immediately          = false

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = merge(var.tags, { Name = local.name })
}

resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/marketplace/${var.environment}/redis/slow-log"
  retention_in_days = 14
  tags              = var.tags
}

