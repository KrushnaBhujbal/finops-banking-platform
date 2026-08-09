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

# ---- Baseline permissions, as a customer-managed policy + attachment ----
# NOTE: tags removed here on purpose - the playground denies iam:TagPolicy
# even though iam:CreatePolicy itself is allowed. Tagging the ROLE (above)
# still works fine; it's specifically tagging a POLICY that's blocked.
resource "aws_iam_policy" "domain_baseline" {
  for_each = toset(var.service_domains)

  name        = "${var.environment}-${each.value}-baseline-policy"
  description = "Baseline CloudWatch Logs + S3 read permissions for ${each.value} domain services"

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

resource "aws_iam_role_policy_attachment" "domain_baseline" {
  for_each = toset(var.service_domains)

  role       = aws_iam_role.domain_irsa[each.value].name
  policy_arn = aws_iam_policy.domain_baseline[each.value].arn
}
