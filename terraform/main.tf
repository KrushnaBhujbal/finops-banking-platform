module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints

  tags = var.common_tags
}

module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  cluster_name = var.cluster_name

  # Leave blank on first apply - EKS/OIDC don't exist yet.
  # After EKS module is added and applied, pass its outputs here to
  # unlock the per-domain IRSA roles.
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_domains = var.service_domains

  tags = var.common_tags
}
