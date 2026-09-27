variable "project" {
  description = "Project name"
  type        = string
  default     = "marketplace"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type    = string
  default = ""
}

