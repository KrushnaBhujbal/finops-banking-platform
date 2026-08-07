environment          = "dev"
cluster_name         = "finops-eks"
vpc_cidr             = "10.0.0.0/16"
az_count             = 3
single_nat_gateway   = true   # cost-saving for dev; set false in prod.tfvars for HA
enable_vpc_endpoints = true

# leave blank for the first apply - fill in after EKS module exists
oidc_provider_arn = ""
oidc_provider_url = ""

service_domains = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]

common_tags = {
  Owner       = "krushna"
  Project     = "finops-banking-platform"
  Environment = "dev"
  CostCenter  = "lab-dev"
}
