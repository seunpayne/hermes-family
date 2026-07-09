---
name: hermes-migration
description: "Migrate a full Hermes installation (skills, config, cron, memory) to a new machine. Never transfers credentials."
version: 1.0.0
author: The Don (Seun's delivery system)
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [migration, backup, restore, hermes-to-hermes, docker, container]
    related_skills: [system-backup, system-restore, hermes-agent, hermes-permissions-repair]
---

# Hermes Migration Skill

Migrates the full OpenClaw delivery system (The Don + 12 agents) from one Hermes installation to another. Handles skills, configuration, cron jobs, and memory. Credentials are never included — they must be re-entered manually.

## Activation

**When Seun says "migrate my hermes" or "move to a new machine":**
1. Say: **"Migration prep running. I'll capture the current state into a manifest first."**
2. Run Step 1 through Step 4 on the SOURCE machine.
3. Then Step 5 through Step 9 on the TARGET machine.

---

## Phase A — SOURCE MACHINE (Current Install)

### Step 1 — Generate Migration Manifest

Run a current-state capture. Ask Seun to confirm the path, then:

```bash
# Capture timestamp
echo "MIGRATION_DATE=$(date +%Y-%m-%d)"

# Count skills
echo "SKILL_COUNT=$(find ~/.hermes/skills -name 'SKILL.md' | wc -l)"

# Dump cron jobs
hermes cron list

# List credential keys (names only, NEVER values)
grep -E '^[A-Z_]' ~/.hermes/.env | cut -d= -f1 | sort
```

Write the manifest to `~/workspace/hermes-migration-manifest-YYYY-MM-DD.json`. Use the template in `references/manifest-template.json`.

### Step 2 — Package Skills

```bash
cd ~/.hermes
tar -czf ~/workspace/hermes-skills-$(date +%Y%m%d).tar.gz skills/
```

Verify:
```bash
tar -tzf ~/workspace/hermes-skills-*.tar.gz | head -20
echo "Total files: $(tar -tzf ~/workspace/hermes-skills-*.tar.gz | wc -l)"
```

⚠️ **Check:** The tarball MUST contain `skills/openclaw-imports/` — this is the 40-skill family agent library. If missing, the target machine won't have the Don or any agents.

### Step 3 — Copy Config (Sanitized)

```bash
# Copy config — it contains no secrets (only provider names, not keys)
cp ~/.hermes/config.yaml ~/workspace/hermes-config-backup.yaml
```

**Review the config backup before transfer.** Confirm these fields contain no credential values:
- `model.api_key` — should be empty or reference env var
- `gateway` sections — should not contain raw tokens

If any secrets are found in config.yaml, strip them before transfer.

### Step 4 — Prepare Transfer Package

Collect all portable files:
```
~/workspace/
├── hermes-migration-manifest-YYYY-MM-DD.json
├── hermes-skills-YYYYMMDD.tar.gz
└── hermes-config-backup.yaml
```

Transfer to the new machine via:
- AirDrop (macOS → macOS)
- USB drive
- scp / rsync
- Private GitHub repo (clone on target)

**Never email or upload to public services.** The config backup may contain internal hostnames and IPs.

---

## Phase B — TARGET MACHINE (Fresh Install)

### Step 5 — Install Hermes

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# Verify
hermes --version
hermes doctor
```

### Step 6 — Restore Skills

```bash
# Extract skills into the new Hermes home
cd ~/
tar -xzf ~/Downloads/hermes-skills-YYYYMMDD.tar.gz -C ~/.hermes/

# Verify critical skills present
ls ~/.hermes/skills/*/gatekeeper/SKILL.md ~/.hermes/skills/gatekeeper/SKILL.md 2>/dev/null
ls ~/.hermes/skills/*/builder/SKILL.md ~/.hermes/skills/builder/SKILL.md 2>/dev/null
ls ~/.hermes/skills/*/account-manager/SKILL.md ~/.hermes/skills/account-manager/SKILL.md 2>/dev/null
ls ~/.hermes/skills/*/coding-project/SKILL.md ~/.hermes/skills/coding-project/SKILL.md 2>/dev/null

# Reload skill index
hermes skills list | head
```

### Step 7 — Rebuild Config

Option A — Copy and edit the backup:
```bash
cp ~/Downloads/hermes-config-backup.yaml ~/.hermes/config.yaml
hermes config edit   # Adjust paths for the new machine
```

Option B — Fresh config, add providers manually:
```bash
hermes setup model
# Add: deepseek (DEEPSEEK_API_KEY), openrouter (OPENROUTER_API_KEY), fal (FAL_KEY)
hermes config set model.default deepseek-v4-pro
hermes config set model.provider deepseek
hermes config set auxiliary.vision.provider openrouter
hermes config set auxiliary.vision.model google/gemini-2.5-flash
```

### Step 8 — Re-enter Credentials

**This is the critical step.** Every API key must be re-entered.

Open `~/.hermes/.env`:
```bash
hermes config env-path
```

Add each key from the manifest's `credential_keys` list. **At minimum these are required for the delivery system to function:**

| Key | Used By |
|-----|---------|
| `DEEPSEEK_API_KEY` | The Don, Clemenza, execution agents |
| `OPENROUTER_API_KEY` | Michael (planning), vision tasks |
| `SUPABASE_URL` | All agents (project state) |
| `SUPABASE_SECRET_KEY` | Consigliere, DB writes |
| `RESEND_API_KEY` | Email delivery |
| `TELEGRAM_BOT_TOKEN` | Gateway notifications |
| `BROWSER_USE_API_KEY` | Cloud browser QA |
| `FAL_KEY` | Image generation (Apollonia) |
| `GITHUB_TOKEN` | Code pushes (Clemenza) |
| `VERCEL_TOKEN` | Deployments |

After entering all keys:
```bash
hermes doctor --fix
```

### Step 9 — Recreate Cron Jobs

Reference the manifest's `cron_jobs` list. Recreate each:

```bash
# Example: Daily health check
hermes cron create "0 10 * * *" \
  --name "consigliere-daily-health-check" \
  --prompt "Run the consigliere daily health check..."

# Or use the cronjob tool in-session:
# cronjob(action='create', schedule='0 10 * * *', name='...', prompt='...')
```

**Verify all jobs are active:**
```bash
hermes cron list
```

### Step 10 — Setup Gateway (Optional)

```bash
hermes gateway setup
# Select Telegram
# Enter bot token from @BotFather
# Set home channel
hermes gateway install   # Auto-start on login
hermes gateway status    # Verify running
```

---

## Phase C — Docker Container Migration (Alternative Path)

When the target is a **Docker container** (not a bare-metal machine), the workflow differs in several critical ways:

### C1 — Permissions Are the First Hurdle

Inside Docker containers, files are often root-owned. Before you can write skills, config, or any files:

```bash
# From the DOCKER HOST (not inside the container)
docker exec -u 0 <container-name> sh -c "chown -R <uid>:<gid> /home/<user>/.hermes"
```

**Critical verification:** Check both the DIRECTORY and its contents:
```bash
# Test write to a file inside a subdirectory
touch /home/user/.hermes/skills/any-skill/test_write && rm /home/user/.hermes/skills/any-skill/test_write
# If this fails, the directory (not just files) is still root-owned
```

**Why:** Tools like `patch` create temp files (`.hermes-tmp.*`) in the target directory. If the directory itself is root-owned, edits silently fail with "Permission denied" even if the individual files are writable.

### C2 — Skills Transfer (No Tarball)

Since you have interactive shell access via the WebUI:

1. Create a category folder on the target:
   ```bash
   mkdir -p ~/.hermes/skills/"Your Category Name"
   ```

2. Move each skill directory into the category (one-by-one or loop):
   ```bash
   cd ~/.hermes/skills
   for d in */; do
     [ "$d" = "Your Category Name/" ] && continue
     mv "$d" "Your Category Name/"
   done
   ```

3. Verify all skills are visible:
   ```bash
   hermes skills list
   ```

### C3 — Config Migration (Clean-Config Approach)

The old config.yaml is often 450+ lines but only ~35 are actually custom. The rest are defaults the agent assumes. **Do not copy the full backup — distill it:**

| Keep | Strip |
|------|-------|
| `model.*` (provider, default, base_url) | All `terminal.*` (defaults) |
| `agent.*` (max_turns, timeouts) | All `web.*` / `browser.*` (defaults) |
| `compression.*` (if non-default) | All `checkpoints.*` (defaults) |
| `memory.*` (char limits) | All `tool_output.*` (defaults) |
| `display.*` (language, show_cost) | All `tool_loop_guardrails.*` (defaults) |
| `approvals.*` (mode) | All `delegation.*` (defaults — needs API key) |
| `cron.*` (wrap_response) | All `auxiliary.*` (defaults — most need API keys) |
| `skills.disabled` | All platform configs (slack, discord, telegram, etc.) |
| | All `bedrock.*`, `model_catalog.*`, `lsp.*` (defaults) |

Write the cleaned config:
```yaml
model:
  default: deepseek-v4-flash
  provider: deepseek
  base_url: https://api.deepseek.com

agent:
  max_turns: 50
  gateway_timeout: 1800
  clarify_timeout: 600

compression:
  enabled: true
  threshold: 0.5
  target_ratio: 0.2
  protect_last_n: 20

memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200
  user_char_limit: 1375

display:
  show_cost: true
  language: en

approvals:
  mode: manual
  cron_mode: deny

cron:
  wrap_response: true

skills:
  disabled: []
```

### C4 — Reading the .env File (Terminal Truncation Gotcha)

**Critical:** When you `cat ~/.hermes/.env`, the terminal **visually truncates long lines with `...` in the middle.** The file has the full value — the display lies.

**Do NOT ask the user to re-paste keys.** Instead, read the file properly:

```bash
# Method 1: Check actual byte lengths
python3 -c "
with open('/home/hermeswebui/.hermes/.env') as f:
    for line in f:
        line = line.strip()
        if '=' in line:
            k, v = line.split('=', 1)
            print(f'{k}: {len(v)} chars')
"

# Method 2: Read full values in hex to verify completion
python3 -c "
with open('/home/hermeswebui/.hermes/.env', 'rb') as f:
    for line in f:
        if line.startswith(b'SUPABASE_SECRET_KEY='):
            val = line.split(b'=', 1)[1].strip()
            print(f'Full value: {val.decode()}')
"
```

**Common key lengths to validate against:**
| Key | Expected Length | Pattern |
|-----|----------------|---------|
| DEEPSEEK_API_KEY | 35 chars | `sk-` prefix + 32 hex |
| SUPABASE_SECRET_KEY | 41 chars | `sb_secret_` + 32 chars |
| SUPABASE_ANON_KEY | 46 chars | `sb_publishable_` + 34 chars |
| RESEND_API_KEY | 36 chars | `re_` prefix |
| BROWSER_USE_API_KEY | 46 chars | `bu_` prefix |
| VERCEL_TOKEN | 60 chars | `vcp_` prefix |
| TAVILY_API_KEY | 58 chars | `tvly-` prefix |
| FIGMA_ACCESS_TOKEN | 45 chars | `figd_` prefix |
| N8N_API_TOKEN | ~272 chars | JWT (base64-encoded JSON) |
| FAL_KEY | 69 chars | UUID-like with `:` separator |

If a value's length doesn't match, the user genuinely needs to re-paste that specific key. Otherwise, the data is complete and you can proceed.

### C5 — Migrate Identity Files (SOUL.md / AGENTS.md)

The source installation may have custom identity files that define the agent's
persona, routing rules, and operating protocol. These are the files that make
a generic Hermes installation into *your* delivery system.

**Files to migrate:**

| File | Purpose | Target Location |
|------|---------|-----------------|
| `SOUL.md` | Identity, routing, hard rules, family structure | `~/.hermes/SOUL.md` |
| `AGENTS.md` | Agent instructions, startup context | Project root (e.g., `/app/AGENTS.md`) |

**Migration steps:**

1. Copy the raw content from the source files.
2. **Adapt paths** — The source may reference skill locations like
   `skills/openclaw-imports/`. Update these to the actual category name
   on the target machine (e.g., `skills/Family Skills/`).
3. **Strip platform-specific sections** — Remove gateway platform configs
   (Telegram, Discord, WhatsApp, group chat rules) if the target is
   WebUI-only. Keep the core routing protocol and identity.
4. **Update model routing** — Match the source's model hierarchy to what's
   available on the target. Document which models use which providers.
5. Write to target locations:
   ```bash
   # SOUL.md goes to ~/.hermes/
   cat > ~/.hermes/SOUL.md << 'EOF'
   ...
   EOF

   # AGENTS.md goes to the project root
   cat > /app/AGENTS.md << 'EOF'
   ...
   EOF
   ```

**Note on category names:** The source installation may have used
`openclaw-imports/` as a skill category directory, while the target may use
a different name like `Family Skills/`. When adapting SOUL.md's skill routing
section, use the target's actual category name — the Hermes skill loader
reads `~/.hermes/skills/<category>/<skill-name>/` and displays the category
name in the skills index.

### C6 — Permissions Final Check

After everything is restored, verify no root-owned files remain:

```bash
find ~/.hermes -not -user $(whoami) 2>/dev/null | head -20
# Should return nothing
```

If any root-owned files remain, run the docker exec chown again from the host.

Run this checklist on the target machine:

```
✓ hermes --version returns expected version
✓ hermes doctor shows all green
✓ hermes skills list shows all expected skills (100+ including gatekeeper, builder, coding-project)
✓ hermes config shows correct model routing
✓ hermes cron list shows all 7 jobs active
✓ Supabase connection verified (query projects table)
✓ Telegram gateway sends/receives messages
✓ delegate_task spawns a working subagent
✓ The Don routes a test message correctly
```

**Final test:** Send "Nike, you there?" via Telegram. If The Don responds, migration is complete.

---

## What NEVER Transfers

- **`~/.hermes/.env`** — All API keys. Re-enter manually.
- **`~/.hermes/auth.json`** — OAuth tokens. Re-auth manually.
- **`~/.hermes/sessions/`** — Session transcripts. Optional convenience copy.
- **Any credential value.** Names only in the manifest.

---

## Disaster Recovery Notes

If the source machine is dead and no backup exists:

1. **Skills:** The family skills can be regenerated — they are procedural knowledge, not state. The critical ones (gatekeeper, builder, account-manager, coding-project, web-builder) are the delivery backbone.
2. **Config:** Rebuild from the SOUL.md specification — model routing table is documented.
3. **Cron jobs:** Recreate from memory/manifest. The schedules are known patterns (daily at 7/8/9/10am, weekly Monday).
4. **Supabase state:** Fully cloud-hosted. No local state to lose.
5. **Memory:** Will rebuild naturally over sessions. Supabase is the durable source of truth for projects, clients, tasks, and decisions.

The only irreplaceable asset is the skill library. **Always back up `~/.hermes/skills/` somewhere.** A private GitHub repo is ideal:
```bash
cd ~/.hermes
git init
git add skills/
git commit -m "Skill library backup — $(date +%Y-%m-%d)"
git remote add origin git@github.com:seunpayne/hermes-skills-backup.git
git push -u origin main
```

---

## Environment Variables

- None required for the migration process itself.
- All listed credential keys needed on the target machine for system operation.

---

### C10 — Enable Cron Scheduling (Docker WebUI)

After migration, cron jobs exist in the job store but **won't fire automatically**.
The cron scheduler runs inside the Hermes gateway daemon, which is not started
by default in a WebUI-only Docker container.

**Fix — Auto-start gateway with the WebUI server:**

Patch `server.py` to spawn the gateway as a background subprocess at
startup, right before `httpd.serve_forever()`:

```python
try:
    import subprocess
    _gw = subprocess.Popen(
        [sys.executable, '-m', 'hermes_cli', 'gateway', 'run'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    logger.info("Gateway started (PID: %s) for cron", _gw.pid)
except Exception:
    logger.debug("Gateway auto-start skipped")
```

**Fallback (manual start):**

```bash
/app/venv/bin/hermes gateway run &
```

### C11 — Parallel Work via delegate_task

Use `delegate_task` with the `tasks` array for independent parallel audits:

```python
delegate_task(
    tasks=[
        {"goal": "Audit A...", "toolsets": ["terminal", "file"]},
        {"goal": "Audit B...", "toolsets": ["terminal", "file"]},
    ]
)
```

Max 3 concurrent children. Children cannot delegate/clarify/memory/execute_code.
Always verify side effects — results are self-reported.

### C12 — Configure Delegation Model (Michael)

Independent of the main orchestration model:

```yaml
delegation:
  model: deepseek-v4-pro
  provider: deepseek
  base_url: https://api.deepseek.com
```

The Don uses cheap `deepseek-v4-flash` for routing.
Michael uses capable `deepseek-v4-pro` for planning.
Different models, different budgets.

### C7 — Migrate Cron Jobs (Pattern Reference)

See `references/cron-setup-patterns.md` for the full schedule table, delivery targets, and naming conventions. Key patterns:

- Convert Lagos time to UTC: subtract 1 hour
- Replace all Obsidian references with Outline (MCP)
- Scope `enabled_toolsets` to reduce token burn
- Use `"origin"` delivery for persistence, `"telegram"` for alerts

### C8 — Post-Migration: Outline / MCP Servers

After migrating skills and config, add MCP servers if Outline or other services
are used. See `references/mcp-server-config.md` for auth formats.

**Cloudflare note:** If the MCP endpoint returns Error 1010 (Access denied),
the server IP needs to be allowlisted in Cloudflare. See
`references/cloudflare-waf-troubleshooting.md` for the fix.

### C9 — Post-Migration: Secure Discovered Services

After migration, audit services that are accessible from the container but
lack authentication:

- **Cloud Commander** (port 8084, HTTP): See `references/cloud-commander-security.md`.
- **Portainer** (port 80/9000): Verify it requires a login. If not, configure
  authentication in Portainer's admin settings.
- **Any HTTP 200 response** on `172.17.0.1:<port>/`: Check what it is and
  whether it needs auth.

General approach:
1. Scan open ports: `curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:<port>/`
2. Identify the service from the HTML response or HTTP headers
3. Check if it has an API endpoint for enabling auth
4. Configure auth + save credentials to `.env`
5. Note to the user that the fix is in-memory — Docker env vars needed for persistence

## Error Handling

| Failure | Action |
|---------|--------|
| Skills tarball missing `openclaw-imports/` | Re-pack from source. This is the critical directory. |
| config.yaml contains secrets | Strip them before transfer. Never transfer raw credentials. |
| `hermes doctor` fails on target | Install missing dependencies. `brew install node git` if needed. |
| Cron jobs don't fire | Check timezone. Africa/Lagos = UTC+1. Adjust schedules. |
| Supabase connection fails | Verify SUPABASE_URL and SUPABASE_SECRET_KEY. Test with `supabase status`. |
| Gateway not delivering | Check TELEGRAM_BOT_TOKEN. Re-run `hermes gateway setup`. |

## Working with Seun (Communication Style)

**Seun communicates directly and expects the same.** Key preferences:

- **Verify before questioning.** If the system is running (chat works, APIs
  respond), do not assume the credentials are missing because a terminal
  display truncated a line with `...`. The `.env` file typically has full
  values — the terminal view lies. Use Python `len()` or hex decoding to
  confirm before asking Seun to re-paste keys.
- **Fix permanently, not one-at-a-time.** If permissions are broken across
  a directory tree, chown the entire tree at once (`~/.hermes`), not each
  subdirectory individually. If multiple files need editing, batch them.
  Seun should not have to run the same docker exec command three times.
- **Short, direct responses.** Present findings as bullet points or tables.
  Lead with the result, not the process. "X done" is better than "I've gone
  ahead and done X by following steps...".
- **Never change a configuration without asking first.** Seun will correct
  you immediately if you alter a service's root path, auth state, or any
  setting he explicitly uses. Always report what you found and ask "want me
  to fix it?" before taking action — especially for services like Cloud
  Commander where full filesystem access is the intended purpose.
- **Don't explain what you're about to do — just do it and report.** Back-
  ground reasoning is fine in tool calls; the human-facing message should
  be the outcome.
- **When Seun says "check well o",** you made an incorrect assumption.
  Re-verify your data before responding. Common failure: mistaking terminal
  visual truncation for incomplete file values.
- **"I cannot keep pasting keys na" means** the approach needs to change.
  Find a way to read the existing data correctly (Python byte-level reads,
  hex decoding) instead of asking for re-entry.
