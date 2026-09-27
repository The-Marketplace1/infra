################################################################################
# Monitoring Module — CloudWatch, SNS, Alarms
################################################################################

locals {
  name = "${var.project}-${var.environment}"
}

################################################################################
# SNS Topics for alerting
################################################################################
resource "aws_sns_topic" "critical" {
  name              = "${local.name}-critical"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_sns_topic" "warning" {
  name              = "${local.name}-warning"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "critical_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

################################################################################
# CloudWatch Log Groups
################################################################################
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.name}/cluster"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/marketplace/${var.environment}/application"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

################################################################################
# CloudWatch Alarms — RDS
################################################################################
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilisation > 80% for 15 minutes"
  alarm_actions       = [aws_sns_topic.critical.arn]
  ok_actions          = [aws_sns_topic.critical.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120   # 5 GB in bytes
  alarm_description   = "RDS free storage < 5 GB"
  alarm_actions       = [aws_sns_topic.critical.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 400
  alarm_description   = "RDS connections > 400"
  alarm_actions       = [aws_sns_topic.warning.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.tags
}

################################################################################
# CloudWatch Alarms — ElastiCache
################################################################################
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${local.name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Redis CPU > 70% for 15 minutes"
  alarm_actions       = [aws_sns_topic.warning.arn]

  dimensions = {
    ReplicationGroupId = var.redis_replication_group_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${local.name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis memory > 80%"
  alarm_actions       = [aws_sns_topic.critical.arn]

  dimensions = {
    ReplicationGroupId = var.redis_replication_group_id
  }

  tags = var.tags
}

################################################################################
# CloudWatch Dashboard
################################################################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "RDS CPU"
          region = var.aws_region
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Redis CPU"
          region = var.aws_region
          metrics = [["AWS/ElastiCache", "EngineCPUUtilization", "ReplicationGroupId", var.redis_replication_group_id]]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
        }
      },
    ]
  })
}

