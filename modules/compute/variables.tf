variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node groups"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "system_node_instance_types" {
  description = "EC2 instance types for the system node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_desired" {
  type    = number
  default = 2
}

variable "system_node_min" {
  type    = number
  default = 2
}

variable "system_node_max" {
  type    = number
  default = 4
}

variable "app_node_instance_types" {
  description = "EC2 instance types for the application node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "app_node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "app_node_desired" {
  type    = number
  default = 3
}

variable "app_node_min" {
  type    = number
  default = 2
}

variable "app_node_max" {
  type    = number
  default = 20
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

