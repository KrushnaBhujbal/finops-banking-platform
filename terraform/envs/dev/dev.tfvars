environment          = "dev"
cluster_name         = "finops-eks"
vpc_cidr             = "10.0.0.0/16"
az_count             = 3
single_nat_gateway   = true
enable_vpc_endpoints = true

service_domains = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]

# ---- EKS ----
kubernetes_version  = "1.30"
node_instance_types = ["t3.small"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# Playground denies eks:CreateNodegroup via API/CLI consistently (confirmed
# across 2 separate accounts). Create the node group manually via the EKS
# console instead - see terraform/SESSION4-NODEGROUP-WORKAROUND.md.
create_node_group = false

common_tags = {
  Owner       = "krushna"
  Project     = "finops-banking-platform"
  Environment = "dev"
  CostCenter  = "lab-dev"
}
