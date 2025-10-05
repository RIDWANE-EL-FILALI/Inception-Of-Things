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
# Increase timeout and add better error handling
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

echo
echo "======================================================="
echo "✅ Cluster setup complete!"
echo
echo "🌐 Access your app at:   http://localhost:8888"
echo "🌐 Access Argo CD UI at: http://localhost:8080"
echo
echo "🔑 To get Argo CD admin password, run:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo
echo "📊 Check ArgoCD status:"
echo "kubectl get pods -n argocd"
echo "kubectl get applications -n argocd"
echo "======================================================="