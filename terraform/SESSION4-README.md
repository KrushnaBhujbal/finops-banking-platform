# Terraform: EKS Module (Session 4)

## What changed from Session 2
- Added `modules/eks/` - cluster, OIDC provider, one managed node group.
- `main.tf` now wires `module.iam`'s OIDC inputs DIRECTLY to `module.eks`'s
  outputs. No more manual two-pass tfvars editing - Terraform's dependency
  graph creates cluster -> OIDC provider -> IRSA roles automatically, in
  the correct order, in a single `apply`.
- `dev.tfvars` - removed the old blank `oidc_provider_arn`/`oidc_provider_url`
  lines (no longer declared as root variables) and added EKS sizing values.

## Playground constraints this module respects
- Node instance types: t3.small (t2/t3 nano-micro-small-medium allowed only)
- `capacity_type = "ON_DEMAND"` - playground does not allow Spot Instances
- `node_max_size = 3` - playground hard cap on nodes per node group
- Cluster/node IAM roles reused from Session 2, named exactly
  `eksClusterRole` / `AmazonEKSNodeRole` as the playground requires
- NOT yet enforced by this module (matters once you deploy workloads,
  not for cluster creation itself):
  - Max 256 millicores / 512 MiB per pod
  - Max 3 pods per namespace
  - Cumulative cluster cap: 2000m CPU / 4096 MiB memory
  - Account-wide cap: 6000m CPU / 12288 MiB memory
  Keep these in mind in the Helm session - your `resources.requests/limits`
  in the generic-microservice chart need to respect these caps once you
  start deploying the 32 dummy services onto this cluster.

## Apply
```bash
cd terraform
terraform init          # picks up the new eks module + tls provider
terraform validate
terraform plan -var-file=envs/dev/dev.tfvars
terraform apply -var-file=envs/dev/dev.tfvars
```

Expect this to take 10-15 minutes - EKS control plane provisioning alone
is typically 8-11 minutes, node group join adds a few more.

## Verify
```bash
terraform output configure_kubectl
# run the printed command, then:
kubectl get nodes
kubectl get pods -A
```

Check the IRSA roles actually got created this time (Session 2 showed 0):
```bash
terraform output domain_irsa_role_arns
```
Should show 6 ARNs, one per domain.

## Teardown
```bash
terraform destroy -var-file=envs/dev/dev.tfvars
```
Node group deletion + cluster deletion together typically take 10+ minutes -
budget more time for destroy than you did in Session 2.
