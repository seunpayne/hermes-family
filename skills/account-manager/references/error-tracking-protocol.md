# Error Tracking Protocol

Used by Consigliere for the weekly error report and ongoing error log maintenance.

## File Location

`~/.hermes/workspace/.learnings/ERRORS.md` — the single source of truth for system errors.

## Error Log Format

Each error entry in ERRORS.md must include:

```
## [YYYY-MM-DD] — [severity] — [Short Title]
**Issue:** [What went wrong]
**Status:** 🔴 OPEN / ✅ RESOLVED / 🟡 INTERMITTENT
**Impact:** [What this blocks or affects]
**Action needed:** [Exact steps to fix]
**Age:** [days since first logged]
```

When resolved, add:
```
**Resolved:** [YYYY-MM-DD] — [how it was verified]
```

## Weekly Error Report Protocol (Consigliere, every Monday)

### Step 1 — Read ERRORS.md
Load the full ERRORS.md file.

### Step 2 — Verify Each Open Entry
For every entry marked **OPEN**, verify current reality:

- **Credentials** — test the actual key/token (curl, CLI, API call). Don't trust the old "missing" label.
- **Installations** — check if the tool is now installed (`which`, `--version`).
- **Configurations** — check if setup was completed since the entry was created.
- **Bug fixes** — check if the issue was resolved via alternative means.

### Step 3 — Correct Stale Entries
If an OPEN entry is actually resolved:
- Change status to ✅ RESOLVED
- Add a `**Resolved:**` line with the verification date
- Add a note explaining what was found

### Step 4 — Scan errors.log
Read the tail of `~/.hermes/logs/errors.log` for new warnings/errors from the past week.

### Step 5 — Identify Patterns
Look for:
- Same error appearing across multiple cron runs → systemic issue, not transient
- Errors sharing a root cause → consolidate into one entry
- Errors that self-resolved after retry → mark as intermittent, not open

### Step 6 — Flag 7+ Day Entries
Any entry marked OPEN for > 7 days needs explicit flagging to Seun.

### Step 7 — Rewrite ERRORS.md
Rewrite the file with:
1. All entries sorted by age (newest first)
2. Corrected statuses
3. New entries added
4. Resolved entries kept for history (don't delete them)

### Step 8 — Generate Report
Output the report in the format shown in `references/weekly-error-report-format.md`

## Common Pitfalls

### Stale entries that LOOK critical but aren't
Three entries were 20-21 days old and marked OPEN but fully resolved:
- **RESEND_API_KEY missing** — key was already in `.env` and working
- **Vercel CLI not installed** — installed and authenticated all along
- **Supabase not configured** — 7 env vars present, linked project works

**Root cause:** The entry was created during bootstrap when these things weren't set up. They were fixed later but ERRORS.md was never updated.

**Prevention:** Every weekly report MUST verify OPEN entries by actually testing credentials/tools — don't just read what the file says.

### Overwriting vs appending
When updating ERRORS.md:
- **Resolved entries**: update in place (change status, add resolution note)
- **New entries**: add at the top (newest first)
- **Old unresolved entries**: move to bottom, keep them visible but don't delete

## When to Escalate

Escalate to Seun when:
- Any OPEN entry has been stale for > 7 days
- A credential that blocks production operations is missing
- A pattern of failures suggests a systemic issue
- The error log file is growing rapidly (> 1000 new lines/week)
