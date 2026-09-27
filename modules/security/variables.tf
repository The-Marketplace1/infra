variable "project" { type = string }
variable "environment" { type = string }

variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute window per IP before blocking"
  type        = number
  default     = 2000
}

variable "config_s3_bucket" {
   = "S3 bucket name for AWS Config delivery channel"
  type   description     = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

