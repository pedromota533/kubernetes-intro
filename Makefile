BOOTSTRAP_DIR := $(HOME)/personal/k3s.install/k8s/bootstrap
APPS_DIR      := $(HOME)/personal/k3s.install/k8s/kustomize
ROOT_APP      := $(BOOTSTRAP_DIR)/root-app.yml
BIN           := k3s kubectl
NAMESPACE     := argocd
HTTP_PORT     := 30080
HTTPS_PORT    := 30443

.PHONY: install uninstall link unlink port-forward password status deploy-apps remove-apps nuke-apps prune-apps

Logs:
	mkdir -p logs

install: Logs 
	@echo "Installing ArgoCD in the cluster..."
	@$(BIN) apply --server-side --force-conflicts -k $(BOOTSTRAP_DIR) > logs/install.log 2>&1 || (echo "Installation failed. Check logs/install.log for details." && exit 1)

uninstall: Logs
	@echo "Step 1/3 — Removing finalizers from root app and all Applications..."
	@$(BIN) patch -f $(ROOT_APP) --type=json \
		-p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
	@for app in $$($(BIN) get applications.argoproj.io -n $(NAMESPACE) -o name 2>/dev/null); do \
		$(BIN) patch $$app -n $(NAMESPACE) --type=json \
			-p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true; \
	done
	@echo "Step 2/3 — Deleting root app and all Applications..."
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found
	@echo "Step 3/3 — Uninstalling ArgoCD..."
	@$(BIN) delete -k $(BOOTSTRAP_DIR) --ignore-not-found

# Apply the root Application — links ArgoCD to the repo (run once after install)
link:
	@echo "Linking ArgoCD to the repository..."
	@$(BIN) apply -f $(ROOT_APP)

unlink:
	@echo "Unlinking ArgoCD from the repository..."
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found

port-forward: Logs
	@echo "Starting port-forwarding for ArgoCD server..."
	@$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8080:80

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo

status:

	$(BIN) get all -n $(NAMESPACE)

# Deploy ArgoCD Application manifests (run after `make install` and ArgoCD is ready)
deploy-apps:
	$(BIN) apply -k $(APPS_DIR)

remove-apps:
	$(BIN) delete -k $(APPS_DIR) --ignore-not-found

# Delete namespaces left behind when uninstall ran without finalizers
prune-apps:
	@echo "Pruning app namespaces left behind by uninstall..."
	@for ns in triggerdev istio-system istio-ingress; do \
		$(BIN) delete namespace $$ns --ignore-not-found; \
	done

# Delete every ArgoCD Application in the cluster (cascade-deletes managed resources via finalizers)
nuke-apps:
	@echo "Removing all ArgoCD Applications from the cluster..."
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found
