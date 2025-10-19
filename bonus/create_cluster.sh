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
  --port "8181:30003@loadbalancer"

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

echo "[+] Deploying GitLab (minimal configuration)..."
kubectl apply -f gitlab-deployment.yaml

echo "[+] Waiting for GitLab pod to start..."
kubectl wait --for=condition=ready --timeout=180s pod -l app=gitlab -n gitlab

echo "[+] GitLab is initializing (minimal mode - takes 3-5 minutes)..."
echo "    Waiting for services to start..."

# Wait for GitLab to be fully configured
MAX_ATTEMPTS=40
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if kubectl logs -n gitlab deployment/gitlab --tail=100 2>/dev/null | grep -q "gitlab Reconfigured"; then
        echo "✅ GitLab is ready!"
        sleep 5
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo "    Still initializing... ($ATTEMPT/$MAX_ATTEMPTS) - ~$((ATTEMPT * 10)) seconds"
    sleep 10
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "⚠️  GitLab is taking longer than expected but should be ready soon..."
    echo "    Check status with: kubectl logs -n gitlab deployment/gitlab"
fi

echo
echo "======================================================="
echo "✅ Cluster setup complete!"
echo
echo "🌐 Access your app at:   http://localhost:8888"
echo "🌐 Access Argo CD UI at: http://localhost:8080"
echo "🌐 Access Gitea at:      http://localhost:8181"
echo
echo "ArgoCD Credentials:"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)"
echo
echo "GitLab Credentials:"
echo "Username: root"
echo "Password: rootpassword123"
echo
echo "📊 Check status:"
echo "kubectl get pods -n argocd"
echo "kubectl get pods -n gitlab"
echo "kubectl get applications -n argocd"
echo "======================================================="