# DevOps & Infrastructure as Code

## GitOps via [doco-cd](https://github.com/kimdre/doco-cd)

```bash
# ==== Server-side ====
# Configure doco-cd
vim .doco-cd.gitops.yaml
vim .doco-cd.yaml
cd deploy/docker/doco-cd
vim .env # see below

# Deploy doco-cd to initialize GitOps
docker compose --project-name temp up # after "gitops" target bootstrap, press ctrl-c to stop this container
docker container rm --force temp_doco-cd

# ==== Local-side ====
# GitOps: modify files and git push to enable Continuous Deployment
vim .doco-cd.yaml
git add .doco-cd.yaml
git commit -m "Update deployment configuration"
git push
```

`.env` example for temp doco-cd:
```dotenv
# ONLY use this file for deploying temporary doco-cd
# to initialize GitOps.
# Env file does not take effect in swarm mode.

# https://github.com/kimdre/doco-cd/wiki/App-Settings
GIT_ACCESS_TOKEN=xxxx
SOPS_AGE_KEY=xxxx # if sops is used

# https://github.com/kimdre/doco-cd/wiki/External-Secrets
SECRET_PROVIDER=infisical
SECRET_PROVIDER_SITE_URL=https://app.infisical.com
SECRET_PROVIDER_CLIENT_ID=xxxx
SECRET_PROVIDER_CLIENT_SECRET=xxxx

# https://github.com/kimdre/doco-cd/wiki/Poll-Settings
POLL_CONFIG='
- url: https://github.com/gdm257/dev-iac.git # replace with your repo and target
  target: gitops # reference this example
  interval: 180
'

# Common
TZ=Asia/Tokyo
VOLUME_NAME=temp_data
PUBLIC_NETWORK_NAME=temp
PUBLIC_NETWORK_DRIVER=bridge
```

> [!TIP]
> Constrains in the `deploy/docker` directory:
> 
> `${VAR:-default}` is an optional variable
> 
> `${VAR:-}` is an optional variable
> 
> `${VAR}` is a required variable
