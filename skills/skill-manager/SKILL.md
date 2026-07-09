---
name: skill-manager
description: Tracks every installed skill, detects updates, and ensures nothing changes silently. Manages skill lifecycle including install, update, pin, and disable operations.
---

# Skill Manager Skill

## Activation

**When activated:**
1. Gatekeeper pre-flight runs automatically
2. Query Supabase `skills_manifest` table for all active skills
3. Say: **"skill-manager loaded. [X] skills registered. What would you like to do?"**

---

## COMMAND 1 — Check for Updates

**When "check updates" is received or on scheduled weekly run:**

### For every skill where `source` is `clawhub`:
1. Run `clawhub info [clawhub_id]` to retrieve the latest published version
2. Compare against the `version` column in `skills_manifest`

### For every skill where `source` is `openclaw-master-skills`:
1. Check the GitHub repo for the latest commit on that skill's file
2. Compare against `last_checked` timestamp

### For every skill where `source` is `custom` or `manual`:
1. Skip — custom skills do not have upstream versions
2. Update `last_checked` timestamp only

### Update `skills_manifest` for each skill checked:
```sql
UPDATE skills_manifest
SET
 last_checked = now(),
 latest_version = '[fetched version]',
 update_available = '[true if latest > current]',
 updated_at = now()
WHERE name = '[skill name]';
```

### Report results:
```
SKILL UPDATE CHECK — [date]

UP TO DATE: [count]
UPDATES AVAILABLE: [count]

[For each skill with update available:]
 [skill name]
 Current: [version]
 Latest: [latest_version]
 Source: [clawhub / openclaw-master-skills]
 Pinned: [yes / no]

Run 'review update [skill name]' to see what changed.
Run 'approve update [skill name]' to schedule the update.
Run 'pin [skill name]' to skip updates for that skill permanently.
```

---

## COMMAND 2 — Review an Update

**When "review update [skill name]" is received:**

1. **Fetch the changelog or diff** for the skill from ClawHub or GitHub
2. **Display a plain English summary** of what changed
3. **Flag any changes that could affect existing workflows**
4. **Flag any new dependencies** the update introduces
5. **Say:** "Type 'approve update [skill name]' to apply or 'pin [skill name]' to skip this and future updates."

---

## COMMAND 3 — Approve and Apply an Update

**When "approve update [skill name]" is received:**

### This is a destructive action — confirm before proceeding

**Say:** "This will replace the current [skill name] skill file. The existing version will be backed up first. Type APPROVE to continue."

### When APPROVE is received:

1. **Back up the current skill file** to `~/.openclaw/backups/skills/[skill-name]-[version]-[timestamp].md`

2. **Apply the update** via:
   - `clawhub install [clawhub_id]` (for ClawHub skills)
   - Pull from GitHub (for openclaw-master-skills)

3. **Update `skills_manifest`:**
   ```sql
   UPDATE skills_manifest
   SET
    version = latest_version,
    update_available = false,
    update_reviewed = true,
    update_approved = true,
    updated_at = now()
   WHERE name = '[skill name]';
   ```

4. **Run a quick activation test** on the updated skill to confirm it loads without errors

5. **If activation fails:**
   - Restore the backup immediately
   - Alert Seun

6. **Log the update as a decision in Supabase:**
   ```sql
   INSERT INTO decisions (
    project_id,
    client_id,
    made_by,
    decision,
    rationale,
    affects,
    reversible
   ) VALUES (
    null,
    null,
    'Seun',
    'Updated skill [skill-name] from version [old] to [new]',
    'Manual approval after update review',
    ARRAY['architecture'],
    true
   );
   ```

7. **Say:** "[skill name] updated to version [new version]. Previous version backed up."

---

## COMMAND 4 — Pin a Skill

**When "pin [skill name]" is received:**

```sql
UPDATE skills_manifest
SET pinned = true, updated_at = now()
WHERE name = '[skill name]';
```

**Say:** "[skill name] pinned. It will be excluded from all future update checks."

**Pinned skills are never updated automatically or flagged in update reports.**

---

## COMMAND 5 — Install a New Skill

**When "install skill [skill name or clawhub URL]" is received:**

1. **Search ClawHub** for the skill
2. **Display the skill description, author, rating, and security assessment**
3. **Ask:** "Install this skill? Type APPROVE to confirm."
4. **On APPROVE:** install the skill and add it to `skills_manifest`:
   ```sql
   INSERT INTO skills_manifest (
    name, version, source, clawhub_id, file_path, status
   ) VALUES (
    '[name]', '[version]', 'clawhub', '[id]', '[path]', 'active'
   );
   ```

---

## COMMAND 6 — Disable a Skill

**When "disable skill [skill name]" is received:**

```sql
UPDATE skills_manifest
SET status = 'disabled', updated_at = now()
WHERE name = '[skill name]';
```

**Disabled skills remain in the manifest but cannot be loaded by any agent until re-enabled.**

---

## COMMAND 7 — List All Skills

**When "list skills" is received:**

```sql
SELECT
 name,
 version,
 source,
 status,
 update_available,
 pinned,
 last_checked
FROM skills_manifest
ORDER BY source ASC, name ASC;
```

**Display as a clean table.**

---

## Scheduled Run

**Every Monday at 8am, skill-manager automatically runs "check updates"** and includes the results in the Account Manager morning briefing if any updates are available.

---

## Supabase Tables Used

- `skills_manifest` — Read/write skill registry
- `decisions` — Log skill update decisions
- `agent_runs` — Log skill-manager operations

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.hermes`
- `SUPABASE_SECRET_KEY` from `~/.env.hermes`

---

## Reference Documents

- `references/openclaw-hermes-migration.md` — Systematic migration patterns for converting OpenClaw-era skills to Hermes conventions. Use when auditing remaining openclaw-imports skills.

---

## Error Handling

If update application fails:
1. Restore backup immediately
2. Log failure to `agent_runs`
3. Alert Seun with error details
4. Mark skill as `pending-update` in manifest
5. Do not retry without approval

If ClawHub or GitHub is unreachable:
1. Log error to `agent_runs`
2. Mark check as incomplete
3. Retry on next scheduled run
4. Alert Seun if unreachable for more than 24 hours
