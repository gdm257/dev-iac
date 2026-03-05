# OpenClaw Stack

OpenClaw is an AI agent tool that provides autonomous execution capabilities through a WebSocket-based Gateway interface. It enables AI agents to interact with various platforms (Telegram, Discord, Slack) and execute commands with configurable security constraints.

## Quick Start

```bash
# Deploy the stack
docker stack deploy -c compose.yaml openclaw

# Verify deployment
docker service ls | grep openclaw
```

## Access

- **WebSocket Gateway:** `wss://openclaw.${BASE_DOMAIN:-localhost}` (port 18789)
- **Web Interface:** `https://openclaw.${BASE_DOMAIN:-localhost}` (if available)

## Environment Variables

### Required

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_DOMAIN` | Your base domain for Traefik routing | `localhost` |
| `NODE_ENV` | Application environment | `production` |
| `TZ` | Container timezone | `Asia/Tokyo` |

### Optional: AI Model API Keys

OpenClaw requires at least one AI model API key to function. Configure via external secrets or `.env`:

```bash
# OpenAI (GPT models)
OPENAI_API_KEY=sk-...

# Anthropic (Claude models)
ANTHROPIC_API_KEY=sk-ant-...

# Google (Gemini models)
GOOGLE_API_KEY=...
```

### Optional: Channel Integrations

OpenClaw can integrate with messaging platforms:

```bash
# Telegram
TELEGRAM_BOT_TOKEN=...

# Discord
DISCORD_BOT_TOKEN=...

# Slack (both tokens required)
SLACK_BOT_TOKEN=...
SLACK_APP_TOKEN=...
```

## Deployment Methods

### Method 1: Docker Stack (Manual)

```bash
cd deploy/docker/openclaw
docker stack deploy -c compose.yaml openclaw
```

### Method 2: GitOps with doco-cd (Recommended)

The stack is registered in `.doco-cd.yaml` and will deploy automatically:

```bash
git add deploy/docker/openclaw/
git commit -m "Add OpenClaw stack"
git push
```

### External Secrets (Recommended for Production)

When using doco-cd, configure external secrets to inject API keys:

```yaml
# In .doco-cd.yaml, under the openclaw stack entry:
external_secrets:
  OPENAI_API_KEY: "infisical:<projectId>:<env>:/openclaw/openai_api_key"
  TELEGRAM_BOT_TOKEN: "infisical:<projectId>:<env>:/openclaw/telegram_bot_token"
```

## Storage

- **Volume:** `openclaw_data`
- **Mount Path:** `/root/.openclaw`
- **Contents:** Configuration, credentials, workspace data

## Network

- **Network:** `traefik-public` (external overlay)
- **Port:** 18789 (Gateway WebSocket, internal only - exposed via Traefik)

## Traefik Routing

This stack uses Traefik for SSL/TLS termination and routing:

- **HTTP Router:** Redirects to HTTPS
- **HTTPS Router:** Terminates TLS with Let's Encrypt (certresolver: `myresolver`)
- **Service:** `openclaw` on port 18789

> [!NOTE]
> Traefik natively supports WebSocket. No additional configuration is required beyond the port specification.

## Verification

After deployment, verify:

```bash
# Check service status
docker service ls | grep openclaw

# Check logs
docker service logs openclaw_openclaw

# Test WebSocket connection (requires wscat)
wscat -c wss://openclaw.${BASE_DOMAIN}
```

## Troubleshooting

### Service not starting

```bash
# Check logs for errors
docker service logs openclaw_openclaw --tail 100

# Verify volume exists
docker volume ls | grep openclaw_data

# Verify network attachment
docker network inspect traefik-public | grep openclaw
```

### WebSocket connection failing

- Verify Traefik is running and `traefik-public` network exists
- Check that `BASE_DOMAIN` is set correctly
- Ensure TLS certificates are valid (check Traefik dashboard)
- Verify service is healthy: `docker service ps openclaw_openclaw`

### Missing API keys

OpenClaw will start without API keys but will have limited functionality. Configure at least one AI model API key via external secrets or `.env` file.

## Documentation

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [WebSocket Client Testing](https://github.com/websockets/wscat)
