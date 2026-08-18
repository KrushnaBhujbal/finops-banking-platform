include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_terragrunt_dir()}/../../../terraform/modules//iam-base"
}

inputs = {
  environment       = "dev"
  cluster_role_name = "eksClusterRole"
  node_role_name    = "AmazonEKSNodeRole"

  tags = {
    Owner       = "krushna"
    Project     = "finops-banking-platform"
    Environment = "dev"
    CostCenter  = "lab-dev"
  }
}
