################################################################################
# Secrets Module — AWS Secrets Manager + External Secrets Operator IRSA
################################################################################

locals {
  name = "${var.project}-${var.environment}"

  secret_names = [
    "database",
    "jwt",
    "payment",
    "twilio",
    "smtp",
    "redis",
    "api-keys",
  ]
}

################################################################################
# Secrets Manager containers only. Values are written out of band by the
# deployment/security process and are never represented in Terraform state.
################################################################################
resource "aws_secretsmanager_secret" "this" {
  for_each = toset(local.secret_names)

  name                    = "marketplace/${var.environment}/${each.key}"
  description             = "${each.key} credentials for marketplace ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = aws_kms_key.secrets.arn

  tags = merge(var.tags, { Name = "marketplace/${var.environment}/${each.key}" })
}

################################################################################
# KMS key for secrets
################################################################################
resource "aws_kms_key" "secrets" {
  description             = "${local.name} secrets encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${local.name}-secrets-kms" })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

################################################################################
# IRSA — External Secrets Operator
################################################################################
data "aws_iam_policy_document" "eso_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:external-secrets-operator"]
    }
  }
}

data "aws_iam_policy_document" "eso_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [for s in aws_secretsmanager_secret.this : s.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.arn]
  }
}

resource "aws_iam_role" "eso" {
  name               = "${local.name}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "eso" {
  name   = "${local.name}-eso-policy"
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso_policy.json
}

