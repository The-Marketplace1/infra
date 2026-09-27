variable "project" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

variable "rds_instance_id" {
  description = "RDS instance identifier for CloudWatch alarms"
  type        = string
}

variable "redis_replication_group_id" {
  description = "ElastiCache replication group ID for CloudWatch alarms"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS critical alert subscription (leave empty to skip)"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

