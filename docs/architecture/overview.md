# Architecture Overview

## Design Philosophy

This project follows the **GitOps** pattern: the Git repository is the single source of truth for the cluster state. No manual `kubectl apply` commands are needed after the initial bootstrap. ArgoCD continuously reconciles the cluster against the repository.

---

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                        Local Machine                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    k3s Cluster                              │  │
│  │                                                             │  │
│  │  ┌──────────┐   watches    ┌─────────────────────────────┐  │  │
│  │  │  ArgoCD  │ ──────────► │  GitHub Repository          │  │  │
│  │  │          │             │  k8s/kustomize/              │  │  │
│  │  └──────────┘             └─────────────────────────────┘  │  │
│  │       │ deploys                                             │  │
│  │       ▼                                                     │  │
│  │  ┌──────────┐  ┌──────────┐                             │  │
│  │  │  ArgoCD  │  │ Traefik  │                             │  │
│  │  │   UI     │  │ ingress  │                             │  │
│  │  └──────────┘  └──────────┘                             │  │
│  │       │                                                     │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │          Traefik Ingress (:80)                       │   │  │
│  │  │   routes traffic via Ingress + Middleware rules      │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                            ▲                                      │
│                     make / kubectl                                 │
│                       (operator)                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## GitOps Flow

```
Developer                  Git Repository              ArgoCD                  Cluster
    │                           │                         │                       │
    │  git push (manifest)      │                         │                       │
    │──────────────────────────►│                         │                       │
    │                           │  polls every 3 minutes  │                       │
    │                           │◄────────────────────────│                       │
    │                           │                         │                       │
    │                           │  detects diff           │                       │
    │                           │────────────────────────►│                       │
    │                           │                         │  kubectl apply        │
    │                           │                         │──────────────────────►│
    │                           │                         │                       │
    │                           │                         │  resource created/    │
    │                           │                         │  updated/deleted      │
```

1. A developer pushes Kubernetes manifests to the `main` branch of this repository.
2. ArgoCD polls GitHub periodically and detects the difference between the desired state (Git) and the live state (cluster).
3. ArgoCD applies the changes to the cluster automatically.

---

## Bootstrap vs GitOps

There is a clear separation between the **bootstrap phase** (one-time, manual) and the **GitOps phase** (ongoing, automatic):

| Phase      | What runs it | What it manages                         |
|------------|--------------|------------------------------------------|
| Bootstrap  | `make`        | k3s install, ArgoCD namespace + install, root Application |
| GitOps     | ArgoCD        | Everything under `k8s/kustomize/`        |

---

## Application Order

Traefik is provided by K3s and is not deployed as an ArgoCD child Application. The root ArgoCD Application applies the Traefik Ingress and middleware manifests directly from `k8s/kustomize/gateway-config/`.

---

## Traffic Routing

All HTTP traffic enters the cluster through the **K3s bundled Traefik ingress controller** on port 80. Kubernetes Ingress resources route traffic to backend services, and Traefik middleware applies the traffic filter:

```
http://argocd.local             → argocd-server.argocd.svc.cluster.local:80
```

---

## Namespace Layout

| Namespace            | Contents                                      |
|----------------------|-----------------------------------------------|
| `argocd`             | ArgoCD server, repo-server, application-controller |
| `kube-system`        | K3s Traefik ingress controller               |

---

## Next Step

→ [Components](components.md)
