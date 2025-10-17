#!/bin/bash
set -e

CLUSTER_NAME="iot-cluster"

echo "[+] Deleting old cluster if exists..."
k3d cluster delete $CLUSTER_NAME || true

echo "[+] Creating new K3d cluster..."
k3d cluster create $CLUSTER_NAME \
  --api-port 6550 \
  --servers 1 \
  --agents 1 \
  --port "8888:30001@loadbalancer" \
  --port "8080:30002@loadbalancer"

echo "[+] Creating namespaces and deploying application..."
kubectl apply -f deployment.yaml

echo "[+] Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[+] Waiting for Argo CD to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd || {
    echo "⚠️  ArgoCD server taking longer than expected. Checking status..."
    kubectl get pods -n argocd
    kubectl describe deployment argocd-server -n argocd
    echo "Continuing with setup..."
}

echo "[+] Creating ArgoCD NodePort service..."
kubectl apply -f argocd-nodeport.yaml

echo "[+] Deploying Argo CD application..."
kubectl apply -f argocd-app.yaml

echo "[+] Waiting for application to sync..."
sleep 15

# =============================
# GITLAB INSTALLATION PART
# =============================
echo "[+] Creating namespace for GitLab (if not present)..."
kubectl get ns gitlab >/dev/null 2>&1 || kubectl create namespace gitlab

echo "[+] Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/ >/dev/null
helm repo update >/dev/null

echo "[+] Installing GitLab (lightweight mode)..."
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --wait \
  --timeout 900s \
  --set global.edition=ce \
  --set global.hosts.domain=localdomain \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.hosts.gitlab.name=gitlab.localdomain \
  --set certmanager.install=false \
  --set nginx-ingress.enabled=false \
  --set postgresql.install=true \
  --set gitlab-runner.install=false

echo "[+] Waiting for GitLab webservice to be ready (this may take a while)..."
kubectl -n gitlab wait --for=condition=available deployment/gitlab-webservice-default --timeout=900s || {
  echo "⚠️ GitLab webservice still starting... check pods manually with:"
  echo "kubectl get pods -n gitlab"
}

echo
echo "======================================================="
echo "✅ Cluster + GitLab setup complete!"
echo
echo "🌐 App URL:        http://localhost:8888"
echo "🌐 Argo CD UI:     http://localhost:8080"
echo "🌐 GitLab URL:     http://gitlab.localdomain"
echo
echo "🧩 ArgoCD login:"
echo "   Username: admin"
echo "   Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo)"
echo
echo "🧩 GitLab root password:"
echo "   $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d; echo)"
echo
echo "📊 Namespaces:"
kubectl get ns
echo
echo "📦 Pods summary:"
kubectl get pods -A
echo "======================================================="
