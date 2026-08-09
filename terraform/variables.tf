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

# ---- EKS ----
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "node_instance_types" {
  description = "Playground allows only t2/t3 nano-micro-small-medium"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  description = "Playground hard cap: 3 nodes per node group"
  type        = number
  default     = 3
}

variable "create_node_group" {
  description = "eks:CreateNodegroup is blocked on this playground - keep false, use Fargate instead"
  type        = bool
  default     = false
}

variable "create_fargate_profiles" {
  description = "Create Fargate profiles as the compute layer instead of an EC2 node group"
  type        = bool
  default     = true
}

variable "fargate_namespaces" {
  description = "Namespaces scheduled onto Fargate. Playground hard cap: 3 profiles per cluster."
  type        = list(string)
  default     = ["kube-system", "default"]
}
