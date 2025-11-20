# Check if monitoring cluster is running
kind get clusters

# Check if you can access the monitoring cluster
kubectl cluster-info --context kind-monitoring

# Check if Prometheus pods are running
kubectl get pods -n monitoring --context kind-monitoring

If the cluster is down, restart it:

./cluster-monitoring/setup-monitoring-cluster.sh

Then try adding the cluster to ArgoCD again:

# Make sure you're on management context
kubectl config use-context kind-management

# Try adding the cluster again
argocd cluster add kind-monitoring --name monitoring-cluster