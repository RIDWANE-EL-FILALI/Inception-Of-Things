# Inception of Things 
![banner inception of things](./../images/Inception-Of-Things.png)

## Description
This project aims to introduce you to Kubernetes from a developer's perspective. You will have to set up small clusters and discover the mechanics of continuous integration. At the end of this project, you will be able to set up a working cluster in Docker and have a usable continuous integration pipeline for your applications.

## Vagrant
Vagrant is the command line utility for managing the lifecycle of virtual machines. Isolate dependencies and their configuration within a single disposable and consistent environment.

```mermaid
flowchart TD
    A[Vagrant CLI] --> B[Vagrantfile]
    B --> C[VM Provider Configuration]
    B --> D[Networking Configuration]
    B --> E[Synced Folders / Volumes]
    C --> F[VirtualBox / VMware / Libvirt / Docker]
    F --> G[VM Instance Created]
    D --> H[Port Forwarding & Private Networks]
    E --> I[Host ↔ Guest Shared Folder]

    style A fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style B fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style C fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style D fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style E fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style F fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style G fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style H fill:#000,stroke:#fff,stroke-width:3px,color:#fff
    style I fill:#000,stroke:#fff,stroke-width:3px,color:#fff
```

## kurbernetes