#!/bin/bash
# ================================================
# Inception-of-Things - BONUS
# Lightweight GitLab + ArgoCD Local Setup
# Author: rel-fila
# ================================================

set -e

CLUSTER_NAME="iot-cluster"
DOMAIN="localhost"
EMAIL="ridwaneelfilali@gmail.com"

echo "🚀 [1/8] Cleaning up any existing cluster..."
k3d cluster delete $CLUSTER_NAME || true

echo "🚀 [2/8] Creating new k3d cluster..."
k3d cluster create $CLUSTER_NAME \
  --api-port 6550 \
  --servers 1 \
  --agents 1 \
  --port "8888:30001@loadbalancer" \
  --port "8080:30002@loadbalancer" \
  --port "8082:30082@loadbalancer"

echo "🚀 [3/8] Creating namespaces..."
for ns in argocd gitlab dev; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
done

echo "🚀 [4/8] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD server to become ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd || true

echo "🔧 Exposing ArgoCD via NodePort..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8080,"nodePort":30002}]}}'

echo "🚀 [5/8] Installing GitLab (official Helm chart)..."
helm repo add gitlab https://charts.gitlab.io || true
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f gitlab-values.yaml \
  --timeout 600s \
  --set global.hosts.domain=$DOMAIN \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email=$EMAIL \
  --set global.edition=ce \
  --set global.time_zone="UTC" \
  --set postgresql.image.tag=16.4.0-debian-12-r13 \
  --set global.minio.enabled=false \
  --set global.appConfig.lfs.enabled=false \
  --set global.appConfig.registry.enabled=false \
  --set global.appConfig.pages.enabled=false \
  --set global.appConfig.smtp.enabled=false \
  --set prometheus.install=false \
  --set gitlab-runner.install=false \
  --set redis.master.resources.requests.memory=64Mi \
  --set redis.master.resources.limits.memory=128Mi \
  --set postgresql.primary.resources.requests.memory=128Mi \
  --set postgresql.primary.resources.limits.memory=256Mi \
  --set webservice.resources.requests.memory=512Mi \
  --set webservice.resources.limits.memory=1Gi

echo "⏳ Waiting for GitLab core services..."
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=900s || true

echo "🔧 Creating GitLab NodePort service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: gitlab-webservice-nodeport
  namespace: gitlab
spec:
  type: NodePort
  ports:
    - port: 8181
      targetPort: 8181
      nodePort: 30082
      protocol: TCP
  selector:
    app: webservice
    release: gitlab
EOF

echo "🚀 [6/8] Deploying your app (t2o-app)..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t2o-app
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: t2o-app
  template:
    metadata:
      labels:
        app: t2o-app
    spec:
      containers:
      - name: t2o-app
        image: broly20/flask-app-p3:v1
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: t2o-service
  namespace: dev
spec:
  selector:
    app: t2o-app
  type: NodePort
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30001
EOF

echo "🚀 [7/8] Creating ArgoCD Application for auto-deploy..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: t2o-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'http://gitlab-webservice.gitlab.svc.cluster.local:8181/root/t2o-app.git'
    targetRevision: main
    path: '.'
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "🚀 [8/8] Setup complete!"

echo
echo "======================================================="
echo "✅ Cluster setup complete!"
echo
echo "🌐 Your App:   http://localhost:8888"
echo "🌐 Argo CD UI: http://localhost:8080"
echo "🌐 GitLab UI:  http://localhost:8082"
echo
echo "🔑 ArgoCD Login:"
echo "   Username: admin"
echo "   Password: \$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'N/A')"
echo
echo "🔑 GitLab Login:"
echo "   Username: root"
echo "   Password: \$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'Still initializing...')"
echo
echo "======================================================="
