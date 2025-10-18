#!/bin/bash
set -e

# Create a local bin directory if it doesn't exist
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

echo "[+] Skipping system package updates (no sudo access)."

# -------------------------------
# Install Docker (rootless)
# -------------------------------
# echo "[+] Installing Rootless Docker..."

# # Install dependencies locally if needed
# curl -fsSL https://get.docker.com/rootless | sh

# # Export Docker environment variables
# export PATH=$HOME/bin:$PATH
# export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# echo "[+] Docker (rootless) installed."

# -------------------------------
# Install kubectl
# -------------------------------
echo "[+] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl ~/.local/bin/
echo "[+] kubectl installed to ~/.local/bin/kubectl"

# -------------------------------
# Install K3d (manual download)
# -------------------------------
echo "[+] Installing K3d (manual install)..."
K3D_VERSION=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o k3d
chmod +x k3d
mv k3d ~/.local/bin/
echo "[+] K3d installed to ~/.local/bin/k3d"


# -------------------------------
# Install Argo CD CLI
# -------------------------------
echo "[+] Installing Argo CD CLI..."
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
mv argocd ~/.local/bin/
echo "[+] Argo CD CLI installed to ~/.local/bin/argocd"

# -------------------------------
# Install Git (from source if needed)
# -------------------------------
echo "[+] Checking for Git..."
if ! command -v git &>/dev/null; then
  echo "[+] Git not found, installing from source (local)..."
  GIT_VERSION="2.45.2"
  curl -LO https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz
  tar -xzf git-${GIT_VERSION}.tar.gz
  cd git-${GIT_VERSION}
  make prefix=$HOME/.local all
  make prefix=$HOME/.local install
  cd ..
  rm -rf git-${GIT_VERSION}*
else
  echo "[+] Git already installed."
fi

# -------------------------------
# Done
# -------------------------------
echo "[+] All done!"
echo "Make sure ~/.local/bin is in your PATH:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
