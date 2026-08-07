output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "domain_irsa_role_arns" {
  description = "Map of domain -> IRSA role ARN, empty until OIDC provider vars are supplied"
  value       = { for k, v in aws_iam_role.domain_irsa : k => v.arn }
}
