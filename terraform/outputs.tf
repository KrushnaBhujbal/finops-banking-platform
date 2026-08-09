output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "node_group_status" {
  value = module.eks.node_group_status
}

output "fargate_profile_names" {
  value = module.eks.fargate_profile_names
}

output "domain_irsa_role_arns" {
  value = module.iam.domain_irsa_role_arns
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1 --profile playground"
}
