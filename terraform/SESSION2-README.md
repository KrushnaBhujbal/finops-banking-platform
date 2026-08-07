# Terraform: VPC + IAM Modules (Session 2)

## What this creates
- **VPC module**: 3-AZ VPC with public/private/data subnets, NAT gateway(s),
  route tables, and optional S3 + ECR VPC endpoints (cuts NAT data-transfer
  cost — FinOps).
- **IAM module**: EKS cluster role, EKS node role, and per-domain IRSA
  roles (accounts/payments/risk/notifications/reporting/platform) so each
  microservice domain can eventually get scoped AWS permissions instead of
  sharing one blanket node role.

## Important: apply this in TWO passes

The IRSA roles need the EKS cluster's OIDC provider, which doesn't exist
until the EKS module (Session 4) creates the cluster. So:

**First apply (this session)** — leave `oidc_provider_arn` and
`oidc_provider_url` blank in `dev.tfvars` (already set that way). This
creates the VPC and the EKS cluster/node IAM roles only. The IRSA role
block will show 0 resources — that's expected, not an error.

```bash
cd terraform
terraform init
terraform validate
terraform plan -var-file=envs/dev/dev.tfvars
terraform apply -var-file=envs/dev/dev.tfvars
```

**Second apply (Session 4, after EKS module exists)** — fill in
`oidc_provider_arn` and `oidc_provider_url` in `dev.tfvars` with the
values output by the EKS module, then `terraform apply` again. This time
the per-domain IRSA roles get created.

## Before you run this on the playground
Swap in real playground values before applying:
- Confirm `providers.tf` (from Session 1) points the `aws` provider at
  the `playground` profile, and `backend.tf` points the S3 backend at
  the `backend` profile in your real account.
- No `<ACCOUNT_ID>` placeholders in this module - nothing here is
  account-specific yet, that only shows up in the ECR/Helm work later.

## Cost note
`single_nat_gateway = true` in dev.tfvars means one shared NAT Gateway
across all 3 AZs instead of three. This is intentional for lab cost/simplicity.
For a "closer to real prod" HA exercise later, flip it to `false` in a
`prod.tfvars` and compare the plan output - that's a good FinOps talking
point for interviews (single NAT = cost savings vs. per-AZ NAT = no
cross-AZ single point of failure).
