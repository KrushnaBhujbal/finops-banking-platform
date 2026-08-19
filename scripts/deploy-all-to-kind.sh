#!/usr/bin/env bash
#
# Builds a local Docker image, loads it into kind, and helm-installs every
# service listed in microservices/services.txt onto the local kind cluster.
#
# Usage:
#   ./scripts/deploy-all-to-kind.sh
#
# Safe to re-run: skips the build+load+install for any service already
# deployed and healthy, so you can re-run after fixing a single failure
# without rebuilding everything.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_FILE="${ROOT_DIR}/microservices/services.txt"
CLUSTER_NAME="finops-onprem"

success_count=0
fail_count=0
skip_count=0
failed_services=()

echo "=== Deploying all services to kind cluster '${CLUSTER_NAME}' ==="
echo ""

while IFS=':' read -r domain service; do
  [ -z "$service" ] && continue

  echo "--- ${service} (domain: ${domain}) ---"

  # Skip if already deployed and running
  existing_status=$(kubectl get pods -n "${domain}" -l app="${service}" \
    -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "${existing_status}" == "Running" ]; then
    echo "  already Running, skipping"
    skip_count=$((skip_count + 1))
    echo ""
    continue
  fi

  # Ensure the namespace exists
  kubectl get namespace "${domain}" >/dev/null 2>&1 || kubectl create namespace "${domain}"

  # Build
  if ! docker build -q -t "${service}:local" "${ROOT_DIR}/microservices/${service}" > /tmp/build_${service}.log 2>&1; then
    echo "  BUILD FAILED - see /tmp/build_${service}.log"
    fail_count=$((fail_count + 1))
    failed_services+=("${service} (build)")
    echo ""
    continue
  fi

  # Load into kind
  if ! kind load docker-image "${service}:local" --name "${CLUSTER_NAME}" > /tmp/load_${service}.log 2>&1; then
    echo "  KIND LOAD FAILED - see /tmp/load_${service}.log"
    fail_count=$((fail_count + 1))
    failed_services+=("${service} (kind load)")
    echo ""
    continue
  fi

  # Helm install (or upgrade if it already exists in a failed state)
  helm upgrade --install "${service}" "${ROOT_DIR}/helm/charts/generic-microservice" \
    -f "${ROOT_DIR}/helm/values/dev/${service}.yaml" \
    --set image.repository="${service}" \
    --set image.tag=local \
    --set image.pullPolicy=Never \
    --set serviceMonitor.enabled=false \
    -n "${domain}" > /tmp/helm_${service}.log 2>&1

  if [ $? -ne 0 ]; then
    echo "  HELM INSTALL FAILED - see /tmp/helm_${service}.log"
    fail_count=$((fail_count + 1))
    failed_services+=("${service} (helm)")
    echo ""
    continue
  fi

  echo "  deployed"
  success_count=$((success_count + 1))
  echo ""

done < "${SERVICES_FILE}"

echo "=== Summary ==="
echo "  Deployed:        ${success_count}"
echo "  Already running: ${skip_count}"
echo "  Failed:          ${fail_count}"

if [ ${#failed_services[@]} -gt 0 ]; then
  echo ""
  echo "Failed services (check /tmp/*_<service>.log for details):"
  for f in "${failed_services[@]}"; do
    echo "  - $f"
  done
fi

echo ""
echo "Check overall status with:"
echo "  kubectl get pods -A | grep -v kube-system"
