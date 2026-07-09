---
name: project-manager
description: Track and manage projects via a JSON registry. Use to list, update, add, or archive projects with status and deployment URLs.
---

# Project Manager Skill

## Activation Checklist

When this skill is loaded/activated:

1. **Check for registry** - Look for `~/Projects/registry.json`
2. **If it doesn't exist**, create it: `echo '[]' > ~/Projects/registry.json`
3. **Read current projects** from registry
4. **Say**: "project-manager loaded. You have [X] active projects."

## Project Schema

Each project entry:

```json
{
  "name": "project-name",
  "status": "active|completed|archived|paused",
  "url": "https://deployment-url.com",
  "path": "~/Projects/client-builds/project-name",
  "notes": "Additional context or todo items",
  "createdAt": "2026-05-11",
  "updatedAt": "2026-05-11"
}
```

## Commands

### `list projects`

- Read `~/Projects/registry.json`
- Show all projects with:
  - Name
  - Status
  - Deployment URL (if any)
  - Last updated date
- Format as a clean table or list

### `add project` — DUPLICATE CHECK REQUIRED

**BEFORE creating a new project record:**

1. **Search Supabase projects table:**
   ```sql
   SELECT id, name, status FROM projects 
   WHERE name ILIKE '%[project-name]%';
   ```

2. **Check Kanban board:**
   ```bash
   hermes kanban list
   ```

3. **Search session history:**
   ```bash
   session_search(query="[project-name] project")
   ```

4. **Check registry.json:**
   ```bash
   cat ~/Projects/registry.json | grep -i "[project-name]"
   ```

**PITFALL:** Creating duplicate project records wastes tokens, confuses tracking, and requires cleanup. The Foremost Capital incident (May 27, 2026) — created duplicate Supabase record when project already existed in Kanban — is the canonical example of what NOT to do.

**Rule:** If ANY system returns a match, do NOT create. Use the existing record.

### `update [project-name]`

- Find project in registry
- Ask what to update: status, notes, URL, or other fields
- Update the entry
- Set `updatedAt` to current date
- Write back to `registry.json`
- Confirm the update

### `add project`

- Ask for:
  - Project name
  - Initial status (default: "active")
  - URL (optional)
  - Path (optional)
  - Notes (optional)
- Create new entry with `createdAt` and `updatedAt`
- Append to registry
- Write to `registry.json`
- Confirm addition

### `archive [project-name]`

- Find project in registry
- Set status to "archived" (or "completed")
- Update `updatedAt`
- Write to `registry.json`
- Confirm archival

### `status [project-name]` — Full Project Health Check

Pull comprehensive project state across all systems. Use this when asked to "pull up" a project, "what's the status of X", or "check on X."

**CRITICAL — ORDER MATTERS.** Supabase records are *recorded state* that may lag days behind reality. Filesystem and Vercel are *ground truth*. Query ground truth FIRST, then compare Supabase to it. Never form conclusions from Supabase alone.

**Step 1 — Filesystem check (ground truth #1):**
```bash
# List ALL matching directories with sizes and modification times
find ~/Projects/clients -maxdepth 1 -type d -iname "*[project-name]*" -exec ls -ld {} \;
```

**PITFALL — Multiple Directories:** A project may have MORE THAN ONE directory. This is the single most common cause of stale project reports. If multiple directories exist:
- The **newest** (most recent mtime) is the active working copy
- Older directories with suffixes (`-FAILED`, `-OLD`, etc.) are stale
- Check BOTH to understand the project history, but report from the NEWEST
- Never report project state from a stale directory without checking for a newer one

Once you've identified the active directory, inspect it:
```bash
# Check for real artifacts
ls -la <active-dir>/public/images/   # real images or placeholder SVGs?
ls -la <active-dir>/dist/            # build output exists?
git -C <active-dir> log --oneline -5 # recent commits?
cat <active-dir>/DEPLOYMENT.md 2>/dev/null || cat <active-dir>/README.md 2>/dev/null
```

Check for content population (grep for real names, not placeholders):
```bash
grep -r "TODO\|placeholder\|RC Number\|TBD" <active-dir>/src --include="*.tsx" | head -10
```

**Step 2 — Vercel check (ground truth #2):**

The Vercel CLI is authenticated as `seunpayne-9311`. Use it directly — the curl+token approach is unreliable (token file location varies and the token may be stale).

```bash
# List all projects (find the match)
vercel projects list 2>&1 | grep -i "[search-term]"

# Get deployments for a specific project
vercel list <project-name> 2>&1
```

The `vercel list` output shows:
- Deployment URL, age, status (Ready/Error), environment (Production/Preview), duration
- The top Production entry is the current live deployment
- The `vercel projects list` output shows: Project Name, Latest Production URL, Updated, Node Version

**PITFALL — Vercel may have deployments even when Supabase shows no `production_url`.** Always check Vercel directly before reporting "not deployed."

**Step 3 — Supabase query (recorded state):**
```bash
curl -s "$SUPABASE_URL/rest/v1/projects?select=*&or=(name.ilike.*[project-name]*,name.ilike.*[PROJECT-NAME]*)&order=updated_at.desc" \
  -H "apikey: $SUPABASE_SECRET_KEY" \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY"
```

If client_id is not null, also pull the client record. Pull tasks, agent_runs, decisions, and deployments filtered by project_id.

**PITFALL — "Bare" Supabase Record:** When a project in Supabase shows `status: active` but has ALL of these characteristics:
- `created_at == updated_at` (never updated since creation)
- `production_url` is null AND `staging_url` is null
- `client_id` is null
- Zero tasks logged
- Zero decisions logged
- Only 1 agent run (usually Consigliere receiving the super prompt)

...this is a STRONG signal that the Supabase record is stale and the project continued on disk without updating the database. The project was likely built, iterated, and deployed — but Supabase was never synced. **Treat this as a red flag: check ground truth (filesystem + Vercel) first, and expect Supabase to be behind.** Do NOT report "project is not deployed" or "no client record exists" based solely on a bare Supabase record.

**PITFALL — Memory "session sync needed" Signal:** When the SOUL.md active projects list or your injected memory says "session sync needed" next to a project, that means Seun or another agent already flagged that Supabase is behind. Treat this as advance warning that the Supabase record will be stale.

**Step 4 — Cross-reference ground truth vs. recorded state:**
- Does Supabase status match filesystem reality?
- Are there MULTIPLE project directories? If so, which is newest?
- Does Vercel show deployments that Supabase doesn't know about?
- Are there real images on disk but Supabase shows no asset decisions?
- Is the git history richer than the Supabase agent_runs suggest?

**Step 5 — Report format:**

Present a clean summary that clearly distinguishes what you observed from ground truth vs. what's in Supabase:
- Project name, status, stack, dates
- **Ground truth:** Vercel deployment status (production URL, latest deploy age, total deploys) + filesystem reality (path, artifacts, images, content)
- **Supabase state:** Record health (client linked? tasks logged? decisions recorded? deployment URLs populated?)
- **Gaps:** What ground truth shows that Supabase doesn't know about
- **Missing:** What still needs doing (content gaps, credentials, deployment)
- Next actions required

**Step 6 — After presenting the status:** ask if Seun wants you to sync Supabase to match ground truth, or resume/repair the project.

## Notes

- **Ground truth first, Supabase second.** When pulling up a project, check filesystem and Vercel BEFORE Supabase. Supabase records what was recorded — filesystem and Vercel record what actually happened.
- **"Bare" Supabase records are red flags.** If a project shows `active` but has no deployments, no tasks, no client, and `created_at == updated_at`, assume Supabase is stale. Do not report "not deployed" or "no client" — check ground truth first.
- **"Session sync needed" in memory/SOUL.md** means Supabase is already known to be behind for that project. Treat it as advance warning.
- Always update `updatedAt` on any change
- Validate JSON before writing
- Keep registry clean - no duplicate names
- Back up before major operations if possible
- Filesystem directory naming carries state that Supabase may not reflect — always check both
- For known filesystem naming signals (FAILED, ABANDONED, STALE), see `references/filesystem-state-signals.md`
- For decisions table schema and insert patterns, see `references/supabase-decisions-schema.md`
- Vercel CLI (`vercel list`, `vercel projects list`) is preferred over curl+token for deployment checks
- Always check for multiple project directories before reporting state
- After reporting project state, always offer to sync Supabase to match ground truth if gaps exist
