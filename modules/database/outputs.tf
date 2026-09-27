output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname (without port)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "kms_key_arn" {
  description = "KMS key ARN used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "replica_endpoint" {
  description = "Read replica endpoint (empty if not created)"
  value       = length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].endpoint : ""
}

output "required_extensions" {
  description = "Extensions reserved for the database repository to enable"
  value       = var.required_extensions
}

