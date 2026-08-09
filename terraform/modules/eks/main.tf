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

# ---- Managed Node Group (kept for reference - blocked on this playground) ----
# eks:CreateNodegroup is denied for this identity via BOTH the API/CLI and
# the AWS console (confirmed with identical error messages both ways).
# create_node_group defaults to false. Using Fargate as the compute layer
# instead - see below.
resource "aws_eks_node_group" "main" {
  count = var.create_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-primary-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

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

# ---- Fargate Pod Execution Role ----
# Separate trust principal (eks-fargate-pods.amazonaws.com) and separate
# managed policy from the node role - required even though node groups
# aren't in use, because Fargate pods still need something to assume.
resource "aws_iam_role" "fargate_pod_execution" {
  count = var.create_fargate_profiles ? 1 : 0

  name = "${var.environment}-${var.cluster_name}-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  count = var.create_fargate_profiles ? 1 : 0

  role       = aws_iam_role.fargate_pod_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# ---- Fargate Profiles ----
# One profile per namespace in var.fargate_namespaces. kube-system is
# required for CoreDNS to schedule (otherwise DNS never comes up). Playground
# hard cap: 3 Fargate profiles per cluster - keep fargate_namespaces short.
resource "aws_eks_fargate_profile" "main" {
  for_each = var.create_fargate_profiles ? toset(var.fargate_namespaces) : toset([])

  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${var.environment}-${each.value}-fargate"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution[0].arn
  subnet_ids              = var.private_subnet_ids

  selector {
    namespace = each.value
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.value}-fargate"
  })

  depends_on = [aws_eks_cluster.main]
}
