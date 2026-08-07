terraform {
  backend "s3" {
    bucket       = "krushna-tfstate-lab-2026"
    key          = "eks-lab/dev/terraform.tfstate"
    region       = "us-east-1"
    profile      = "backend"
    use_lockfile = true
  }
}