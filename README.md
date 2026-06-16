# DevOps & Infrastructure as Code

## GitOps via [doco-cd](https://github.com/kimdre/doco-cd)

```bash
# ==== Server-side ====
# Configure doco-cd
vim .doco-cd.gitops.yaml
vim .doco-cd.yaml
git add .
git push origin main
# Deploy doco-cd to initialize GitOps
cd deploy/docker/doco-cd
vim .bootstrap.env
docker compose --env-file .bootstrap.env up # after "gitops" target bootstrap, press ctrl-c to stop this container
docker compose --env-file .bootstrap.env down

# ==== Local-side ====
# GitOps: modify files and git push to enable Continuous Deployment
vim .doco-cd.yaml
git add .doco-cd.yaml
git commit -m "Update deployment configuration"
git push
```

> [!TIP]
> Constrains in the `deploy/docker` directory:
> 
> `${VAR:-default}` is an optional variable with default value
> 
> `${VAR:-}` is an optional variable
> 
> `${VAR}` is a required variable
