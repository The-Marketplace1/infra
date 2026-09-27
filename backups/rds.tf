variable "environment" { type = string }
variable "rds_instance_id" { type = string }
variable "backup_vault_name" { type = string }
variable "object_storage_arns" {
  description = "S3 bucket ARNs requiring AWS Backup protection"
  type        = list(string)
  default     = []
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "backup_kms" {
  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowBackupServiceUse"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey*", "kms:ReEncrypt*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["backup.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_backup_vault" "rds" {
  name        = var.backup_vault_name
  kms_key_arn = aws_kms_key.backup.arn
  tags        = { Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_kms_key" "backup" {
  description             = "Marketplace ${var.environment} backup vault encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.backup_kms.json
  tags                    = { Environment = var.environment, ManagedBy = "Terraform" }
}

resource "aws_kms_alias" "backup" {
  name          = "alias/marketplace-${var.environment}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

resource "aws_iam_role" "backup" {
  name = "marketplace-${var.environment}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_plan" "rds" {
  name = "marketplace-${var.environment}-rds"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.rds.name
    schedule          = "cron(0 3 * * ? *)"
    start_window      = 60
    completion_window = 180
    lifecycle { delete_after = var.environment == "production" ? 90 : 14 }
  }
}

resource "aws_backup_selection" "rds" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "marketplace-${var.environment}-rds"
  plan_id      = aws_backup_plan.rds.id
  resources    = ["arn:aws:rds:*:*:db:${var.rds_instance_id}"]
}

resource "aws_backup_selection" "object_storage" {
  count        = length(var.object_storage_arns) == 0 ? 0 : 1
  iam_role_arn = aws_iam_role.backup.arn
  name         = "marketplace-${var.environment}-object-storage"
  plan_id      = aws_backup_plan.rds.id
  resources    = var.object_storage_arns
}

output "backup_plan_arn" {
  value = aws_backup_plan.rds.arn
}

output "backup_vault_arn" {
  value = aws_backup_vault.rds.arn
}
