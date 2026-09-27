variable "project" { type = string }
variable "environment" { type = string }

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (for IRSA)"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where External Secrets Operator runs"
  type        = string
  default     = "external-secrets"
}

variable "recovery_window_in_days" {
  description = "Days before a deleted secret is permanently removed"
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}

