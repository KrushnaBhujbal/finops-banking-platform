# Local kind cluster - "On-Prem" Leg of the Hybrid Architecture

## Why this exists
The playground's EKS cluster is blocked from running any actual pods -
`eks:CreateNodegroup` and `eks:CreateFargateProfile` are both denied by
an org-level Service Control Policy (confirmed via API and console).
This isn't fixable from within the playground.

This kind cluster is where the ACTUAL hands-on workload practice happens:
Helm charts, ArgoCD GitOps, Prometheus/Grafana, the 32 dummy microservices,
and SLI/SLO dashboards all run here, on your own laptop, with zero AWS
restrictions.

The playground EKS cluster remains valuable for a different half of the
resume story: Terraform, VPC design, IAM/IRSA - the infrastructure-as-code
and cloud architecture side, which doesn't require pods to actually run.

## What this simulates
This cluster represents the "on-prem" or "local dev" leg of a hybrid
cloud/on-prem Kubernetes setup - a legitimate real-world pattern where
some workloads run in a managed cloud service and others run in
self-managed clusters (data centers, edge locations, or local dev/test).

## Cluster shape
- 1 control-plane node
- 2 worker nodes
- Ports 80/443 on the control-plane node are mapped to host ports
  8080/8443, so ingress-based services (ArgoCD UI, Grafana, etc.) are
  reachable at localhost without manual port-forwarding later.

## Commands
Create:
```bash
kind create cluster --config k8s-local-kind/kind-config.yaml
```

Verify:
```bash
kubectl get nodes
kubectl cluster-info --context kind-finops-onprem
```

Delete (when done for the session - kind clusters don't auto-persist
across laptop restarts the way cloud resources would, so recreate as
needed):
```bash
kind delete cluster --name finops-onprem
```

## Context switching
kind automatically adds a `kind-finops-onprem` context to your kubeconfig
and switches to it. To go back to the playground's EKS cluster later:
```bash
kubectl config get-contexts
kubectl config use-context <eks-context-name>
```
