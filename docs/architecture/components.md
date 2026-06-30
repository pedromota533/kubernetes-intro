# Components

Detailed description of every component deployed by this project.

---

## k3s

**Namespace:** system-level (not a Kubernetes namespace)  
**Managed by:** `make` (systemd)

k3s is a lightweight, certified Kubernetes distribution by Rancher. It packages the entire Kubernetes control plane into a single binary and uses `containerd` as the container runtime. It replaces the standard `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager` with a single optimized process.

Key differences from upstream Kubernetes:
- SQLite is used as the default backing store instead of etcd
- Traefik ingress is bundled and used as the cluster ingress controller
- `kubectl` is embedded as `k3s kubectl`

In this project k3s is installed with:
```
--node-ip=<NODE_IP> --flannel-iface=eth1
```

---

## ArgoCD

**Namespace:** `argocd`  
**Exposed at:** `http://localhost/argocd`  
**Managed by:** Bootstrap (`make install`)

ArgoCD is the GitOps engine of this project. It continuously watches this Git repository and reconciles the cluster state to match what is defined in `k8s/kustomize/`.

### How it's configured

ArgoCD is installed in insecure mode (HTTP only) and exposed via Traefik:

1. **Path-based access:** `http://localhost/argocd`
2. **Traffic filtering:** Traefik middleware allows loopback and private network source ranges

An Ingress routes traffic to the ArgoCD server service.

### Root Application

The root Application (`lhs-argocd-apps`) is the entry point. It points to `k8s/kustomize/` and applies the Traefik routing manifests.

---

## Traefik Ingress

**Namespace:** `kube-system`  
**Managed by:** K3s bundled component

Traefik is the default K3s ingress controller. It watches Kubernetes Ingress resources and routes external HTTP traffic to cluster services.

### Routing Configuration

The active routing manifests live in `k8s/kustomize/gateway-config/`:

- `argocd-ingress.yml` routes `localhost/argocd` to `argocd-server`
- `argocd-filter.yml` restricts traffic to loopback and private network ranges

---

## Next Step

→ [k3s Installation](../installation/k3s.md)
