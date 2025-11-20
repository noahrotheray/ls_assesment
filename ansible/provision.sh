#!/usr/bin/env bash
set -euo pipefail

# ================================
# K3s Cluster Provisioning Script
# ================================
# This script will:
# 1. Run Ansible to provision server1
# 2. Remind you to capture the k3s token
# 3. Install ingress-nginx
# 4. Wait for nginx-admission webhook to be ready
# 5. Apply orchestration manifests

INVENTORY="inventory/prod"
PLAYBOOK="site.yml"
if [ $# -ne 1 ]; then
  echo "Usage: $0 <ansible-limit>"
  echo "Example: $0 server1"
  exit 1
fi

LIMIT="$1"

INGRESS_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml"
APP_MANIFEST="../k3s/app.yaml"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 1. Provision server with Ansible
log "Running Ansible playbook for ${LIMIT}..."
ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" --limit "${LIMIT}"

cat <<EOF

====================================================
IMPORTANT:
Take note of the k3s_token from the output above.
This token is required when joining worker nodes.
You can usually find it on the server at:
  /var/lib/rancher/k3s/server/node-token
====================================================

EOF

# 2. Install ingress-nginx
log "Installing ingress-nginx..."
kubectl apply -f "${INGRESS_URL}"

# 3. Wait for nginx-admission to become ready
log "Waiting for nginx-admission webhook to be ready..."
TIMEOUT=90
INTERVAL=5
ELAPSED=0

until kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "nginx-admission" && \
      kubectl get pods -n ingress-nginx | grep nginx-admission | grep -q "Running"; do
  sleep ${INTERVAL}
  ELAPSED=$((ELAPSED + INTERVAL))

  if [ ${ELAPSED} -ge ${TIMEOUT} ]; then
    log "Timeout reached (${TIMEOUT}s). Continuing anyway..."
    break
  fi

done

# 4. Apply orchestration manifests
log "Applying orchestration manifests..."
kubectl apply -f "${APP_MANIFEST}"

log "Provisioning complete ✅"
nohup xdg-open http://localhost