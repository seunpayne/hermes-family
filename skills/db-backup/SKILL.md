---
name: db-backup
description: Creates daily supplementary JSON backups of all Supabase tables. Exports, verifies, encrypts, and pushes to GitHub. Runs at 2am daily and on-demand. Never silently fails.
---

# DB Backup Skill

## Activation

**When activated:**
1. Gatekeeper pre-flight runs automatically
2. Confirm Supabase credentials are valid in `~/.env.openclaw`
3. Say: **"db-backup running..."**

**This skill runs automatically every day at 2am and whenever you type `run db-backup`.**

---

## BACKUP SEQUENCE

### Step 1 — Export All Tables to JSON

**Create backup directory:**
```bash
BACKUP_DIR=~/.openclaw/db-backups/$(date +%Y-%m-%d)
mkdir -p $BACKUP_DIR
```

**Export full SQL dump:**
```bash
supabase db dump --data-only > $BACKUP_DIR/full-dump.sql
```

**Export individual tables as JSON for readability:**

Tables to export (13 total):
- `clients`, `projects`, `tasks`, `agent_runs`
- `decisions`, `credentials_status`, `assets`
- `deployments`, `billing_events`, `invoices`
- `escalations`, `memory`, `skills_manifest`

**Using Supabase client:**
```javascript
const tables = [
 'clients', 'projects', 'tasks', 'agent_runs',
 'decisions', 'credentials_status', 'assets',
 'deployments', 'billing_events', 'invoices',
 'escalations', 'memory', 'skills_manifest'
];

for (const table of tables) {
 const { data } = await supabase
 .from(table)
 .select('*');

 fs.writeFileSync(
 `${backupDir}/${table}.json`,
 JSON.stringify(data, null, 2)
 );
}
```

---

### Step 2 — Verify Backup Integrity

**For each exported file:**

1. **Confirm the file exists and is not empty**
2. **Count the records in the export**
3. **Compare against a live count from Supabase**

```javascript
const { count } = await supabase
 .from(table)
 .select('*', { count: 'exact', head: true });

// Compare against exported record count
// Flag any mismatch as a backup integrity error
```

**If any mismatch is found:**
- Log the discrepancy
- Re-run the export for that table
- If mismatch persists: escalate to Seun immediately
- **Do not mark backup as complete until all tables verify**

---

### Step 3 — Encrypt the Backup

```bash
# Encrypt the backup directory before pushing anywhere
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
openssl enc -aes-256-cbc -salt \
 -in $BACKUP_DIR.tar.gz \
 -out $BACKUP_DIR.enc \
 -k $BACKUP_ENCRYPTION_KEY
rm $BACKUP_DIR.tar.gz
```

**Store `BACKUP_ENCRYPTION_KEY` in `~/.env.openclaw`.**

**Never push unencrypted backups anywhere.**

---

### Step 4 — Push to GitHub

```bash
cp $BACKUP_DIR.enc ~/openclaw-restore/db-backups/
cd ~/openclaw-restore
git add db-backups/
git commit -m "DB backup — $(date +%Y-%m-%d)"
git push origin main
```

---

### Step 5 — Enforce Retention Policy

**Keep the last 30 daily backups locally and on GitHub.**

**Delete anything older:**
```bash
# Local retention — keep 30 days
find ~/.openclaw/db-backups/ -name "*.enc" \
 -mtime +30 -delete

# GitHub retention — keep 30 most recent commits on db-backups path
# Handled automatically by keeping only 30 local files before push
```

---

### Step 6 — Log Backup to Supabase

```sql
INSERT INTO agent_runs (
 project_id,
 agent,
 task,
 status,
 outputs_created,
 risks
) VALUES (
 null,
 'db-backup',
 'Daily database backup',
 '[done or failed]',
 '["~/.openclaw/db-backups/[date].enc", "github:openclaw-system-backup/db-backups/[date].enc"]',
 '[any integrity warnings]'
);
```

---

### Step 7 — Report

```
DB BACKUP COMPLETE — [date]

Tables exported: 13 / 13
Records verified: [total record count]
Integrity check: [passed / warnings]
Encrypted: yes
Pushed to GitHub: yes
Backup size: [file size]
Retention: [count] backups stored (30 day limit)
Oldest backup: [date]

STATUS: [COMPLETE / WARNINGS / FAILED]
```

**If any failure: escalate to Seun immediately. Do not silently fail.**

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.openclaw`
- `SUPABASE_SECRET_KEY` from `~/.env.openclaw`
- `BACKUP_ENCRYPTION_KEY` from `~/.env.openclaw` (generate with `openssl rand -base64 32`)

---

## Error Handling

If export fails for any table:
1. Retry export up to 3 times
2. If still failing: log error to `agent_runs`
3. Escalate to Seun immediately
4. Do not proceed to encryption until all tables export successfully

If encryption fails:
1. Log error to `agent_runs`
2. Alert Seun
3. Do not push unencrypted data
4. Keep local backup intact for manual recovery

If GitHub push fails:
1. Log error to `agent_runs`
2. Alert Seun with error details
3. Keep local backup intact
4. Do not retry more than twice without approval

---

## Scheduled Execution

Use OpenClaw's `cron` tool to schedule daily backups:
- Schedule: `0 2 * * *` (2am daily, Africa/Lagos timezone)
- Action: Run full backup sequence

---

## Prerequisites

**Supabase CLI must be installed and authenticated:**
```bash
brew install supabase/tap/supabase
supabase login
supabase link --project-ref tqacwivrwfsdsjdnxblp
```

**Backup encryption key must be generated:**
```bash
openssl rand -base64 32 >> ~/.env.openclaw
# Add as: BACKUP_ENCRYPTION_KEY=[value]
```
