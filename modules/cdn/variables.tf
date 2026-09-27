variable "project" { type = string }
variable "environment" { type = string }

variable "domain_name" {
  description = "Root domain (e.g. marketplace.example.com)"
  type        = string
}

variable "additional_domains" {
  description = "Extra SANs for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "s3_bucket_domain" {
  description = "S3 bucket regional domain name for CloudFront origin"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for Route53 alias records"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF WebACL ARN to attach to CloudFront"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}

