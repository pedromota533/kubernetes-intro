Cluster information


kind create cluster --name saas-dev
kubectl cluster-info --context kind-saas-dev

Namespace:
    - monitoring
    - dev
    - qua

kind create cluster --name saas-prod
kubectl cluster-info --context kind-saas-prod

namespace:
    - monitoring
    - prd


Namespace Monitoring:
    - grafana
    - promoteus