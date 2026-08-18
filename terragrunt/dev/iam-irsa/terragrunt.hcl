include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_terragrunt_dir()}/../../../terraform/modules//iam-irsa"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/mock.eks.us-east-1.amazonaws.com/id/mock"
    oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/mock"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  environment       = "dev"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.oidc_provider_url

  service_domains = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]

  tags = {
    Owner       = "krushna"
    Project     = "finops-banking-platform"
    Environment = "dev"
    CostCenter  = "lab-dev"
  }
}
