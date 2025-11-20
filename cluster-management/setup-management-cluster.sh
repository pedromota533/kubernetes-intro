#!/bin/bash

LOGFILE="cluster-management/logs/management-cluster-setup.log"

echo "Creating Management Cluster..." | tee $LOGFILE
kind create cluster --config cluster-management/management-cluster-config.yaml >> $LOGFILE 2>&1
kubectl cluster-info --context kind-management >> $LOGFILE 2>&1

echo "Creating argocd namespace..."
kubectl create ns argocd >> $LOGFILE 2>&1 || echo "  ✓ argocd namespace ready"

echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >> $LOGFILE 2>&1
echo "  ✓ ArgoCD installed"

echo "Configuring persistent storage..."
kubectl apply -f cluster-management/argocd/persistent-storage.yml >> $LOGFILE 2>&1
echo "  ✓ Persistent volumes created"

echo "Waiting for pods to be ready..."

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s >> $LOGFILE 2>&1

echo "Exposing ArgoCD UI via NodePort..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443, "name": "https"}]}}' >> $LOGFILE 2>&1
echo "  ✓ ArgoCD UI exposed"

echo ""
echo "=== Management Cluster Status ==="
kubectl get pods -n argocd
kubectl get svc -n argocd

echo ""
echo "=== ArgoCD Access Information ==="
echo "ArgoCD UI: https://localhost:30443"
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "Full logs saved to: $LOGFILE"
