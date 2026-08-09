locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "finops-banking-platform"
    }
  )
}

# ---- EKS Cluster (control plane) ----
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(local.common_tags, {
    Name = var.cluster_name
  })
}

# ---- OIDC provider (unlocks IRSA - required for module.iam's per-domain roles) ----
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# ---- Managed Node Group ----
# Optional via create_node_group: the playground consistently denies
# eks:CreateNodegroup via the API/CLI regardless of account. When that
# happens, set create_node_group = false, apply everything else via
# Terraform, then create the node group manually through the EKS console
# (console actions appear to run through a different, more permissive
# path than programmatic API calls on this playground).
resource "aws_eks_node_group" "main" {
  count = var.create_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-primary-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND" # playground doc: no Spot Instances allowed

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-primary-nodes"
  })

  depends_on = [aws_eks_cluster.main]
}
