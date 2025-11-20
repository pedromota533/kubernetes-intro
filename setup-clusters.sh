#!/bin/bash

echo "========================================"
echo "Setting up all Kubernetes clusters"
echo "========================================"
echo ""

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
    echo "ERROR: Kind is not installed. Please install Kind first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed. Please install Helm first."
    exit 1
fi

echo "All prerequisites found ✓"
echo ""

# Setup Management Cluster (ArgoCD)
echo "========================================"
echo "1/3 Setting up Management Cluster"
echo "========================================"
./cluster-management/setup-management-cluster.sh
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to setup management cluster"
    exit 1
fi
echo ""

# Setup Monitoring Cluster (Prometheus)
echo "========================================"
echo "2/3 Setting up Monitoring Cluster"
echo "========================================"
./cluster-monitoring/setup-monitoring-cluster.sh
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to setup monitoring cluster"
    exit 1
fi
echo ""

# Setup Dev Cluster (Applications)
echo "========================================"
echo "3/3 Setting up Dev Cluster"
echo "========================================"
./cluster-dev/setup-dev-cluster.sh
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to setup dev cluster"
    exit 1
fi
echo ""

echo "========================================"
echo "All clusters are ready!"
echo "========================================"
echo ""
echo "Access Information:"
echo "  - ArgoCD UI:    https://localhost:30443 (Management Cluster)"
echo "  - Prometheus:   http://localhost:30090  (Monitoring Cluster)"
echo "  - Nginx App:    http://localhost:30080  (Dev Cluster)"
echo ""
echo "Cluster Contexts:"
echo "  - Management:   kind-management"
echo "  - Monitoring:   kind-monitoring"
echo "  - Dev:          kind-saas-dev"
echo ""
echo "Switch contexts with: kubectl config use-context <context-name>"
echo ""
