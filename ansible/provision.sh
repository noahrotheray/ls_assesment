#!/usr/bin/env bash
set -euo pipefail

# ================================
# K3s Cluster Provisioning Script
# ================================
# This script will:
# 1. Run Ansible to provision server1
# 2. Install ingress-nginx
# 3. Wait for nginx-admission webhook to be ready
# 4. Apply orchestration manifests

INVENTORY="inventory/prod"
PLAYBOOK="site.yml"
LIMIT="server1"

INGRESS_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml"
MANIFEST="../k3s/app.yaml"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 1. Provision server
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

# 3. Wait for nginx controller to become ready
log "Waiting for nginx controller to be ready..."
TIMEOUT=120
INTERVAL=15
ELAPSED=0

until kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "ingress-nginx-controller" && \
      kubectl get pods -n ingress-nginx | grep ingress-nginx-controller | grep -q "Running"; do
  sleep ${INTERVAL}
  ELAPSED=$((ELAPSED + INTERVAL))

  if [ ${ELAPSED} -ge ${TIMEOUT} ]; then
    log "Timeout reached (${TIMEOUT}s). Continuing anyway..."
    break
  fi

done
log "Make sure nginx is running..." # Even though the pod is 'Running', its not accepting new ingresses yet.
sleep 10

# 4. Apply manifests.
log "Applying orchestration manifests..."
kubectl apply -f "${MANIFEST}"
log "Give it a second..." # nginx reloads after config changes
sleep 10
log "Provisioning complete ✅"
