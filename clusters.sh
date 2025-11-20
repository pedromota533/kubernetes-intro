#!/bin/bash

LOGFILE="cluster-setup.log"

echo "Creating Kind cluster..." | tee $LOGFILE
kind create cluster --config saas-dev-config.yaml >> $LOGFILE 2>&1
kubectl cluster-info --context kind-saas-dev >> $LOGFILE 2>&1

echo "Creating namespaces..."
kubectl create ns monitoring >> $LOGFILE 2>&1 || echo "  ✓ monitoring namespace ready"
kubectl create ns dev >> $LOGFILE 2>&1 || echo "  ✓ dev namespace ready"
kubectl create ns qua >> $LOGFILE 2>&1 || echo "  ✓ qua namespace ready"

echo "Deploying Nginx (5 replicas with LoadBalancer)..."
kubectl apply -f saas-dev/dev/nginx-deployment.yaml >> $LOGFILE 2>&1
echo "  ✓ Nginx deployed"

echo "Deploying Grafana..."
kubectl apply -f saas-dev/monitoring/grafana/deployment.yml >> $LOGFILE 2>&1
echo "  ✓ Grafana deployed"

echo "Installing Prometheus via Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >> $LOGFILE 2>&1
helm repo update >> $LOGFILE 2>&1
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring -f saas-dev/monitoring/prometheus/deployment.yml >> $LOGFILE 2>&1
helm upgrade prometheus prometheus-community/prometheus -n monitoring -f saas-dev/monitoring/prometheus/service.yml >> $LOGFILE 2>&1
kubectl apply -f saas-dev/monitoring/prometheus/nodeport-service.yml >> $LOGFILE 2>&1
echo "  ✓ Prometheus deployed"

echo ""
echo "=== Monitoring Namespace ==="
kubectl get pods -n=monitoring
kubectl get svc  -n=monitoring

echo ""
echo "=== Dev Namespace ==="
kubectl get pods -n=dev
kubectl get svc -n=dev

echo ""
echo "Full logs saved to: $LOGFILE"
