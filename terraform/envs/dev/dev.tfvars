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

# eks:CreateNodegroup is confirmed blocked on this playground - via API AND
# console, identical error both ways. Using Fargate as the compute layer
# instead (Fargate profile limits are explicitly documented in the
# playground's allowed-services list, unlike node groups).
create_node_group       = false
create_fargate_profiles = true
fargate_namespaces      = ["kube-system", "default"]

common_tags = {
  Owner       = "krushna"
  Project     = "finops-banking-platform"
  Environment = "dev"
  CostCenter  = "lab-dev"
}
