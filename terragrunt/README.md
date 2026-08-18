# Terragrunt Setup

## Install (one-time)
```bash
choco install terragrunt -y
# or
winget install Gruntwork.Terragrunt
terragrunt --version
```

## Structure
```
terragrunt/
  terragrunt.hcl          <- root: generates backend.tf + provider.tf for every unit
  dev/
    vpc/terragrunt.hcl      <- independent
    iam-base/terragrunt.hcl <- independent (cluster/node roles only)
    eks/terragrunt.hcl      <- depends on vpc + iam-base
    iam-irsa/terragrunt.hcl <- depends on eks (needs its OIDC output)
```

Each unit gets its OWN state file in the same S3 bucket, keyed by its
path (e.g. `dev/vpc/terraform.tfstate`, `dev/eks/terraform.tfstate`).

## Why IAM was split into iam-base and iam-irsa
The original single-state `iam` module worked because eks needs iam's
cluster/node role ARNs FIRST, then iam needs eks's OIDC output SECOND -
a resource-level ordering Terraform resolves fine within one state.
Terragrunt units are separate states, and a genuine cycle between two
units can't be expressed as a dependency block. Splitting into
`iam-base` (no eks dependency) and `iam-irsa` (depends on eks) turns
this into a clean DAG:

```
vpc ─┐
     ├─> eks ─> iam-irsa
iam-base ─┘
```

vpc and iam-base have no dependency on each other, so THIS is where
real parallelism happens - though honestly, both finish in seconds
regardless, since the slow parts (NAT Gateway ~2min, EKS cluster
~8-11min) are AWS-side latency on the eks unit specifically, which
still runs serially after vpc+iam-base finish. Terragrunt doesn't
change that; nothing can.

## Commands

Apply everything in correct dependency order (parallel where possible):
```bash
cd terragrunt
terragrunt run-all apply
```
Watch the output - you'll see `vpc` and `iam-base` start creating at
the same time, then `eks` waits for both, then `iam-irsa` waits for eks.

Plan everything first (recommended before your first real apply):
```bash
terragrunt run-all plan
```

Apply/plan a single unit:
```bash
cd dev/vpc
terragrunt apply
```

Destroy everything in REVERSE dependency order (iam-irsa first, vpc last):
```bash
cd terragrunt
terragrunt run-all destroy
```

## Note on create_node_group / create_fargate_profiles
Both are hardcoded false in dev/eks/terragrunt.hcl - confirmed blocked
by an org-level SCP in Session 4, not fixable. Compute layer is the
local kind cluster (k8s-local-kind/) instead.
