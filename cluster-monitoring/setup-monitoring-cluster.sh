#!/bin/bash

LOGFILE="cluster-monitoring/logs/monitoring-cluster-setup.log"

echo "Creating Monitoring Cluster..." | tee $LOGFILE
kind create cluster --config cluster-monitoring/monitoring-cluster-config.yaml >> $LOGFILE 2>&1
kubectl cluster-info --context kind-monitoring >> $LOGFILE 2>&1

echo "Creating monitoring namespace..."
kubectl create ns monitoring >> $LOGFILE 2>&1 || echo "  ✓ monitoring namespace ready"

echo "Installing Prometheus via Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >> $LOGFILE 2>&1
helm repo update >> $LOGFILE 2>&1
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring -f cluster-monitoring/prometheus/deployment.yml >> $LOGFILE 2>&1
helm upgrade prometheus prometheus-community/prometheus -n monitoring -f cluster-monitoring/prometheus/service.yml >> $LOGFILE 2>&1
kubectl apply -f cluster-monitoring/prometheus/nodeport-service.yml >> $LOGFILE 2>&1
echo "  ✓ Prometheus deployed"

echo ""
echo "=== Monitoring Cluster Status ==="
kubectl get pods -n monitoring
kubectl get svc -n monitoring

echo ""
echo "Prometheus available at: http://localhost:30090"
echo "Full logs saved to: $LOGFILE"
