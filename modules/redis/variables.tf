variable "project" { type = string }
variable "environment" { type = string }

variable "private_subnet_ids" {
  type = list(string)
}

variable "redis_security_group_id" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "7.1"
}

variable "node_type" {
  type    = string
  default = "cache.t3.small"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (2+ enables multi-AZ failover)"
  type        = number
  default     = 2
}

variable "snapshot_retention_limit" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}

