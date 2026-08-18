include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_terragrunt_dir()}/../../../terraform/modules//vpc"
}

inputs = {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  az_count             = 3
  single_nat_gateway   = true
  enable_vpc_endpoints = true

  tags = {
    Owner       = "krushna"
    Project     = "finops-banking-platform"
    Environment = "dev"
    CostCenter  = "lab-dev"
  }
}
