#!/bin/bash
# Minimal K3d cluster setup and deploy Argo CD + app
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


echo "[+] Applying namespaces..."
kubectl apply -f namespaces.yaml

echo "[+] Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[+] Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "[+] Creating ArgoCD NodePort service..."
kubectl apply -f argocd-nodeport.yaml

echo "[+] Deploying Argo CD application..."
kubectl apply -f argocd-app.yaml

echo "[+] Waiting for application to sync..."
sleep 15

# ArgoCD will be accessible via NodePort on localhost:8080



echo
echo "======================================================="
echo "✅ Cluster is ready!"
echo
echo "🌐 Access your app at:   http://localhost:8888"
echo "🌐 Access Argo CD UI at: https://localhost:8080"
echo
echo "🔑 To get Argo CD admin password, run:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo "======================================================="
