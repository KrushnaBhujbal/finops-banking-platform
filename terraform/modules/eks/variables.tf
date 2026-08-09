variable "environment" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "finops-eks"
}

variable "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role (eksClusterRole), from module.iam"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the EKS node IAM role (AmazonEKSNodeRole), from module.iam"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Subnets where worker nodes / Fargate pods run"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Included in cluster vpc_config so the control plane can also attach ENIs here if needed"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.30"
}

# --- Playground constraint: t2/t3 nano-micro-small-medium ONLY, max 3 nodes per group ---
variable "node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
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
  description = "Playground hard cap is 3 nodes per node group - do not exceed"
  type        = number
  default     = 3
}

variable "create_node_group" {
  description = "Set false when eks:CreateNodegroup is blocked (confirmed blocked on this playground, console included). Use Fargate instead."
  type        = bool
  default     = false
}

# ---- Fargate (compute alternative since EC2 node groups are blocked) ----
variable "create_fargate_profiles" {
  description = "Create Fargate profiles as the compute layer instead of a managed node group"
  type        = bool
  default     = true
}

variable "fargate_namespaces" {
  description = "Namespaces that get scheduled onto Fargate. kube-system is required so CoreDNS can run. Playground hard cap: 3 Fargate profiles per cluster."
  type        = list(string)
  default     = ["kube-system", "default"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
