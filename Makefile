BOOTSTRAP_DIR   := $(HOME)/personal/k3s.install/k8s/bootstrap
APPS_DIR        := $(HOME)/personal/k3s.install/k8s/kustomize
ROOT_APP        := $(BOOTSTRAP_DIR)/root-app.yml
DOMAINS_FILE    := $(HOME)/personal/k3s.install/config/domains
BIN             := k3s kubectl
NAMESPACE       := argocd
HTTP_PORT       := 30080
HTTPS_PORT      := 30443
NODE_IP         ?= 127.0.0.1
K3S_INSTALL_URL := https://get.k3s.io
K3S_UNINSTALL   := /usr/local/bin/k3s-uninstall.sh
K3S_SERVICE     := k3s

.DEFAULT_GOAL   := help

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
BLUE   := \033[0;34m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

.PHONY: help \
        k3s-setup k3s-start k3s-stop k3s-enable k3s-disable k3s-delete \
        install uninstall link unlink port-forward password status \
        deploy-apps remove-apps nuke-apps prune-apps \
        ghcr-secret hosts-add hosts-remove pods

Logs:
	@mkdir -p logs

# ─── Default ───────────────────────────────────────────────────────────────────

help: ## Show this help message
	@printf "\n$(BOLD)Usage:$(NC)  make $(CYAN)<target>$(NC)\n\n"
	@printf "$(BOLD)k3s$(NC)\n"
	@printf "  $(CYAN)k3s-setup$(NC)      Download and install k3s from $(K3S_INSTALL_URL)\n"
	@printf "  $(CYAN)k3s-start$(NC)      Start the k3s systemd service\n"
	@printf "  $(CYAN)k3s-stop$(NC)       Stop the k3s systemd service\n"
	@printf "  $(CYAN)k3s-enable$(NC)     Enable k3s to start on boot\n"
	@printf "  $(CYAN)k3s-disable$(NC)    Disable k3s from starting on boot\n"
	@printf "  $(CYAN)k3s-delete$(NC)     Fully uninstall k3s from the system\n"
	@printf "\n$(BOLD)ArgoCD$(NC)\n"
	@printf "  $(CYAN)install$(NC)        Install ArgoCD into the cluster\n"
	@printf "  $(CYAN)uninstall$(NC)      Remove ArgoCD and all its Applications\n"
	@printf "  $(CYAN)link$(NC)           Apply root-app (link ArgoCD to this repo)\n"
	@printf "  $(CYAN)unlink$(NC)         Delete root-app (unlink ArgoCD from this repo)\n"
	@printf "  $(CYAN)port-forward$(NC)   Forward ArgoCD server to localhost:8080\n"
	@printf "  $(CYAN)password$(NC)       Print the ArgoCD initial admin password\n"
	@printf "  $(CYAN)status$(NC)         Show all resources in the $(NAMESPACE) namespace\n"
	@printf "  $(CYAN)pods$(NC)           Show pods across all namespaces\n"
	@printf "  $(CYAN)deploy-apps$(NC)    Apply kustomize app manifests\n"
	@printf "  $(CYAN)remove-apps$(NC)    Delete kustomize app manifests\n"
	@printf "  $(CYAN)nuke-apps$(NC)      Delete ALL ArgoCD Applications (cascade)\n"
	@printf "  $(CYAN)prune-apps$(NC)     Remove namespaces left behind after uninstall\n"
	@printf "  $(CYAN)ghcr-secret$(NC)    Add ghcr.io OCI credentials to ArgoCD  (GHCR_USER= GHCR_TOKEN=)\n"
	@printf "\n$(BOLD)Hosts$(NC)\n"
	@printf "  $(CYAN)hosts-add$(NC)      Add project domains to /etc/hosts  (NODE_IP=$(NODE_IP))\n"
	@printf "  $(CYAN)hosts-remove$(NC)   Remove project domains from /etc/hosts\n"
	@printf "\n"

# ─── k3s ───────────────────────────────────────────────────────────────────────

k3s-setup: Logs
	@echo "$(BLUE)Installing k3s from $(K3S_INSTALL_URL)...$(NC)"
	@curl -sfL $(K3S_INSTALL_URL) | sudo sh - 2>&1 | tee logs/k3s-setup.log
	@echo "$(GREEN)k3s installed. Run 'make k3s-enable && make k3s-start' to bring it up.$(NC)"

k3s-start:
	@echo "$(GREEN)Starting k3s service...$(NC)"
	@sudo systemctl start $(K3S_SERVICE)
	@systemctl is-active $(K3S_SERVICE)

k3s-stop:
	@echo "$(YELLOW)Stopping k3s service...$(NC)"
	@sudo systemctl stop $(K3S_SERVICE)

k3s-enable:
	@echo "$(GREEN)Enabling k3s service at boot...$(NC)"
	@sudo systemctl enable $(K3S_SERVICE)

k3s-disable:
	@echo "$(YELLOW)Disabling k3s service at boot...$(NC)"
	@sudo systemctl disable $(K3S_SERVICE)

k3s-delete:
	@if [ ! -x "$(K3S_UNINSTALL)" ]; then \
		echo "$(RED)$(K3S_UNINSTALL) not found — is k3s installed?$(NC)"; exit 1; \
	fi
	@echo "$(RED)Uninstalling k3s from the system...$(NC)"
	@sudo $(K3S_UNINSTALL)
	@echo "$(GREEN)k3s removed.$(NC)"

# ─── ArgoCD ────────────────────────────────────────────────────────────────────

install: Logs
	@echo "$(BLUE)Installing ArgoCD in the cluster...$(NC)"
	@$(BIN) apply --server-side --force-conflicts -k $(BOOTSTRAP_DIR) > logs/install.log 2>&1 \
		|| (echo "$(RED)Installation failed. Check logs/install.log for details.$(NC)" && exit 1)
	@echo "$(GREEN)ArgoCD installed.$(NC)"

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

link:
	@echo "$(BLUE)Linking ArgoCD to the repository...$(NC)"
	@$(BIN) apply -f $(ROOT_APP)

unlink:
	@echo "$(YELLOW)Unlinking ArgoCD from the repository...$(NC)"
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found

port-forward: Logs
	@echo "$(BLUE)Starting port-forwarding for ArgoCD server...$(NC)"
	@echo "  Open: http://localhost:8080"
	@$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8080:80

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo

status:
	@$(BIN) get all -n $(NAMESPACE)

pods:
	@$(BIN) get pods -A -o wide

deploy-apps:
	@$(BIN) apply -k $(APPS_DIR)

remove-apps:
	@$(BIN) delete -k $(APPS_DIR) --ignore-not-found

# ─── Hosts ─────────────────────────────────────────────────────────────────────

hosts-add:
	@echo "$(BLUE)Adding domains to /etc/hosts (NODE_IP=$(NODE_IP))...$(NC)"
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print "$(NODE_IP) " $$1}' | while read entry; do \
		if grep -qF "$$entry" /etc/hosts; then \
			echo "  already exists: $$entry"; \
		else \
			echo "$$entry" | sudo tee -a /etc/hosts > /dev/null && echo "  added: $$entry"; \
		fi; \
	done

hosts-remove:
	@echo "$(YELLOW)Removing project domains from /etc/hosts...$(NC)"
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print $$1}' | while read domain; do \
		sudo sed -i "/[[:space:]]$$domain$$/d" /etc/hosts && echo "  removed: $$domain"; \
	done

# ─── Cleanup ───────────────────────────────────────────────────────────────────

prune-apps:
	@echo "$(YELLOW)Pruning app namespaces left behind by uninstall...$(NC)"
	@echo "  stripping finalizers from ArgoCD Applications..."
	@$(BIN) get applications.argoproj.io -n $(NAMESPACE) -o name 2>/dev/null \
		| xargs -I{} $(BIN) patch {} -n $(NAMESPACE) \
			--type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
	@for ns in triggerdev istio-system istio-ingress monitoring kubernetes-dashboard; do \
		if $(BIN) get namespace $$ns > /dev/null 2>&1; then \
			echo "  stripping finalizers in $$ns..."; \
			$(BIN) api-resources --verbs=list --namespaced -o name 2>/dev/null \
				| xargs -I{} $(BIN) get {} -n $$ns -o name 2>/dev/null \
				| xargs -I{} $(BIN) patch {} -n $$ns \
					--type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true; \
			echo "  deleting namespace $$ns..."; \
			$(BIN) delete namespace $$ns --ignore-not-found; \
		fi; \
	done

# Usage: make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>
ghcr-secret:
	@if [ -z "$(GHCR_USER)" ] || [ -z "$(GHCR_TOKEN)" ]; then \
		echo "$(RED)Error: GHCR_USER and GHCR_TOKEN must be set.$(NC)"; \
		echo "Usage: make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>"; \
		exit 1; \
	fi
	@$(BIN) delete secret ghcr-triggerdev-charts -n $(NAMESPACE) --ignore-not-found
	@$(BIN) create secret generic ghcr-triggerdev-charts \
		-n $(NAMESPACE) \
		--from-literal=type=helm \
		--from-literal=name=ghcr-triggerdev-charts \
		--from-literal=url=ghcr.io \
		--from-literal=enableOCI=true \
		--from-literal=username=$(GHCR_USER) \
		--from-literal=password=$(GHCR_TOKEN)
	@$(BIN) label secret ghcr-triggerdev-charts -n $(NAMESPACE) \
		argocd.argoproj.io/secret-type=repository
	@echo "$(GREEN)ghcr.io repository secret applied to ArgoCD.$(NC)"

nuke-apps:
	@echo "$(RED)Removing all ArgoCD Applications from the cluster...$(NC)"
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found
