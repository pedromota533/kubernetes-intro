# TODO - Fix ArgoCD Cluster Registration

## Problem

ArgoCD (running in management cluster) cannot connect to the monitoring cluster.

**Error:**
```
rpc error: code = Unknown desc = error getting server version:
failed to get server version:
Get "https://127.0.0.1:38019/version?timeout=32s":
dial tcp 127.0.0.1:38019: connect: connection refused
```

**Command that fails:**
```bash
argocd cluster add kind-monitoring --name monitoring-cluster
```

## Tasks to Fix Tomorrow

- [ ] Understand why ArgoCD can't reach monitoring cluster via localhost
- [ ] Test network connectivity between management and monitoring clusters
- [ ] Find the correct way to register monitoring cluster with ArgoCD
- [ ] Verify cluster appears in ArgoCD UI at `https://localhost:30443/settings/clusters`
- [ ] Create ArgoCD Application to deploy Prometheus to monitoring cluster

## Current Status

- ✅ Management cluster running (ArgoCD on port 30443)
- ✅ Monitoring cluster running (Prometheus on port 30090)
- ✅ Dev cluster running (Nginx on port 30080)
- ❌ Monitoring cluster NOT registered with ArgoCD
- ❌ Cannot deploy via ArgoCD to monitoring cluster

## Notes

- Both clusters are running on same Docker network
- kubectl can access both clusters from host machine
- Issue is ArgoCD (inside container) reaching other Kind clusters
