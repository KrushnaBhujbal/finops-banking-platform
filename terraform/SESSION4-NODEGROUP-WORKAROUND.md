# Node Group Workaround - Manual Console Creation

## Why
The playground's identity policy denies `eks:CreateNodegroup` via the
API/CLI. This was confirmed consistently across two separate playground
accounts (339712991953 and 140023394742) with identical error messages,
so it's a permanent restriction on this playground tier, not a fluke.

## What Terraform manages vs. what's manual
- Terraform: VPC, IAM (cluster/node roles, IRSA roles+policies), EKS
  cluster control plane, OIDC provider.
- Manual (console): the EKS managed node group only.

`create_node_group = false` in dev.tfvars keeps Terraform from attempting
the blocked API call. Everything else applies normally.

## Steps to create the node group manually
1. After `terraform apply`, run `terraform output vpc_config_subnet_ids`
   and `terraform output cluster_name` - copy these values.
2. AWS Console -> EKS -> Clusters -> (your cluster name) -> Compute tab
   -> Add node group.
3. Node group name: `dev-primary-nodes` (matches what Terraform would
   have named it, in case you later want to import it).
4. Node IAM role: select `AmazonEKSNodeRole` (already created by Terraform).
5. Subnets: select the PRIVATE subnets only (from the output above -
   don't include the public ones here, only the cluster's vpc_config
   needs those).
6. Instance type: t3.small (playground only allows t2/t3 nano-micro-small-medium).
7. Capacity type: On-Demand (playground does not allow Spot).
8. Scaling: min 1, desired 2, max 3 (playground hard cap: 3 nodes).
9. Create. Wait for status to show "Active" (a few minutes).

## Bringing it under Terraform management later (optional)
Once created manually, you can technically `terraform import` it so state
knows about it:
```bash
terraform import module.eks.aws_eks_node_group.main[0] finops-eks:dev-primary-nodes
```
This will likely also hit permission issues on subsequent applies/destroys
if the same policy blocks node group actions broadly (not just Create) -
treat this as optional, not required for the session to be productive.

## For your resume/interview story
This is a legitimate real-world pattern: some organizations' SCPs block
certain automated infrastructure actions and require console-based
creation with manual review - often for exactly the kind of environment
you're building (banking/FinOps, where change control matters). You can
speak to this as "identified an IAM restriction, worked around it with a
documented manual step, and structured the Terraform module so it degrades
gracefully via a feature flag" - which is a stronger story than everything
having gone smoothly.
