data "aws_caller_identity" "current" {}

variable "project" {
  type    = string
  default = "marketplace"
}

variable "environment" {
  type = string
}

variable "private_assets_bucket_arn" {
  description = "Private asset bucket ARN for scoped application storage access"
  type        = string
  default     = ""
}

variable "secret_arns" {
  description = "Secret ARNs explicitly approved for workload reads"
  type        = list(string)
  default     = []
}

variable "database_resource_id" {
  description = "RDS resource ID used for optional IAM database authentication"
  type        = string
  default     = ""
}

variable "database_username" {
  description = "Database username allowed to use IAM database authentication"
  type        = string
  default     = ""
}

variable "autoscaling_group_arns" {
  description = "Auto Scaling group ARNs that the cluster autoscaler may change"
  type        = list(string)
  default     = []
}

locals {
  name = "${var.project}-${var.environment}"
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid       = "TerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.project}-tfstate-${var.environment}",
      "arn:aws:s3:::${var.project}-tfstate-${var.environment}/*"
    ]
  }

  statement {
    sid       = "StateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = ["arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.project}-tfstate-${var.environment}-lock"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name   = "${local.name}-github-actions"
  policy = data.aws_iam_policy_document.github_actions.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid       = "ReadAutoScalingMetadata"
    effect    = "Allow"
    actions   = ["autoscaling:DescribeAutoScalingGroups", "autoscaling:DescribeAutoScalingInstances", "autoscaling:DescribeTags"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.autoscaling_group_arns) == 0 ? [] : [var.autoscaling_group_arns]
    content {
      sid       = "ChangeApprovedAutoScalingGroups"
      effect    = "Allow"
      actions   = ["autoscaling:SetDesiredCapacity", "autoscaling:TerminateInstanceInAutoScalingGroup"]
      resources = statement.value
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${local.name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "application_storage" {
  count = var.private_assets_bucket_arn == "" ? 0 : 1

  statement {
    sid       = "PrivateAssetObjectAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["${var.private_assets_bucket_arn}/*"]
  }
  statement {
    sid       = "PrivateAssetBucketMetadata"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.private_assets_bucket_arn]
  }
}

resource "aws_iam_policy" "application_storage" {
  count  = var.private_assets_bucket_arn == "" ? 0 : 1
  name   = "${local.name}-application-storage"
  policy = data.aws_iam_policy_document.application_storage[0].json
}

data "aws_iam_policy_document" "application_secrets" {
  count = length(var.secret_arns) == 0 ? 0 : 1

  statement {
    sid       = "ReadApprovedSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = var.secret_arns
  }
}

resource "aws_iam_policy" "application_secrets" {
  count  = length(var.secret_arns) == 0 ? 0 : 1
  name   = "${local.name}-application-secrets"
  policy = data.aws_iam_policy_document.application_secrets[0].json
}

data "aws_iam_policy_document" "database_connect" {
  count = var.database_resource_id == "" || var.database_username == "" ? 0 : 1

  statement {
    sid       = "ConnectToApprovedDatabaseUser"
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = [
      "arn:aws:rds-db:*:*:dbuser:${var.database_resource_id}/${var.database_username}"
    ]
  }
}

resource "aws_iam_policy" "database_connect" {
  count  = var.database_resource_id == "" || var.database_username == "" ? 0 : 1
  name   = "${local.name}-database-connect"
  policy = data.aws_iam_policy_document.database_connect[0].json
}

data "aws_iam_policy_document" "monitoring_read" {
  statement {
    sid       = "ReadInfrastructureTelemetry"
    effect    = "Allow"
    actions   = ["cloudwatch:GetMetricData", "cloudwatch:GetMetricStatistics", "cloudwatch:ListMetrics", "logs:DescribeLogGroups", "logs:FilterLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "monitoring_read" {
  name   = "${local.name}-monitoring-read"
  policy = data.aws_iam_policy_document.monitoring_read.json
}

output "github_actions_policy_arn" {
  value = aws_iam_policy.github_actions.arn
}

output "cluster_autoscaler_policy_arn" {
  value = aws_iam_policy.cluster_autoscaler.arn
}

output "application_storage_policy_arn" {
  value = try(aws_iam_policy.application_storage[0].arn, null)
}

output "application_secrets_policy_arn" {
  value = try(aws_iam_policy.application_secrets[0].arn, null)
}

output "database_connect_policy_arn" {
  value = try(aws_iam_policy.database_connect[0].arn, null)
}

output "monitoring_read_policy_arn" {
  value = aws_iam_policy.monitoring_read.arn
}
