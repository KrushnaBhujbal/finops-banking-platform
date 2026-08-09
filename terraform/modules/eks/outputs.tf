output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  value = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

output "node_group_status" {
  value = var.create_node_group ? aws_eks_node_group.main[0].status : "not created - eks:CreateNodegroup blocked on this playground (confirmed via API and console)"
}

output "fargate_profile_names" {
  value = var.create_fargate_profiles ? [for p in aws_eks_fargate_profile.main : p.fargate_profile_name] : []
}

output "vpc_config_subnet_ids" {
  description = "Subnet IDs the cluster is using"
  value       = concat(var.private_subnet_ids, var.public_subnet_ids)
}
