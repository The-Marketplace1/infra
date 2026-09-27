output "primary_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Redis reader endpoint address"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = 6379
}

output "auth_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

