# Inception of Things - Part 1: K3s with Vagrant

## Overview
Set up a 2-node Kubernetes cluster using K3s and Vagrant. This lightweight setup provides hands-on experience with Kubernetes fundamentals while using minimal resources.

## Architecture
```
Host Machine (192.168.56.1)
├── rel-filaS (Server)    - 192.168.56.110 - K3s Control Plane
└── rel-filaSW (Worker)   - 192.168.56.111 - K3s Agent
```

## Requirements
- VirtualBox
- Vagrant
- 2GB+ available RAM
- 2 CPU cores

## Quick Start
1. Clone/create project directory
2. Add the Vagrantfile
3. Run: `vagrant up`
4. SSH into server: `vagrant ssh rel-filaS`
5. Check cluster: `kubectl get nodes`

## Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  # Server Node - K3s Control Plane
  config.vm.define "rel-filaS" do |server|
    server.vm.box = "ubuntu/focal64"
    server.vm.hostname = "rel-filaS"
    server.vm.network "private_network", ip: "192.168.56.110"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    server.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      curl -sfL https://get.k3s.io | sh -
      sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
    SHELL
  end
  
  # Worker Node - K3s Agent
  config.vm.define "rel-filaSW" do |worker|
    worker.vm.box = "ubuntu/focal64"
    worker.vm.hostname = "rel-filaSW"
    worker.vm.network "private_network", ip: "192.168.56.111"
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end
    worker.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      while [ ! -f /vagrant/node-token ]; do sleep 2; done
      curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$(cat /vagrant/node-token) sh -
    SHELL
  end
end
```

## How It Works
1. **Server Provisioning**: Installs K3s control plane and saves join token
2. **Worker Provisioning**: Waits for token, then joins cluster as agent
3. **Automatic Setup**: No manual configuration needed

## Verification Commands
```bash
# Check cluster status
vagrant ssh rel-filaS -c "kubectl get nodes"

# View all pods
vagrant ssh rel-filaS -c "kubectl get pods -A"

# Check K3s services
vagrant ssh rel-filaS -c "sudo systemctl status k3s"
vagrant ssh rel-filaSW -c "sudo systemctl status k3s-agent"
```

## Key Features
- **Minimal Resources**: 1.5GB total RAM usage
- **Automated Setup**: One-command deployment
- **SSH Access**: Passwordless via `vagrant ssh`
- **Private Network**: Isolated 192.168.56.0/24 subnet

## Cleanup
```bash
vagrant destroy -f
```

## Next Steps
With the cluster running, you're ready for Part 2: deploying applications with Ingress and load balancing.