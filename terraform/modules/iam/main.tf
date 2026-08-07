locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "finops-banking-platform"
    }
  )

  # IRSA roles need the OIDC provider, which only exists after the EKS
  # cluster is created. On the FIRST apply (cluster + node roles only),
  # leave oidc_provider_arn/url blank so this count evaluates to 0.
  # After the EKS module creates the cluster, re-apply with those values
  # filled in to create the per-domain IRSA roles.
  create_irsa_roles = var.oidc_provider_arn != "" && var.oidc_provider_url != ""
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
# Each microservice domain gets its own scoped role instead of sharing the
# node role - so payment-gateway-service can eventually get different AWS
# permissions than notification-service. Applied only after OIDC exists.
resource "aws_iam_role" "domain_irsa" {
  for_each = local.create_irsa_roles ? toset(var.service_domains) : toset([])

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
  for_each = local.create_irsa_roles ? toset(var.service_domains) : toset([])

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
