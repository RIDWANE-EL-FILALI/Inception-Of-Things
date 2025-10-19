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
  --port "8080:30002@loadbalancer" \
  --port "8082:30082@loadbalancer"

echo "[+] Creating namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "[+] Deploying base resources..."
kubectl apply -f deployment.yaml

echo "[+] Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[+] Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd || true

echo "[+] Creating Argo CD NodePort service..."
kubectl apply -f argocd-nodeport.yaml

echo "[+] Deploying Argo CD application..."
kubectl apply -f argocd-app.yaml

echo "[+] Installing GitLab Helm Chart..."
helm repo add gitlab https://charts.gitlab.io
helm repo update

# Install GitLab with proper configuration
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --create-namespace \
  --timeout 1800s \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=ridwaneelfilali@gmail.com \
  --set global.edition=ce \
  --set global.time_zone="UTC" \
  --set postgresql.image.tag=16.4.0-debian-12-r13 \
  --set postgresql.primary.resources.requests.memory=256Mi \
  --set postgresql.primary.resources.limits.memory=512Mi \
  --set redis.master.resources.requests.memory=128Mi \
  --set redis.master.resources.limits.memory=256Mi \
  --set gitlab-runner.resources.requests.memory=256Mi \
  --set gitlab-runner.resources.limits.memory=512Mi

echo "[+] Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready --timeout=600s pod/gitlab-postgresql-0 -n gitlab || {
  echo "⚠️  PostgreSQL pod failed. Checking status..."
  kubectl get pod gitlab-postgresql-0 -n gitlab
  kubectl describe pod gitlab-postgresql-0 -n gitlab | tail -30
  exit 1
}

echo "[+] Waiting for GitLab core services..."
kubectl wait --for=condition=ready --timeout=900s pod -l app=gitaly -n gitlab || true
kubectl wait --for=condition=ready --timeout=900s pod -l app=gitlab-shell -n gitlab || true

echo "[+] Waiting for GitLab webservice (this takes 10-15 minutes)..."
kubectl wait --for=condition=ready --timeout=900s pod -l app=webservice -n gitlab || true

echo "[+] Creating GitLab NodePort service..."
kubectl apply -f gitlab-nodeport.yaml

echo
echo "======================================================="
echo "✅ Cluster setup complete!"
echo
echo "🌐 Your App:   http://localhost:8888"
echo "🌐 Argo CD UI: http://localhost:8080"
echo "🌐 GitLab UI:  http://localhost:8082"
echo
echo "ArgoCD Login:"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'N/A')"
echo
echo "GitLab Login:"
echo "Username: root"
echo "Password: $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'Still initializing...')"
echo
echo "======================================================="