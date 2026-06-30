# Repository Guidelines

## Project Structure & Module Organization

This repository provisions a local k3s cluster with ArgoCD GitOps and Traefik ingress. The root `Makefile` is the main entry point and delegates to focused modules in `make/`: `k3s.mk`, `argocd.mk`, `hosts.mk`, `cleanup.mk`, `vars.mk`, and `help.mk`. Kubernetes manifests live under `k8s/`: `bootstrap/` contains the manually applied ArgoCD install and root app, while `kustomize/` contains workloads managed by ArgoCD. Local hostname data is in `config/domains`. User-facing documentation belongs in `docs/`, grouped by getting started, architecture, installation, operations, applications, and reference topics. Runtime output such as `logs/` and downloaded binaries in `bin/` are ignored.

## Build, Test, and Development Commands

- `make help`: list supported targets and current default variable values.
- `make k3s-download`: download the configured k3s release to `/usr/local/bin/k3s`.
- `make k3s-install`: write the systemd unit after the binary exists.
- `make k3s-enable && make k3s-start`: enable and start the local cluster.
- `make install`: apply `k8s/bootstrap/` and install ArgoCD.
- `make link`: apply `k8s/bootstrap/root-app.yml` so ArgoCD tracks this repo.
- `make hosts-add NODE_IP=127.0.0.1`: add entries from `config/domains` to `/etc/hosts`.
- `make status` and `make pods`: inspect ArgoCD namespace resources and all pods.

## Coding Style & Naming Conventions

Keep Make targets short, task-oriented, and grouped in the relevant `make/*.mk` module. Make recipes must use tab indentation. Use lowercase, hyphenated target names such as `k3s-download` or `hosts-remove`. Keep YAML resource filenames lowercase with hyphens and the existing `.yml` extension. Prefer explicit variable definitions in `make/vars.mk` over hard-coded paths in recipes.

## Testing Guidelines

There is no formal test suite. Validate Makefile changes with `make help` and, where possible, the specific target in a disposable local environment. Validate manifest edits before applying them:

```bash
k3s kubectl kustomize k8s/bootstrap
k3s kubectl kustomize k8s/kustomize
```

For cluster-affecting changes, verify with `make status`, `make pods`, and ArgoCD sync state.

## Commit & Pull Request Guidelines

Git history uses short imperative subjects, sometimes with Conventional Commit prefixes such as `feat:`, `fix:`, `refactor:`, or scoped `chore(ingress):`. Keep commits focused and mention the affected area. Pull requests should describe the operational impact, list validation commands run, and call out destructive or host-level changes such as systemd edits, `/etc/hosts` updates, or purge targets.

## Security & Configuration Tips

Do not commit generated `logs/`, downloaded `bin/` artifacts, tokens, or kubeconfigs. Treat `make k3s-purge`, `make uninstall`, and app cleanup targets as destructive and document when they are required.
