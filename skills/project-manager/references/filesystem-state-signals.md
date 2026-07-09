# Filesystem State Signals

The filesystem directory naming convention carries out-of-band project
state that Supabase may not reflect. Always check the actual directory
name when pulling up a project.

## Known Suffixes

| Suffix | Meaning | Action |
|---|---|---|
| `-FAILED-YYYY-MM-DD` | Build session crashed or was abandoned on that date. Code may be partially built. | Audit what was built vs. what's missing. Check if a NEWER directory without the suffix exists BEFORE resuming. |
| `-ABANDONED` | Project was started but never completed. | Same as FAILED — check artifacts and newer directories before deciding. |
| `-STALE` | Project hasn't been touched in weeks/months. | Check if still relevant. May need stack updates. |
| (no suffix) | Normal operational project. | Standard workflow. |

## Multiple Directories — Critical Signal

A project may have **more than one** directory. This is the #1 cause of stale project reports. When you see multiple directories for the same project:

```
~/Projects/clients/tmg-capital-FAILED-2026-05-12/    ← older, stale
~/Projects/clients/tmg-capital/                       ← newer, active
```

**Always:**
1. List ALL matching directories with modification times
2. The **newest** (most recent mtime) is the active working copy
3. Older directories with suffixes are stale — reference them for history only
4. Report from the **newest** directory
5. Never report project state from a stale directory without checking for a newer one first

**Pitfall**: Running `find` and stopping at the first match. Always check for multiple results.

## Canonical Example: TMG Capital (May–June 2026)

Two directories exist:
- `tmg-capital-FAILED-2026-05-12/` — Original build session (May 12). 8 pages built, placeholder SVGs only, no Vercel deployment. The session crashed/abandoned. **Stale.**
- `tmg-capital/` — Resumed build (May 12–18). Real images, real logos, leadership names filled, deployed to Vercel (https://tmg-capital.vercel.app, 8 deploys). **Active.**

Supabase `projects` table: status = `active`, but `production_url` was `null`, `staging_url` was `null`, `client_id` was `null` — the DB record wasn't kept current with the actual deployed state.

**Lesson**: A `-FAILED` directory doesn't mean the project is dead. It means the FIRST attempt failed. Always check for a newer, working directory alongside it.
