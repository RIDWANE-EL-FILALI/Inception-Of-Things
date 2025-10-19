#!/bin/bash
# Minimal dependencies installer for K3d + Argo CD
set -e

echo "[+] Updating packages..."
sudo apt update -y && sudo apt upgrade -y

echo "[+] Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "[+] Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "[+] Installing Argo CD CLI..."
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

echo "[+] Installing Git..."
sudo apt install -y git

echo "[+] All done!"
