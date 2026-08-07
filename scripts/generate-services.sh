#!/usr/bin/env bash
#
# Generates the per-service folder, Helm values override, and ArgoCD
# Application manifest for every service listed in microservices/services.txt.
#
# Usage:
#   ./scripts/generate-services.sh <env> <repo_url>
#
# Example:
#   ./scripts/generate-services.sh dev https://github.com/KrushnaBhujbal/finops-banking-platform.git

set -euo pipefail

ENVIRONMENT="${1:-dev}"
REPO_URL="${2:-https://github.com/KrushnaBhujbal/finops-banking-platform.git}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_FILE="${ROOT_DIR}/microservices/services.txt"
TEMPLATE_DIR="${ROOT_DIR}/microservices/templates/generic-service"
VALUES_DIR="${ROOT_DIR}/helm/values/${ENVIRONMENT}"
ARGOCD_APPS_DIR="${ROOT_DIR}/argocd/applications"
APP_TEMPLATE="${ROOT_DIR}/argocd/application-template.yaml"

mkdir -p "${VALUES_DIR}" "${ARGOCD_APPS_DIR}"

count=0

while IFS=':' read -r domain service; do
  [ -z "$service" ] && continue

  SERVICE_DIR="${ROOT_DIR}/microservices/${service}"

  # 1. Stamp out the service folder from the generic template
  mkdir -p "${SERVICE_DIR}"
  cp "${TEMPLATE_DIR}/app.py" "${SERVICE_DIR}/app.py"
  cp "${TEMPLATE_DIR}/requirements.txt" "${SERVICE_DIR}/requirements.txt"
  cp "${TEMPLATE_DIR}/Dockerfile" "${SERVICE_DIR}/Dockerfile"

  # 2. Generate a Helm values override for this service + environment
  cat > "${VALUES_DIR}/${service}.yaml" <<EOF
serviceName: ${service}
serviceDomain: ${domain}
environment: ${ENVIRONMENT}

image:
  repository: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/${service}
  tag: latest

# tweak per service to create realistic SLI variation across the fleet
errorRate: "0.02"
minLatencyMs: "20"
maxLatencyMs: "180"
EOF

  # 3. Generate the ArgoCD Application manifest for this service
  sed -e "s|__SERVICE_NAME__|${service}|g" \
      -e "s|__DOMAIN__|${domain}|g" \
      -e "s|__ENV__|${ENVIRONMENT}|g" \
      -e "s|__REPO_URL__|${REPO_URL}|g" \
      "${APP_TEMPLATE}" > "${ARGOCD_APPS_DIR}/${service}-app.yaml"

  count=$((count + 1))
  echo "generated: ${service} (domain=${domain})"
done < "${SERVICES_FILE}"

echo ""
echo "Done. Generated ${count} services for environment '${ENVIRONMENT}'."
echo "  - Service code:      microservices/<service-name>/"
echo "  - Helm values:       helm/values/${ENVIRONMENT}/<service-name>.yaml"
echo "  - ArgoCD Apps:       argocd/applications/<service-name>-app.yaml"
