---
name: system-restore
description: Rebuilds the full Hermes delivery system on a fresh machine from GitHub backup. Restores all control plane files, skills, scheduled tasks, and verifies Supabase connection. Never restores credentials automatically — requires manual re-entry.
---

# System Restore Skill

## Activation

**When activated on a fresh machine:**
1. Say: **"system-restore running. This will rebuild your full Hermes delivery system. You will need your GitHub credentials and all API keys ready. Type READY to begin."**
2. **Wait for READY before proceeding**

---

## RESTORE SEQUENCE — Run Every Step in This Exact Order

### Step 1 — Install Hermes + Core Dependencies

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js, Git, Python, and GitHub CLI
brew install node git python@3.11 gh

# Install Hermes Agent
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# Authenticate GitHub
gh auth login

# Install Hermes Agent
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
# Install Vercel CLI
npm install -g vercel

# Install Playwright
npm install -g playwright
npx playwright install chromium

# Install Lighthouse CI
npm install -g @lhci/cli

# Install ngrok
brew install ngrok
```

**Confirm each installation before proceeding to the next.**

---

### Step 2 — Clone System Backup from GitHub

```bash
git clone git@github.com:[username]/hermes-system-backup.git ~/hermes-restore
```

**Read `system-manifest.json` from the cloned backup to confirm what needs to be restored.**

---

### Step 3 — Restore Control Plane Files

**Copy all files from `~/hermes-restore/[latest-backup]/` to `~/.hermes/`:**

- `system-policy.json`
- `handoff-schema.json`
- `handoff-rules.md`
- `decision-rules.md`
- `decision-interface.md`
- `memory-rules.md`
- `memory-interface.md`

**Verify each file exists and is valid after copying.**

---

### Step 4 — Restore All Skills

**For each skill listed in the manifest:**

- **If source is hermes skills hub:** run `hermes skills hub install [skill-name]`
- **If source is hermes-master-skills:** copy from backup
- **If source is manual:** copy from backup

**Confirm each skill is loaded after installation.**

---

### Step 5 — Restore Project Workspace Directories

```bash
mkdir -p ~/Projects/client-builds
mkdir -p ~/Projects/content
mkdir -p ~/Projects/reviews
mkdir -p ~/Projects/assets
mkdir -p ~/Projects/docs
mkdir -p ~/Projects/logs
```

---

### Step 6 — Restore Credentials

**Display the list of credential keys from the manifest and prompt for each value one at a time:**

```
The following credentials need to be re-entered.
Values are never stored in the backup for security.
Enter each one when prompted:

[1/13] GITHUB_TOKEN:
[2/13] VERCEL_TOKEN:
[3/13] SUPABASE_URL:
[4/13] SUPABASE_SECRET_KEY:
[5/13] RESEND_API_KEY:
[6/13] OPENAI_API_KEY:
[7/13] STABILITY_AI_KEY:
[8/13] REPLICATE_API_KEY:
[9/13] GOOGLE_CLIENT_ID:
[10/13] GOOGLE_CLIENT_SECRET:
[11/13] GOOGLE_REFRESH_TOKEN:
[12/13] DEPLOY_KIT_TOKEN:
[13/13] AUTOSKILLS_TOKEN:
```

**Write each entered value to `~/.env.hermes` immediately.**

**Never display entered values after saving.**

**Run a Gatekeeper credential health check after all values are entered.**

---

### Step 7 — Verify Supabase Connection

1. **Connect to Supabase using restored credentials**
2. **Confirm all 12 tables exist**
3. **Run a test query on the `decisions` table**
4. **If any table is missing:** display the missing table names and say: "Run the Supabase state tables prompt to recreate missing tables."

---

### Step 8 — Authenticate External Services

```bash
# Vercel
vercel login

# GitHub CLI (if not already done)
gh auth status
```

---

### Step 9 — Restore Scheduled Tasks

**For each scheduled task in the manifest, recreate the cron schedule in Hermes:**

- Account Manager morning briefing at 8am
- Account Manager midday check at 1pm
- Account Manager end of day at 6pm
- Escalation background check every 30 minutes
- Gatekeeper credential health check every 6 hours
- System backup every Sunday at midnight

**Confirm all schedules are active.**

---

### Step 10 — Run Full System Readiness Check

**Verify everything is in place:**

```
SYSTEM RESTORE VERIFICATION

Core runtime:
 Node.js: [version] — [✓ / ✗]
 Hermes: [version] — [✓ / ✗] — [✓ / ✗]
 Vercel CLI: [version] — [✓ / ✗]
 Playwright: [version] — [✓ / ✗]
 Lighthouse CI: [version] — [✓ / ✗]

Control plane:
 system-policy: [✓ / ✗]
 handoff-schema: [✓ / ✗]
 handoff-rules: [✓ / ✗]
 decision-rules: [✓ / ✗]
 memory-rules: [✓ / ✗]

Skills: [count restored] / [count in manifest]
 [list any missing skills]

Supabase tables: [count found] / 12
 [list any missing tables]

Credentials: [count verified] / [count in manifest]
 [list any unverified credentials]

Scheduled tasks: [count active] / [count in manifest]

OVERALL STATUS: [READY / INCOMPLETE]
```

**If INCOMPLETE:** list every item that needs attention with a specific instruction for fixing it.

**If READY:** say "System fully restored. All agents, skills, and schedules are active. Run load skill account-manager to begin."

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.hermes`
- `SUPABASE_SECRET_KEY` from `~/.env.hermes`
- `GITHUB_TOKEN` from `~/.env.hermes`

---

## Error Handling

If any step fails:
1. Log error to `agent_runs`
2. Surface missing information to Seun
3. Do not proceed to next step until current step is resolved
4. Escalate Supabase table recreation to Seun for manual execution

---

## Security Notes

- **Never store credential values in backups**
- **Never display credential values after entry**
- **Always use `~/.env.hermes` with chmod 600**
- **Always verify GitHub repo is private before pushing backups**
