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
  --port "8888:30001@server:0" \
  --port "8080:30002@server:0"

echo "[+] Creating namespaces and deploying application..."
kubectl apply -f deployment.yaml

echo "[+] Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[+] Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

echo "[+] Creating ArgoCD NodePort service..."
kubectl apply -f argocd-nodeport.yaml

echo "[+] Deploying Argo CD application..."
kubectl apply -f argocd-app.yaml

echo "[+] Waiting for application to sync..."
sleep 10

echo
echo "======================================================="
echo "✅ K3d Cluster setup complete!"
echo
echo "🌐 App URL:        http://localhost:8888"
echo "🌐 Argo CD UI:     http://localhost:8080"
echo
echo "🧩 ArgoCD login:"
echo "   Username: admin"
echo "   Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo)"
echo
echo "📊 All Pods:"
kubectl get pods -A
echo
echo "======================================================="
echo
echo "ℹ️  To start GitLab VM:"
echo "   cd vagrant-gitlab"
echo "   vagrant up"
echo
echo "   GitLab will be available at http://localhost:8090"
echo "   (Initial startup takes ~10 minutes)"
echo "======================================================="