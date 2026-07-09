---
name: task-management
description: Task lifecycle, escalation timers, stall
  protocol, and retry rules. Load when managing task
  states, handling stalls, or running Consigliere's
  monitoring cycle.
---

# SKILL: task-management
# Version: 1.0
# Extracted from SOUL.md v1.x — May 2026

---

## PROJECT-LEVEL TRACKING (after every task)

Every task completion requires THREE updates in Supabase — not just marking the task done:

1. **Mark task done:**
   `PATCH /rest/v1/tasks?id=eq.{task_id}` → `{"status": "done"}`

2. **Log a decision:**
   `POST /rest/v1/decisions` with outcome + rationale + affects[] array
   The Don does this in the moment — not at end of session.

3. **Update project timestamp:**
   `PATCH /rest/v1/projects?id=eq.{project_id}` → `{"updated_at": "now()"}`
   This keeps the project list sortable by recency of activity.

If the next task is already known (e.g. user said "proceed"), create it with
`status: "in_progress"` BEFORE dispatching the sub-agent. This ensures the
chain is visible in the DB even if the sub-agent times out.

**PITFALL — Skipping these updates:** The user WILL ask "are you updating the
progress?" if the project-level timestamp is stale. Do not skip the project
timestamp and decision log — they are the primary audit trail.

## TASK LIFECYCLE

Every task moves through these states only:

  READY → ASSIGNED → IN_PROGRESS → REVIEW → DONE
                               ↘ FAILED → RETRY

**⚠️ Supabase tasks table status values (when writing via REST API):**
When creating or updating tasks in the `tasks` table directly, the
`status` column accepts only: `pending`, `in_progress`, `blocked`, `done`.
The canonical names above (READY, ASSIGNED, REVIEW, FAILED, RETRY) are
conceptual lifecycle states. Map them to DB values as:
- READY = `pending`
- ASSIGNED = `pending` (use assigned_to field)
- IN_PROGRESS = `in_progress`
- REVIEW = `in_progress`
- DONE = `done`
- FAILED = `blocked` (log reason in description)
- RETRY = `blocked` (move to RETRY conceptual state when unblocked)

Values like `ready`, `completed`, `open`, `cancelled` will be REJECTED
by the database check constraint (23514 error).

READY
  Task specification complete. All required fields present.
  Michael has confirmed no ambiguity.
  Confidence ≥ 0.75.

ASSIGNED
  The Don has delegated to a family member.
  One task. One agent. Never split across two.

IN_PROGRESS
  Agent executing. Consigliere monitors.
  Stall threshold: 30 minutes with no progress update.

REVIEW
  Agent has delivered output. Seun reviews.
  Escalation timer starts on entry to REVIEW.

DONE
  Seun approved. Supabase updated. Session synced.

FAILED
  Agent could not complete. Reason logged.
  Never abandoned. Always moves to RETRY.

RETRY
  Returns to Michael with failure reason appended.
  Michael updates specification with missing context.
  Returns to READY only when specification is complete.

---

## ESCALATION TIMER

REVIEW state > 4 hours:
  Send one Telegram reminder to Seun:
  "REVIEW WAITING — [task] — [project] —
   Waiting [N]hrs. No action needed if intentional."
  Send once only per 4-hour window.

REVIEW state > 24 hours:
  Send daily Telegram until resolved:
  "REVIEW PENDING — [task] — [project] —
   [N] days waiting. Action required."
  Log to escalations table on first 24-hour trigger.

BLOCKED state > 2 hours:
  Send Telegram immediately — do not wait:
  "BLOCKED — [task] — [agent] — [what is blocking]
   Action required."
  Repeat every 2 hours until resolved.

---

## CONSIGLIERE STALL PROTOCOL

Runs every 30 minutes alongside the escalation check.

Stall detected when:
  status = 'in_progress' AND
  updated_at < now() - interval '30 minutes'

On stall:
  Send Telegram: "STALLED — [task] — [agent] —
  Last update: [time]. Awaiting Seun decision:
  restart / retry / cancel."

Do NOT restart automatically.
Wait for Seun to decide.
Log to decisions table with stall reason.

---

## SYMPHONY TASK SPECIFICATION

Every task dispatched to a family member must include:

  Goal:       One sentence. What done looks like.
              Not what to do — what done looks like.
  Context:    Project path, relevant file paths,
              Supabase IDs, staging URL, all context
              needed to begin immediately.
  Acceptance: Testable conditions. Pass/fail only.
              No subjective criteria.
  Scope:      What to touch. What NOT to touch.
  Output:     File path, commit message, Telegram
              message, or Supabase record.

For execution tasks (code, SQL, CLI commands):
  CODE:    Actual code/SQL/commands to run.
           Not a description. The actual content.
  RUN:     Exact terminal command to execute.
  VERIFY:  Exact check that confirms success
           independently of the next task.
  REPORT:  PASS format with specific values.
           FAIL format with specific values.

A task without all fields is NOT ready.
Return to Michael. Do not dispatch.

The test: can the agent begin immediately
with no clarifying questions?
If no — not ready.

---

## RETRY PROTOCOL

FAILED tasks are never deleted or abandoned.
Every FAILED task moves to RETRY.

When moving to RETRY, document:
  - Original task specification
  - What the agent attempted
  - Where and why it failed
  - What information was missing
  - What the agent encountered that was unexpected

Michael receives RETRY tasks.
Michael updates the specification.
Michael adds the missing context.
Task returns to READY only when complete.

Do not redispatch without updated specification.
Redispatching an unchanged task produces the same failure.

---

## CONSIGLIERE CRON SUITE

This skill owns Consigliere's 7 cron jobs. Full schedule table, SQL queries,
and delivery conventions are in `references/consigliere-cron-suite.md`.

For diagnosing failing cron jobs — Broken pipe errors, delivery target
resolution failures, and systematic investigation workflow — see
`references/cron-job-diagnostics.md`.

The suite replaces all legacy Obsidian writes with Outline MCP documents in
the Consigliere Reports collection. The Hermes MCP client handles
Cloudflare auth automatically.

For connecting Slack as a cron delivery channel, see references/slack-delivery-setup.md.

## CREDENTIAL HEALTH PROBE (interactive)

When asked to check credentials interactively, query:

  SELECT service, status FROM credentials_status
  ORDER BY
    CASE status
      WHEN 'missing' THEN 1
      WHEN 'failed' THEN 2
      WHEN 'expired' THEN 3
      WHEN 'valid' THEN 4
      ELSE 5
    END;

Known services: replicate, stability_ai, google_oauth, google_analytics,
fal_ai, supabase, resend, github, google_drive, deploy_kit.

## HEALTH CHECK PROMPT (interactive)

Complete health check covers:
1. Supabase connection (query projects table, expect 5+ active)
2. Stalled tasks (count where status = 'stalled')
3. Credential health (query credentials_status, flag non-valid)

Output as a structured markdown report. The cron jobs write to Outline;
interactive checks go to the current chat.

---

## PROJECT LOG MAINTENANCE

**Standing rule:** Every project with a `PROJECT_LOG.md` MUST be kept current. This is not optional — Seun explicitly instructed: "Update it and always do that."

### When to Update the Log
- **After every EOD report** — log completion summary, blockers, decisions
- **Before every SOD brief** — verify the log reflects actual state, not stale data
- **On any status change** — payment received, phase transition, escalation raised/resolved
- **On any decision** — that affects scope, timeline, budget, or client communication

### What Gets Updated
- Header status line (phase + key metric)
- Daily log entry (SOD + EOD sections)
- Payment tracker table
- Timeline tracker table
- Risks & Blockers table

### Anti-Pattern (Do Not Repeat)
The cron-generated SOD briefs were reading a stale PROJECT_LOG.md for 4+ days because:
1. EODs were sent to supervisor externally but not logged to PROJECT_LOG.md
2. The Kanban board showed "payment done" but the log still showed "pending"
3. The cron kept generating reports from the stale file

**Fix:** Every session that touches a project MUST verify the log is current before reading from it. If the log is stale, update it first — then read.

### EOD Report Polishing
When Seun drops raw site notes, load `references/eod-report-format.md` for the polishing template. Key rules: never fabricate, use emoji markers, group into sections, flag overdue deadlines.
