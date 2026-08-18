variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "service_domains" {
  type    = list(string)
  default = ["accounts", "payments", "risk", "notifications", "reporting", "platform"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terragrunt"
    Project     = "finops-banking-platform"
  })
}

resource "aws_iam_role" "domain_irsa" {
  for_each = toset(var.service_domains)

  name = "${var.environment}-${each.value}-domain-irsa-role-tg"

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

# NOTE: "-tg" suffix on both the role and policy names below is intentional -
# an earlier session (non-Terragrunt, single-state) created policies named
# "dev-<domain>-baseline-policy" that this playground's identity can create
# but cannot delete (iam:DeletePolicy denied), so those names are permanently
# occupied in this AWS account. Suffixing avoids an EntityAlreadyExists
# collision. Tags omitted here too - iam:TagPolicy is also denied.
resource "aws_iam_policy" "domain_baseline" {
  for_each = toset(var.service_domains)

  name        = "${var.environment}-${each.value}-baseline-policy-tg"
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

output "domain_irsa_role_arns" {
  value = { for k, v in aws_iam_role.domain_irsa : k => v.arn }
}
