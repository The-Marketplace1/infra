variable "project" { type = string }
variable "environment" { type = string }

variable "aws_account_id" {
  description = "AWS account ID — appended to bucket names for global uniqueness"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Explicitly approved origins for private asset uploads"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention period for logs bucket objects (days)"
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow Terraform to destroy non-empty buckets (dev only)"
  type        = bool
  default     = false
}

variable "private_asset_retention_days" {
  description = "Retention for noncurrent private asset versions"
  type        = number
  default     = 365
}

variable "public_asset_retention_days" {
  description = "Retention for noncurrent public asset versions"
  type        = number
  default     = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}

