variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name - used in role/policy naming"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's OIDC provider - set after EKS module creates the cluster (leave blank on first apply, see README)"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL of the EKS cluster, without https:// prefix"
  type        = string
  default     = ""
}

variable "service_domains" {
  description = "List of microservice domains that need their own scoped IRSA role"
  type        = list(string)
  default     = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cluster_role_name" {
  type    = string
  default = "eksClusterRole"
}

variable "node_role_name" {
  type    = string
  default = "AmazonEKSNodeRole"
}