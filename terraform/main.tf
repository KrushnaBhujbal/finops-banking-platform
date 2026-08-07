module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints

  tags = var.common_tags
}

module "eks" {
  source = "./modules/eks"

  environment      = var.environment
  cluster_name     = var.cluster_name
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  kubernetes_version  = var.kubernetes_version

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  tags = var.common_tags
}

module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  cluster_name = var.cluster_name

  # Wired directly to the eks module's outputs - Terraform's dependency graph
  # creates the cluster + OIDC provider first, then the IRSA roles, all in
  # one apply. No manual two-pass tfvars editing needed.
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  service_domains = var.service_domains

  tags = var.common_tags
}
