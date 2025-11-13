# Project Briefing: GitOps with ArgoCD

## Objective
Learn Kubernetes and GitOps by deploying a simple application using ArgoCD.

## What You'll Learn
- Kubernetes basics (Pods, Deployments, Services)
- GitOps workflow (Git as source of truth)
- ArgoCD setup and application deployment
- Declarative configuration management

## Project Overview
Deploy a simple web application (nginx or sample app) to a local Kubernetes cluster using ArgoCD.

## Requirements

### Infrastructure
- Local Kubernetes cluster (kind or minikube)
- ArgoCD installed in the cluster
- kubectl configured

### Application
- Simple containerized application (use existing Docker image)
- Kubernetes manifests (Deployment, Service)
- All config stored in Git

### GitOps Workflow
1. Commit YAML files to Git repository
2. ArgoCD monitors the repository
3. ArgoCD automatically deploys changes
4. Test self-healing (manual change gets reverted)

## Deliverables
- Working local Kubernetes cluster
- ArgoCD installed and accessible
- Sample application deployed via ArgoCD
- Documentation of the process

## Timeline
- Setup: 30-60 minutes
- Testing GitOps flow: 30 minutes
- Total: ~2 hours

## Success Criteria
✅ Application accessible via browser/curl
✅ Git push triggers automatic deployment
✅ ArgoCD UI shows application status
✅ Self-healing works (manual changes reverted)

## Resources Needed
- Docker Desktop or similar
- kind or minikube
- Git repository (GitHub/GitLab)
- Terminal access

## Next Steps
1. Choose cluster tool (kind recommended - faster)
2. Install ArgoCD
3. Create sample app manifests
4. Configure ArgoCD application
5. Test GitOps workflow
