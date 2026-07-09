# Credential Pool Health Signals

The Hermes credential pool at `~/.hermes/auth.json` stores credentials
that are injected at the AIAgent layer. Some credentials only exist in
the pool (value is `***` in `.env`) — `auth.json` is the only place to
check their health from the shell.

## Structure (`credential_pool.<provider>[0]`)

| Field | Meaning | Healthy | Unhealthy |
|-------|---------|---------|-----------|
| `last_status` | Pool-tested status | `null` or `"ok"` | `"exhausted"` |
| `last_error_code` | HTTP error from last test | `null` | `401`, `403`, `429` |
| `last_error_message` | Human-readable error | `null` | e.g. `"User not found."` |
| `last_status_at` | When last tested | Recent | >30 days stale |

## Credential Categories

| Category | `.env` value | `auth.json` value | Shell testable? |
|----------|-------------|------------------|-----------------|
| Full-text | Real token | Real token | Yes — curl directly |
| Redacted | `***` or `sk-...XX` | Same redacted | No — runtime-injected only. Use pool health signals |
| Pool-only | Missing | Real token | Yes if auth.json has the plain value |

## Workflow

1. **Read `.env`** — note which values are full tokens vs redacted `***`
2. **Read `auth.json`** — for any redacted `.env` key, find the provider entry
3. If `access_token` in auth.json is readable → **curl-test it directly**
4. If `access_token` is also redacted → assess from pool health signals:
   - `last_status: null` → "untested, cannot verify from shell"
   - `last_status: "exhausted"` + error info → report failure with recorded details
5. Report findings alongside normal curl-test results
