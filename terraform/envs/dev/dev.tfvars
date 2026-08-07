environment          = "dev"
cluster_name         = "finops-eks"
vpc_cidr             = "10.0.0.0/16"
az_count             = 3
single_nat_gateway   = true   # cost-saving for dev; set false in prod.tfvars for HA
enable_vpc_endpoints = true

service_domains = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]

# ---- EKS ----
kubernetes_version  = "1.30"
node_instance_types = ["t3.small"]   # playground: t2/t3 nano-micro-small-medium only
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3               # playground hard cap: 3 nodes per node group

common_tags = {
  Owner       = "krushna"
  Project     = "finops-banking-platform"
  Environment = "dev"
  CostCenter  = "lab-dev"
}
