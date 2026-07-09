# MCP Server Configuration Patterns

Configuring MCP (Model Context Protocol) servers in Hermes `config.yaml`.

## Auth Formats

### Option A: `token_env` (preferred — keeps secrets out of config)

```yaml
mcp_servers:
  outline:
    url: https://outline.velocit8.com/mcp
    auth:
      type: bearer
      token_env: OUTLINE_API_KEY
    timeout: 180
    connect_timeout: 60
```

The MCP client reads the token from the named environment variable at runtime.
No secrets in config.yaml.

### Option B: Inline `headers` with env var reference

```yaml
mcp_servers:
  outline:
    url: https://outline.velocit8.com/mcp
    headers:
      Authorization: "Bearer $OUTLINE_API_KEY"
    timeout: 180
    connect_timeout: 60
```

`$VAR` is expanded from the process environment. Less clean than `token_env`.

### Option C: Hardcoded (NOT recommended)

```yaml
mcp_servers:
  n8n:
    url: https://n8n.velocit8.com/mcp-server/http
    headers:
      Authorization: Bearer <raw-token>
```

Secrets leak into config.yaml. Avoid.

## Accept Header Gotcha

MCP endpoints require `text/event-stream` in the Accept header. Raw HTTP clients
(urllib, curl) may not include it. The Hermes MCP client handles this correctly.

Error if missing: `"Not Acceptable: Client must accept both application/json and text/event-stream"`

## Timeouts

- `timeout`: Overall request timeout (default: 180s)
- `connect_timeout`: TCP connection timeout (default: 60s)

Set higher for slow first-connection scenarios (cold starts, cold caches).
