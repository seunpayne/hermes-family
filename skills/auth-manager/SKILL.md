---
name: auth-manager
description: Centralized credential management for all services used across skills. Check, configure, and verify API keys, tokens, and authentication for GitHub, Vercel, Supabase, Resend, Google OAuth, OpenAI, Stability AI, Replicate, Deploy Kit, autoskills, and more.
---

# Auth Manager Skill

## Activation

When this skill is loaded/activated:

1. **Say**: "auth-manager loaded. Running credential check..."
2. **Check** `~/.env.openclaw` for existing credentials
3. **Check** Deploy Kit installation
4. **Check** Node.js version for autoskills requirement
5. **Test** each service that has credentials configured
6. **Guide** user through setting up missing credentials
7. **Return** status table when complete

## Credential File

**Primary location:** `~/.hermes/.env` (Hermes Agent standard)
**Legacy/alias location:** `~/.env.openclaw` (OpenClaw compatibility)

**Critical:** Always check `~/.hermes/.env` first. If it exists, that's the source of truth.
The `.env.openclaw` file may exist for backward compatibility but should mirror `.hermes/.env`.

**Format:**
```bash
# GitHub
GITHUB_TOKEN=ghp_xxxx

# Vercel (managed via vercel CLI login)
VERCEL_TOKEN=xxxx

# Supabase
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=xxxx
SUPABASE_SERVICE_ROLE_KEY=xxxx

# Resend
RESEND_API_KEY=re_xxxx

# Google OAuth
GOOGLE_CLIENT_ID=xxxx
GOOGLE_CLIENT_SECRET=xxxx
GOOGLE_REFRESH_TOKEN=xxxx

# OpenAI
OPENAI_API_KEY=sk-xxxx

# Stability AI
STABILITY_API_KEY=xxxx

# Replicate
REPLICATE_API_TOKEN=xxxx

# FAL AI
FAL_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx
```

**Note on paths with spaces:** If any credential value contains spaces (e.g., file paths like `/Applications/Google Chrome.app/...`), wrap the value in quotes:
```bash
AGENT_BROWSER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```
Unquoted paths with spaces will cause shell sourcing errors.

Format:
```bash
# GitHub
GITHUB_TOKEN=ghp_xxxx

# Vercel (managed via vercel CLI login)
VERCEL_TOKEN=xxxx

# Supabase
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=xxxx
SUPABASE_SERVICE_ROLE_KEY=xxxx

# Resend
RESEND_API_KEY=re_xxxx

# Google OAuth
GOOGLE_CLIENT_ID=xxxx
GOOGLE_CLIENT_SECRET=xxxx
GOOGLE_REFRESH_TOKEN=xxxx

# OpenAI
OPENAI_API_KEY=sk-xxxx

# Stability AI
STABILITY_API_KEY=xxxx

# Replicate
REPLICATE_API_TOKEN=xxxx
```

## Services to Check

### GitHub

**Check:** Look for `GITHUB_TOKEN` in `~/.env.openclaw` or `~/.hermes/.env` plus SSH key at `~/.ssh/id_ed25519`

**If missing:**
1. Guide user to https://github.com/settings/tokens
2. Generate classic token with scopes: `repo`, `workflow`, `read:org`
3. Save to `~/.hermes/.env`:
   ```bash
   GITHUB_TOKEN=ghp_xxxx
   ```
4. **Also check gh CLI:** `gh auth status` — prints OK if logged in regardless of token method

**Test:**
```bash
# Test token via API
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user

# Test SSH
ssh -T git@github.com

# Test gh CLI
gh auth status
```

**If token returns 401:** The token is expired or has insufficient scopes. Generate a new one. Tokens in `ghp_` format (classic) expire if no expiration was set to 'no expiration'. Fine-grained tokens need to be authorized for the org.

### Vercel

**Check:** Look for `VERCEL_TOKEN` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://vercel.com/account/tokens
2. Create new token (Account Settings → Tokens)
3. Save to `~/.env.openclaw`:
   ```bash
   VERCEL_TOKEN=***
   ```

**Test:**
```bash
curl -H "Authorization: Bearer $VERCEL_TOKEN" https://api.vercel.com/v9/projects
```

### Supabase

**Check:** Look for `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` in `~/.env.openclaw`

**Note:** If env file uses `NEXT_PUBLIC_` prefixed versions (e.g., `NEXT_PUBLIC_SUPABASE_URL`),
add plain aliases to `~/.env.openclaw` for agent use:
```bash
# Aliases for agent use (if NEXT_PUBLIC_ versions exist)
SUPABASE_URL="$NEXT_PUBLIC_SUPABASE_URL"
SUPABASE_ANON_KEY="$NEXT_PUBLIC_SUPABASE_ANON_KEY"
SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY"
```

**If missing:**
1. Guide user to Supabase dashboard → Select project → Settings → API
2. Copy:
   - Project URL
   - `anon` public key
   - `service_role` key (secret, warn user)
3. Save to `~/.env.openclaw`

**Test (service_role key — only secret keys access root endpoint):**
```bash
# Anon key — query an actual table, not the root endpoint (root requires service_role)
curl -s "$SUPABASE_URL/rest/v1/projects?limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -w '\nHTTP: %{http_code}'

# Service role key — query decisions table directly
curl -s "$SUPABASE_URL/rest/v1/decisions?limit=1" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -w '\nHTTP: %{http_code}'
```
**Expected:** HTTP 200. Empty array `[]` with anon key means the key works but RLS blocks that table — test against a table that allows anon access. Service role should always return data for any table.
```

### FAL AI

**Check:** Look for `FAL_KEY` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://fal.ai/dashboard/keys
2. Create API key
3. Save to `~/.env.openclaw`:
   ```bash
   FAL_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx
   ```

**Test (MUST use POST — GET returns 405 Method Not Allowed):**
```bash
curl -H "Authorization: Key $FAL_KEY" https://fal.run/fal-ai/flux-2-pro \
  -X POST -H "Content-Type: application/json" \
  -d '{"prompt":"test","num_images":1}'
```

### Resend

**Check:** Look for `RESEND_API_KEY` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://resend.com/api-keys
2. Create API key
3. Save to `~/.env.openclaw`

**Test:**
```bash
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"from":"onboarding@resend.dev","to":"delivered@resend.dev","subject":"test","html":"test"}'
```

### Slack

**Check:** Look for `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS` in `~/.hermes/.env`

**If missing:**
1. Generate the Slack app manifest:
   ```bash
   hermes slack manifest --write
   ```
   Writes to `~/.hermes/slack-manifest.json`
2. Go to https://api.slack.com/apps → **Create New App** → **From an app manifest**
3. Paste the manifest, save, **Install to Workspace** → copy **Bot Token** (`xoxb-...`)
4. **Settings → Socket Mode** → enable → generate **App-Level Token** (`xapp-...`) with scope `connections:write`
5. Get your **Slack Member ID** (right-click name → Copy member ID, e.g. `U01ABC2DEF3`)
6. Save to `~/.hermes/.env`:
   ```bash
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_APP_TOKEN=xapp-...
   SLACK_ALLOWED_USERS=U...       # comma-separated
   SLACK_HOME_CHANNEL_NAME=general  # optional — for cron delivery
   ```
7. Restart gateway: `hermes gateway restart`
8. Invite `@hermes` to the desired channel

**Test:**
```bash
hermes gateway status
grep -i slack ~/.hermes/logs/agent.log | tail -5
```

**Bolt startup signal:** `⚡️ Bolt app is running!` in agent.log confirms Slack connected.
**Troubleshooting:** If bot works in DMs but not channels → missing `message.channels` event subscription (reinstall app after adding it).

**Reference:** See `references/slack-delivery-setup.md` for the full setup walkthrough including WebUI-specific patterns, stale-platform-token cleanup, and cron delivery diagnostics.

### Tavily (Web Search API)

**Check:** Look for `TAVILY_API_KEY` in `~/.hermes/.env`

**Test:**
```bash
curl -s -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"query\":\"test\",\"max_results\":1}" \
  -w '\nHTTP: %{http_code}'
```

### Figma API

**Check:** Look for `FIGMA_ACCESS_TOKEN` in `~/.hermes/.env`

**Test:**
```bash
curl -s -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN" \
  https://api.figma.com/v1/me \
  -w '\nHTTP: %{http_code}'
```

### DeepSeek API

**Check:** Look for `DEEPSEEK_API_KEY` in `~/.hermes/.env`

**⚠️ Important:** DeepSeek's API is text-only — it does NOT support vision/image input. If you need image analysis, configure a separate vision provider (OpenRouter + Gemini). See `image-analysis` skill for full setup.

**Test:**
```bash
curl -s https://api.deepseek.com/v1/models \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -w '\nHTTP: %{http_code}'
```

### OpenRouter API

**Check:** Look for `OPENROUTER_API_KEY` in `~/.hermes/.env`

**Test:**
```bash
curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -w '\nHTTP: %{http_code}'
```

### Google OAuth

**Reference:** See `references/supabase-google-oauth.md` for Supabase-specific OAuth configuration, redirect URI format, and troubleshooting `redirect_uri_mismatch` errors.

**Reference:** See `references/nextauth-google-oauth.md` for NextAuth.js Google OAuth setup pattern, task sequencing (T-001 → T-002), environment variable configuration, and common error resolutions.

**Reference:** See `references/nextauth-google-oauth-setup.md` for complete NextAuth.js + Supabase adapter integration pattern, including required packages (`--legacy-peer-deps`), file structure, TypeScript type extensions, Vercel environment variable setup via CLI, and troubleshooting common build errors (peer deps, missing root layout, node_modules type errors).

**Check:** Look for `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`

**If missing:**
1. Guide user to https://console.cloud.google.com/apis/credentials
2. Create OAuth 2.0 Client ID (Web application)
3. Add authorized redirect URIs
4. Download credentials
5. Save Client ID and Secret to `~/.env.openclaw`
6. Guide through OAuth flow to get refresh token

**Additional Google Services:**
For each service user needs, confirm scopes in OAuth consent screen:

| Service | Required Scopes |
|---------|----------------|
| Google Analytics | `https://www.googleapis.com/auth/analytics.readonly` |
| Google Search Console | `https://www.googleapis.com/auth/webmasters.readonly` |
| Google Drive | `https://www.googleapis.com/auth/drive.file` |
| Google Calendar | `https://www.googleapis.com/auth/calendar` |
| Gmail | `https://www.googleapis.com/auth/gmail.send` |

**Test:**
```bash
curl -H "Authorization: Bearer $GOOGLE_ACCESS_TOKEN" \
  https://www.googleapis.com/oauth2/v1/userinfo
```

### OpenAI API

**Check:** Look for `OPENAI_API_KEY` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://platform.openai.com/api-keys
2. Create new secret key
3. Save to `~/.env.openclaw`

**Test:**
```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Stability AI

**Check:** Look for `STABILITY_API_KEY` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://platform.stability.ai/account/keys
2. Create API key
3. Save to `~/.env.openclaw`

**Test:**
```bash
curl https://api.stability.ai/v1/engines/list \
  -H "Authorization: Bearer $STABILITY_API_KEY"
```

### Replicate

**Check:** Look for `REPLICATE_API_TOKEN` in `~/.env.openclaw`

**If missing:**
1. Guide user to https://replicate.com/account/api-tokens
2. Copy API token
3. Save to `~/.env.openclaw`

**Test:**
```bash
curl -H "Authorization: Token $REPLICATE_API_TOKEN" \
  https://api.replicate.com/v1/models
```

### Deploy Kit

**Check:** Run `clawhub list` or check if Deploy Kit commands are available

**If not installed:**
1. Run `clawhub install hugosbl/deploy-kit`
2. Confirm installation successful

**Test:** Run a Deploy Kit command to verify it's working

### autoskills

**Check:** Run `node -v` to verify Node.js version

**Requirement:** Node.js 22 or higher

**If below version 22:**
1. Prompt user to update Node.js:
   - Via nvm: `nvm install 22` then `nvm use 22`
   - Via brew: `brew install node@22`
2. Verify version is now 22+
3. Note: autoskills requires Node.js 22+

**Test:** `npx autoskills --version` (if available)

### Additional Services

If user names a service not listed:

1. Ask for:
   - Service name
   - Credential name/key format
   - Where to obtain it (URL)
   - Test endpoint (if available)
2. Prompt user to paste the credential
3. Save to `~/.env.openclaw` as `[SERVICE]_API_KEY` or appropriate name
4. Test if endpoint provided

## Workflow

### Step 1: Check Existing Credentials

**Discovery order:**
1. Check `~/.hermes/.env` first (Hermes standard location)
2. Check `~/.env.openclaw` for legacy/alias entries
3. If both exist, `.hermes/.env` is source of truth

```bash
# Check primary location first
if [ -f ~/.hermes/.env ]; then
  set -a; source ~/.hermes/.env; set +a
  echo "Credentials loaded from ~/.hermes/.env"
elif [ -f ~/.env.openclaw ]; then
  set -a; source ~/.env.openclaw; set +a
  echo "Credentials loaded from ~/.env.openclaw"
else
  echo "No credential file found. Create ~/.hermes/.env"
  exit 1
fi
# Check each variable
```

### Step 2: Check Deploy Kit and autoskills

```bash
# Check Deploy Kit
clawhub list | grep deploy-kit

# Check Node.js version
node -v
# Must be v22 or higher
```

### Step 3: Test Each Service

For each service with credentials:
- Make lightweight API call
- Record pass/fail
- Record timestamp

### Step 4: Guide Missing Setup

For each missing credential:
- Explain what it's for
- Provide URL to obtain it
- Prompt user to paste (use secure input if possible)
- Save to `~/.env.openclaw`
- Test immediately

### Step 5: Return Status Table

```markdown
## Credential Status

| Service | Authenticated | Test Passed | Last Verified |
|---------|--------------|-------------|---------------|
| GitHub | ✅ | ✅ | 2026-05-11 06:00 |
| Vercel | ✅ | ✅ | 2026-05-11 06:00 |
| Supabase | ❌ | - | - |
| Resend | ✅ | ✅ | 2026-05-11 06:00 |
| Google OAuth | ✅ | ✅ | 2026-05-11 06:00 |
| OpenAI | ✅ | ✅ | 2026-05-11 06:00 |
| Stability AI | ❌ | - | - |
| Replicate | ❌ | - | - |
| Deploy Kit | ✅ Installed | ✅ | 2026-05-11 06:00 |
| autoskills | Node v24.15.0 | ✅ | 2026-05-11 06:00 |

All credentials verified. You are ready to run any skill.
```

## Security Rules

- **NEVER** display credentials in plain text after saving
- **NEVER** commit `~/.env.openclaw` or `~/.hermes/.env` to git (add to `.gitignore`)
- **ALWAYS** test credentials immediately after saving
- **ALWAYS** use HTTPS endpoints for testing (not HTTP)
- **WARN** user before saving service role keys or admin-level credentials

## PITFALLS

### Visually truncated .env values (Hermes Docker environment)

When `cat ~/.hermes/.env` shows `GITHUB_TOKEN=***` or `SUPABASE_SECRET_KEY=sb_sec...`, the `***` is a VISUAL truncation in the terminal display — the actual file has the full value. Do NOT ask the user to re-paste their keys.

**Verification pattern (check byte length):**
```python
python3 -c "
import os
for k in ['GITHUB_TOKEN', 'SUPABASE_SECRET_KEY', 'DEEPSEEK_API_KEY', 'FAL_KEY']:
    v = os.environ.get(k, '')
    print(f'{k}: present={bool(v)} length={len(v)} first={v[:4] if v else \"(empty)\"} last={v[-4:] if v else \"(empty)\"}')
"
```
If length > 10, the value is real. The display truncation is cosmetic. Source `~/.hermes/.env` first (`set -a; source ~/.hermes/.env; set +a`) then verify with this byte-length check. Never ask for a re-paste.

### gh CLI not installed

If `which gh` returns nothing, GitHub is still accessible via the token in `.env`:
```bash
source ~/.hermes/.env
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user
```
Use `git remote add origin https://seunpayne:${GITHUB_TOKEN}@github.com/seunpayne/[repo].git` for pushes. The token in `.env` is a classic PAT with `repo` scope.

## References

- `references/supabase-key-formats.md` — Supabase key format variants (classic JWT vs. new `sb_publishable_`/`sb_secret_` prefixes), sequential auth diagnostics, and exhaust-verification protocol
- `references/hermes-docker-credentials.md` — Credential discovery in Hermes Docker env: visual truncation (`***` display), byte-length verification pattern, multi-location check order, GitHub without gh CLI
- `references/credential-health-cron-pattern.md` — How to run credential checks from cron jobs (testing matrix, false-negative handling, reporting rules, redacted-`.env` detection)
- `references/credential-pool-health.md` — Reading health signals from `~/.hermes/auth.json` credential pool for redacted/inaccessible credentials
- `references/slack-delivery-setup.md` — Full Slack setup walkthrough for Hermes WebUI, including token collection, gateway restart, home channel configuration, stale-platform cleanup, and cron delivery diagnostics
- `references/nextauth-google-oauth.md` — NextAuth.js Google OAuth setup
- `references/supabase-google-oauth.md` — Supabase-specific OAuth configuration
- `references/nextauth-google-oauth-setup.md` — Complete NextAuth.js + Supabase integration

## Credential Expiry & Rotations

Credentials can expire silently. Watch for these patterns:

- **401 responses** — most common sign of an expired API key. If a service returns 401 and the key looks valid, it's likely expired. Generate a new one.
- **SSH permission denied** — SSH keys don't expire but `known_hosts` can fail on first connection. Run `ssh -o StrictHostKeyChecking=accept-new -T git@github.com` to accept the host fingerprint.
- **CLI auth status** — some CLIs (gh, vercel, supabase) maintain independent sessions via tokens. `gh auth status` can fail even if `GITHUB_TOKEN` in `.env` is valid. Check both.
- **403 responses** — usually means the key is valid but lacks the scope/permission for the endpoint. Check scopes.
- **405 responses** — wrong HTTP method (e.g., GET to a POST-only endpoint). Try the method specified in the service's API docs, not an arbitrary test.

**Key rotation protocol:** When `grep -c "^TEST_PASSED=false"` would be the pattern. Notify Seun with the service name, the error code, and a link to generate a new key. Never rotate keys autonomously.

## Integration with Other Skills

All skills should check `~/.env.openclaw` at activation:

```bash
if [ ! -f ~/.env.openclaw ]; then
  echo "Missing credentials. Run: load skill auth-manager"
  exit 1
fi
set -a; source ~/.env.openclaw; set +a
# Check required credentials for this skill
if [ -z "$REQUIRED_VAR" ]; then
  echo "Missing REQUIRED_VAR. Run: load skill auth-manager"
  exit 1
fi
```

Each skill documents which credentials it requires in its SKILL.md activation checklist.
