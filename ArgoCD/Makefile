KUSTOMIZE_DIR := $(HOME)/personal/k3s.install/ArgoCD/k8s/kustomize
BIN           := k3s kubectl
NAMESPACE     := argocd
HTTP_PORT     := 30080
HTTPS_PORT    := 30443

.PHONY: install uninstall port-forward password status

install:
	$(BIN) apply --server-side --force-conflicts -k $(KUSTOMIZE_DIR)

uninstall:
	$(BIN) delete -k $(KUSTOMIZE_DIR) --ignore-not-found

port-forward:
	$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8080:80

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo

status:
	$(BIN) get all -n $(NAMESPACE)
