variable "project" { type = string }
variable "environment" { type = string }

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID to attach to the RDS instance"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "16.3"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "database_name" {
  type    = string
  default = "marketplace"
}

variable "required_extensions" {
  description = "Extensions the database repository must enable after provisioning"
  type        = list(string)
  default     = ["postgis", "postgis_topology", "pg_stat_statements"]
}

variable "master_username" {
  type      = string
  sensitive = true
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling ceiling (GiB)"
  type        = number
  default     = 100
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "create_read_replica" {
  type    = bool
  default = false
}

variable "replica_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "tags" {
  type    = map(string)
  default = {}
}

