variable "state_project" {
  type    = string
  default = "marketplace"
}

variable "state_environment" {
  type = string
}

variable "state_region" {
  type    = string
  default = "us-east-1"
}

locals {
  state_name = "${var.state_project}-tfstate-${var.state_environment}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_name
  force_destroy = false
  tags          = { Environment = var.state_environment, ManagedBy = "Terraform", DataClass = "critical-configuration" }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.terraform_state.arn, "${aws_s3_bucket.terraform_state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    id     = "retain-state-history"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = 365 }
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${local.state_name}-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }
  tags = { Environment = var.state_environment, ManagedBy = "Terraform" }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "state_lock_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
