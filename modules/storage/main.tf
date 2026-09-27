################################################################################
# S3 Module — Object Storage (attachments, backups, logs)
################################################################################

locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_kms_key" "storage" {
  description             = "${local.name} object storage encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${local.name}-storage-kms" })
}

resource "aws_kms_alias" "storage" {
  name          = "alias/${local.name}-storage"
  target_key_id = aws_kms_key.storage.key_id
}

################################################################################
# Private assets bucket
# Prefix contract: verification/, profiles/, services/, communication/
################################################################################
resource "aws_s3_bucket" "attachments" {
  bucket        = "${local.name}-attachments-${var.aws_account_id}"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${local.name}-attachments" })
}

resource "aws_s3_bucket_ownership_controls" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "attachments" {
  bucket                  = aws_s3_bucket.attachments.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = var.cors_allowed_origins
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_logging" "attachments" {
  bucket        = aws_s3_bucket.attachments.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access/${local.name}/private-assets/"
}

resource "aws_s3_bucket_policy" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.attachments.arn, "${aws_s3_bucket.attachments.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  rule {
    id     = "expire-incomplete-multipart"
    status = "Enabled"
    filter { prefix = "" }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
  rule {
    id     = "transition-old-versions"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    noncurrent_version_expiration { noncurrent_days = var.private_asset_retention_days }
  }
  rule {
    id     = "verification-retention"
    status = "Enabled"
    filter { prefix = "verification/" }
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

################################################################################
# Public assets bucket
# Only approved public application/static assets belong here. Sensitive assets
# must never be written to this bucket.
################################################################################
resource "aws_s3_bucket" "public_assets" {
  bucket        = "${local.name}-public-assets-${var.aws_account_id}"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${local.name}-public-assets", DataClass = "public-approved-only" })
}

resource "aws_s3_bucket_ownership_controls" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "public_assets" {
  bucket                  = aws_s3_bucket.public_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "public_assets" {
  bucket        = aws_s3_bucket.public_assets.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access/${local.name}/public-assets/"
}

resource "aws_s3_bucket_policy" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.public_assets.arn, "${aws_s3_bucket.public_assets.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  rule {
    id     = "expire-incomplete-multipart"
    status = "Enabled"
    filter { prefix = "" }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = var.public_asset_retention_days }
  }
}

################################################################################
# Backups bucket
################################################################################
resource "aws_s3_bucket" "backups" {
  bucket        = "${local.name}-backups-${var.aws_account_id}"
  force_destroy = false
  tags          = merge(var.tags, { Name = "${local.name}-backups" })
}

resource "aws_s3_bucket_ownership_controls" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "backups" {
  bucket        = aws_s3_bucket.backups.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access/${local.name}/backups/"
}

resource "aws_s3_bucket_policy" "backups" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.backups.arn, "${aws_s3_bucket.backups.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    filter { prefix = "" }
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    expiration { days = 365 }
  }
}

################################################################################
# Logs bucket
################################################################################
resource "aws_s3_bucket" "logs" {
  bucket        = "${local.name}-logs-${var.aws_account_id}"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${local.name}-logs" })
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      # S3 server access logging delivery supports SSE-S3 without requiring
      # a KMS grant for the logging service principal.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.logs.arn, "${aws_s3_bucket.logs.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "AllowPrivateAssetLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/s3-access/${local.name}/private-assets/*"
        Condition = {
          ArnLike      = { "aws:SourceArn" = aws_s3_bucket.attachments.arn }
          StringEquals = { "aws:SourceAccount" = var.aws_account_id }
        }
      },
      {
        Sid       = "AllowPublicAssetLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/s3-access/${local.name}/public-assets/*"
        Condition = {
          ArnLike      = { "aws:SourceArn" = aws_s3_bucket.public_assets.arn }
          StringEquals = { "aws:SourceAccount" = var.aws_account_id }
        }
      },
      {
        Sid       = "AllowBackupLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/s3-access/${local.name}/backups/*"
        Condition = {
          ArnLike      = { "aws:SourceArn" = aws_s3_bucket.backups.arn }
          StringEquals = { "aws:SourceAccount" = var.aws_account_id }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter { prefix = "" }
    expiration { days = var.log_retention_days }
  }
}

