output "secret_arns" {
  description = "Map of secret name to ARN"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt secrets"
  value       = aws_kms_key.secrets.arn
}

output "eso_role_arn" {
  description = "IAM role ARN for the External Secrets Operator"
  value       = aws_iam_role.eso.arn
}

output "secret_names" {
  description = "Secret names that must be populated out of band"
  value       = sort(local.secret_names)
}

