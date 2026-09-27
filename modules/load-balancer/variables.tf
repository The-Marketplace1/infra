variable "project" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "certificate_arn" { type = string }

variable "target_ips" {
  description = "Private IPs registered by the ingress layer. Kubernetes-managed targets can be supplied by automation."
  type        = list(string)
  default     = []
}

variable "target_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
