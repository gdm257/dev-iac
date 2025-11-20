## Deps

- Kubernetes (remote k8s server)
- kubeconfig (client credential)

## Usage

```bash
# Make sure repo path containers a `bootstrap` directory and k8s manifests in it
GIT_REPO=https://github.com/gdm257/dev-iac.git/deploy/argocd-autocopilot?ref=main
argocd-autopilot repo bootstrap
```
