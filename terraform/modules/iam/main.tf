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

# ---- EKS Cluster Role ----
resource "aws_iam_role" "eks_cluster" {
  name = var.cluster_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---- EKS Node Group Role ----
resource "aws_iam_role" "eks_nodes" {
  name = var.node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---- Per-domain IRSA roles (accounts, payments, risk, etc.) ----
# for_each keys off var.service_domains directly (static, known at plan
# time). The OIDC arn/url used INSIDE the trust policy are allowed to be
# "known after apply" - only the for_each KEY SET must be knowable upfront.
# This is what fixes the "Invalid for_each argument" error: the previous
# version tried to gate the key set itself on module.eks's output, which
# doesn't exist until the cluster is created.
resource "aws_iam_role" "domain_irsa" {
  for_each = toset(var.service_domains)

  name = "${var.environment}-${each.value}-domain-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${each.value}:${each.value}-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Domain = each.value })
}

# Baseline policy per domain - CloudWatch Logs + read-only S3 for now.
# Tighten or extend per domain as each service's real needs become clear.
resource "aws_iam_role_policy" "domain_baseline" {
  for_each = toset(var.service_domains)

  name = "${each.value}-baseline-policy"
  role = aws_iam_role.domain_irsa[each.value].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/finops/${each.value}*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.environment}-finops-*/*"
      }
    ]
  })
}
