# Environment Variable Diagnostics

When reading environment variables for a running Hermes instance,
the key may come from three different sources. Terminal display
truncation is just one of the gotchas — source confusion is another.

## Three Sources of Env Vars

| Source | Check Method | Scope |
|--------|-------------|-------|
| `~/.hermes/.env` | Read file directly | Hermes Agent (resolved at agent runtime) |
| Process env | `echo $VAR_NAME` or `env` | Current shell + child processes |
| Container env | `cat /proc/1/environ` (as root) | Docker/Podman container at launch |
| `auth.json` | `cat ~/.hermes/auth.json` | Hermes credential pool (WebUI + agent) |

## Diagnostic Flow

When you think an env var is "missing" or "just `***`":

```bash
# 1. Check the .env file
grep "^VAR_NAME=" ~/.hermes/.env

# 2. Check the running process env
echo "${VAR_NAME:-(not set)}"

# 3. Check auth.json for credential pool entries
python3 -c "
import json, os
path = os.path.expanduser('~/.hermes/auth.json')
if os.path.exists(path):
    with open(path) as f:
        auth = json.load(f)
    for provider, creds in auth.get('credential_pool', {}).items():
        for c in creds:
            source = c.get('source', '?')
            status = c.get('last_status', '?')
            print(f'{provider}: source={source}, status={status}')
"
```

## The auth.json Pattern (Container-Level Env Vars)

When DEEPSEEK_API_KEY shows as `***` in `.env` but the system works,
the key is often set at **container launch time** via Docker `-e` or
the container runtime's own env. Hermes discovers it because:

1. `auth.json` references `"source": "env:DEEPSEEK_API_KEY"`
2. The credential pool reads from the process environment at runtime
3. The `.env` file's `***` is just a placeholder for Hermes Agent's
   own credential resolution — the container provides the real key

**Do NOT assume `***` in `.env` means the key is missing.** Always
cross-check with `auth.json` and `echo $VAR_NAME`.

## Key Length Validation

When a value appears truncated in terminal output:

```python
# Check actual byte lengths against known patterns
with open('/home/hermeswebui/.hermes/.env') as f:
    for line in f:
        if '=' in line:
            k, v = line.strip().split('=', 1)
            print(f'{k}: {len(v)} chars')
```

**Known key length reference:**

| Key | Expected Length |
|-----|----------------|
| DEEPSEEK_API_KEY | 35 |
| OPENROUTER_API_KEY | 73 |
| SUPABASE_SECRET_KEY | 41 |
| SUPABASE_ANON_KEY | 46 |
| RESEND_API_KEY | 36 |
| BROWSER_USE_API_KEY | 46 |
| FAL_KEY | 69 |
| GITHUB_TOKEN | 40 |
| VERCEL_TOKEN | 60 |
| TAVILY_API_KEY | 58 |
| FIGMA_ACCESS_TOKEN | 45 |
| N8N_API_TOKEN | ~272 (JWT) |

If the length matches the expected value, the terminal was lying —
the value is complete. Proceed without asking the user to re-paste.

## Pitfall: "You won't even work if the key was actually missing"

If you tell a user their API key is missing when it's actually set at
the container level, you lose credibility. Always verify all three
sources (.env, process env, auth.json) before reporting a missing key.
