include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_terragrunt_dir()}/../../../terraform/modules//eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id              = "vpc-mock00000000000000000"
    private_subnet_ids  = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
    public_subnet_ids   = ["subnet-mock4", "subnet-mock5", "subnet-mock6"]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

dependency "iam_base" {
  config_path = "../iam-base"

  mock_outputs = {
    cluster_role_arn = "arn:aws:iam::000000000000:role/mock-cluster-role"
    node_role_arn    = "arn:aws:iam::000000000000:role/mock-node-role"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  environment      = "dev"
  cluster_name     = "finops-eks"
  cluster_role_arn = dependency.iam_base.outputs.cluster_role_arn
  node_role_arn    = dependency.iam_base.outputs.node_role_arn

  vpc_id              = dependency.vpc.outputs.vpc_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  public_subnet_ids   = dependency.vpc.outputs.public_subnet_ids

  kubernetes_version = "1.30"

  node_instance_types = ["t3.small"]
  node_desired_size    = 2
  node_min_size        = 1
  node_max_size        = 3
  create_node_group    = false   # blocked by org SCP - confirmed in Session 4

  create_fargate_profiles = false # also blocked by the same SCP
  fargate_namespaces      = []

  tags = {
    Owner       = "krushna"
    Project     = "finops-banking-platform"
    Environment = "dev"
    CostCenter  = "lab-dev"
  }
}
