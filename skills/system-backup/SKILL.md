---
name: system-backup
description: Creates full system manifests and backups of all Hermes control plane files, skills, and configuration. Runs weekly on Sunday at midnight and on-demand. Never backs up credentials.
---

# System Backup Skill

## Activation

**When activated:**
1. Say: **"system-backup running. Creating full system manifest..."**
2. This skill runs automatically every Sunday at midnight and whenever you type `run system-backup`

---

## Step 1 — Capture System Manifest

**Collect the current state of everything and write it to `~/.hermes/system-manifest.json`:**

```json
{
  "version": "1.0",
  "captured_at": "[timestamp]",
  "owner": "Seun",
  "machine": "[hostname]",
  "os": "[macOS version]",
  "runtime": {
    "node_version": "[node -v output]",
    "npm_version": "[npm -v output]",
    "hermes_version": "[hermes --version output]"
  },
  "homebrew_packages": [
    "[brew list output — one entry per package]"
  ],
  "global_npm_packages": [
    "[npm list -g --depth=0 output]"
  ],
  "control_plane_files": [
    "~/.hermes/system-policy.json",
    "~/.hermes/handoff-schema.json",
    "~/.hermes/handoff-rules.md",
    "~/.hermes/decision-rules.md",
    "~/.hermes/decision-interface.md",
    "~/.hermes/memory-rules.md",
    "~/.hermes/memory-interface.md",
    "~/.hermes/system-manifest.json"
  ],
  "skills": [
    {
      "name": "[skill name]",
      "version": "[version if known]",
      "source": "hermes skills hub | manual | hermes-master-skills",
      "path": "[skill file path]",
      "installed_at": "[timestamp]"
    }
  ],
  "agents": [
    "architect",
    "account-manager",
    "gatekeeper",
    "builder",
    "designer",
    "writer",
    "doc-builder"
  ],
  "supabase": {
    "project_url": "[SUPABASE_URL from env — value not included]",
    "tables": [
      "clients", "projects", "tasks", "agent_runs",
      "decisions", "credentials_status", "assets",
      "deployments", "billing_events", "invoices",
      "escalations", "memory"
    ]
  },
  "credential_keys": [
    "[list of key names from ~/.env.hermes — names only, never values]"
  ],
  "scheduled_tasks": [
    {
      "name": "account-manager morning briefing",
      "schedule": "0 8 * * *"
    },
    {
      "name": "account-manager midday check",
      "schedule": "0 13 * * *"
    },
    {
      "name": "account-manager end of day",
      "schedule": "0 18 * * *"
    },
    {
      "name": "escalation background check",
      "schedule": "*/30 * * * *"
    },
    {
      "name": "gatekeeper credential health check",
      "schedule": "0 */6 * * *"
    },
    {
      "name": "system-backup",
      "schedule": "0 0 * * 0"
    }
  ]
}
```

---

## Step 2 — Back Up All Control Plane Files

**Copy every file listed in `control_plane_files` to a backup directory:**
```
~/.hermes/backups/[timestamp]/
```

**Copy all skill files to:**
```
~/.hermes/backups/[timestamp]/skills/
```

---

## Step 3 — Push Backup to GitHub

1. **Check if a private GitHub repo called `hermes-system-backup` exists**
2. **If not:** create it — `gh repo create hermes-system-backup --private`
3. **Commit and push the entire backup directory:**

```bash
cd ~/.hermes/backups/[timestamp]
git init
git add .
git commit -m "System backup — [timestamp]"
git remote add origin git@github.com:[username]/hermes-system-backup.git
git push origin main --force
```

**Never push `~/.env.hermes` — credentials are never backed up to GitHub**

---

## Step 4 — Log Backup to Supabase

```sql
INSERT INTO agent_runs (
 project_id,
 agent,
 task,
 status,
 outputs_created
) VALUES (
 null,
 'system-backup',
 'Weekly system manifest backup',
 'done',
 '["~/.hermes/backups/[timestamp]/", "github:hermes-system-backup"]'
);
```

**Say:** "System backup complete. Manifest saved locally and pushed to GitHub. Credentials not included — re-enter those manually on restore."

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.hermes`
- `SUPABASE_SECRET_KEY` from `~/.env.hermes`
- `GITHUB_TOKEN` from `~/.env.hermes`

---

## Error Handling

If GitHub push fails:
1. Log error to `agent_runs`
2. Alert Seun with error details
3. Keep local backup intact
4. Do not retry more than twice without approval

If manifest generation fails:
1. Log error to `agent_runs`
2. Surface missing information to Seun
3. Do not proceed with backup until manifest is valid

---

## Scheduled Execution

Use Hermes `cron` tool to schedule weekly backups:
- Schedule: `0 0 * * 0` (Sunday at midnight, Africa/Lagos timezone)
- Action: Run full system backup sequence
