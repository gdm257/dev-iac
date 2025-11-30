# DevOps & Infrastructure as Code

## Command-line cheatsheet

There are many tools to take note for command-line:

- Blog (e.g. Medium, Wordpress, Hexo)
- Note-taking application (e.g. Notion, Obsidian, VNote)
- Code snippets (e.g. VSCode snippets, IDEA snippets, GitHub gist)
- Cheatsheet tool (e.g. navi, cheat, tldr)
- Task runner (e.g. just, task, make)

After thousands of notes, I realize **task runner** is the best choice for **CLI**. Finally I choose [task](https://taskfile.dev/), a YAML-based task runner, which has excellent cross-platform experience and powerful features.

> [!TIP]
> It's allowed to write sensitive environment variables to `.local.env` file that taskfile auto reads.

## GitOps via [doco-cd](https://github.com/kimdre/doco-cd)

```bash
# ==== Server-side ====
# Create docker network
PUBLIC_NETWORK_NAME=traefik-public
PUBLIC_NETWORK_DRIVER=overlay
docker network create $PUBLIC_NETWORK_NAME --attachable --driver $PUBLIC_NETWORK_DRIVER

# Configure doco-cd
vim deploy/docker/doco-cd/.env
vim .doco-cd.gitops.yaml
vim .doco-cd.yaml

# Deploy doco-cd to initialize GitOps
export $(cat deploy/docker/doco-cd/.env) > /dev/null 2>&1
docker stack deploy -c deploy/docker/doco-cd/compose.yaml temp
docker service ps doco-cd_doco-cd && docker stack rm temp || echo please execute again

# ==== Local-side ====
# GitOps: modify files and git push to enable Continuous Deployment
vim .doco-cd.yaml
git add .doco-cd.yaml
git commit -m "Update deployment configuration"
git push
```
