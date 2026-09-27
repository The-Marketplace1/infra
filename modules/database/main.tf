################################################################################
# RDS Module — PostgreSQL (Multi-AZ)
################################################################################

locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_db_subnet_group" "this" {
  name        = "${local.name}-rds-subnet-group"
  description = "RDS subnet group for ${local.name}"
  subnet_ids  = var.private_subnet_ids
  tags        = merge(var.tags, { Name = "${local.name}-rds-subnet-group" })
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.name}-pg16"
  family      = "postgres16"
  description = "Custom parameter group for ${local.name}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"   # log queries > 1s
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = var.tags
}

resource "aws_kms_key" "rds" {
  description             = "${local.name} RDS encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${local.name}-rds-kms" })
}

resource "aws_db_instance" "this" {
  identifier = local.name

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final-snapshot"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true

  tags = merge(var.tags, { Name = local.name })
}

################################################################################
# Enhanced monitoring role
################################################################################
data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "${local.name}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Read replica (production only)
################################################################################
resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  identifier             = "${local.name}-replica"
  replicate_source_db    = aws_db_instance.this.identifier
  instance_class         = var.replica_instance_class
  publicly_accessible    = false
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  auto_minor_version_upgrade = true
  tags                       = merge(var.tags, { Name = "${local.name}-replica" })
}

