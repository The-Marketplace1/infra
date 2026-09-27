output "attachments_bucket_id" {
  value = aws_s3_bucket.attachments.id
}

output "attachments_bucket_arn" {
  value = aws_s3_bucket.attachments.arn
}

output "attachments_bucket_domain" {
  value = aws_s3_bucket.attachments.bucket_regional_domain_name
}

output "private_assets_bucket_arn" {
  value = aws_s3_bucket.attachments.arn
}

output "public_assets_bucket_id" {
  value = aws_s3_bucket.public_assets.id
}

output "public_assets_bucket_arn" {
  value = aws_s3_bucket.public_assets.arn
}

output "public_assets_bucket_domain" {
  value = aws_s3_bucket.public_assets.bucket_regional_domain_name
}

output "backups_bucket_id" {
  value = aws_s3_bucket.backups.id
}

output "backups_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}

output "logs_bucket_id" {
  value = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

output "storage_kms_key_arn" {
  value = aws_kms_key.storage.arn
}

