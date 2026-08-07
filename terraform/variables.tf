variable "environment" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "finops-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_vpc_endpoints" {
  type    = bool
  default = true
}

variable "oidc_provider_arn" {
  type    = string
  default = ""
}

variable "oidc_provider_url" {
  type    = string
  default = ""
}

variable "service_domains" {
  type    = list(string)
  default = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]
}

variable "common_tags" {
  type = map(string)
  default = {
    Owner   = "krushna"
    Project = "finops-banking-platform"
  }
}
