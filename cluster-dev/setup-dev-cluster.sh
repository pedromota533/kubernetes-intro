#!/bin/bash

LOGFILE="cluster-dev/logs/dev-cluster-setup.log"

echo "Creating Dev Cluster..." | tee $LOGFILE
kind create cluster --config cluster-dev/dev-cluster-config.yaml >> $LOGFILE 2>&1
kubectl cluster-info --context kind-saas-dev >> $LOGFILE 2>&1

echo "Creating namespaces..."
kubectl create ns dev >> $LOGFILE 2>&1 || echo "  ✓ dev namespace ready"
kubectl create ns qua >> $LOGFILE 2>&1 || echo "  ✓ qua namespace ready"

echo "Deploying Nginx (40 replicas with LoadBalancer)..."
kubectl apply -f cluster-dev/apps/dev/nginx-deployment.yaml >> $LOGFILE 2>&1
echo "  ✓ Nginx deployed"

echo ""
echo "=== Dev Cluster Status ==="
kubectl get pods -n dev
kubectl get svc -n dev

echo ""
echo "Nginx available at: http://localhost:30080"
echo "Full logs saved to: $LOGFILE"
