# Cron Job Diagnostics

## Systematic Investigation Workflow

When alerted that cron jobs are failing, follow this sequence:

### Phase 1 — Gather System State

```bash
# 1. List all cron jobs with status
# Use the cronjob tool: action='list'

# 2. Identify failing vs healthy jobs
# Note: last_status, last_delivery_error, last_run_at

# 3. Check output directories on disk
ls -la ~/.hermes/cron/output/<job_id>/

# 4. Read both SUCCESS and FAILURE logs
# Success logs show what a healthy run looks like
# Failure logs show the error
```

### Phase 2 — Analyze Error Patterns

**Common cron job error signatures:**

| Error | Likely Cause | Next Step |
|-------|-------------|-----------|
| `RuntimeError: [Errno 32] Broken pipe` | Transport failure — agent completed work but failed to stream response back to scheduler. Usually a delivery target issue. | Check delivery target config and platform connectivity |
| `no delivery target resolved for deliver=origin` | No messaging platform connected (WebUI, CLI-only mode). `origin` can't resolve. | Switch to `deliver=local` or connect a platform |
| `no delivery target resolved for deliver=telegram` | Telegram not configured or bot token invalid. | Configure Telegram or change delivery target |
| `RuntimeError: [Errno 32] Broken pipe` on first run | Cron job was created in an environment that doesn't support the delivery type. | Fix delivery target before expecting the job to work |
| HTTP 401/403 on data fetch | Credentials stale or wrong auth method. | Check key format (sb_ prefix → apikey only, not Bearer) |
| HTTP 1010 (Cloudflare) | WAF blocking the request. Outline/n8n behind Cloudflare. | Use browser-like headers or MCP client |

### Phase 3 — Compare Healthy vs Failing Runs

**Key diagnostic technique:** Read a SUCCESSFUL run log first, then a FAILED run log from the same job. Compare:

- Same prompt? ✅
- Same agent model? ✅
- Same data sources? ✅
- Same delivery target? ❌ (this is the differentiator)
- What's the last thing different between them?

**Session example (2026-06-04):**
- Foremost Capital SOD Brief ran fine Jun 5, 6, 7 — produced full 3,643-byte briefs
- Failed on Jun 8 with Broken pipe
- Data source (Supabase) was unreachable with anon key — but the job uses the secret key internally
- The actual root cause: the delivery target (`deliver=telegram`) couldn't resolve because Telegram isn't connected in the WebUI environment
- The earlier successful runs were being logged but the delivery was silently dropping

### Phase 4 — Root Cause Triage

**Broken pipe specifically:** This means the agent completed its work (data fetched, analysis done, report produced) but **the connection back to the scheduler broke** during response streaming. It is NOT a logic error — it's a transport error.

Three things cause Broken pipe in cron jobs:
1. **Delivery target doesn't resolve** — No channel knows how to receive the output → scheduler closes the connection → agent gets broken pipe
2. **Output exceeds buffer** — Very large responses hit the scheduler's write buffer limit (rare; most cron reports are <50KB)
3. **Scheduler restart during execution** — Scheduler cycled mid-run (check for Docker restarts, config changes)

### Phase 5 — Fix Strategy

| Root Cause | Fix |
|------------|-----|
| `deliver=origin` doesn't resolve in WebUI | Change to `deliver=local` (output saved to disk, no delivery attempt) |
| `deliver=telegram` with no Telegram setup | Configure Telegram or switch to `deliver=local` |
| `deliver=origin` but no connected platform | Same as above — use `local` until a platform is connected |
| Deliver config correct but still broken pipe | Pause and resume the job (may be a stale scheduler session) |

### Phase 6 — Report Format

```
## Cron Job Investigation — [date]

### Jobs in System: [N] total
| Status | Count | Job Names |
|--------|-------|-----------|
| ✅ Running (ok) | N | ... |
| ❌ Failing (error) | N | ... |
| ⏸️ Never ran | N | ... |

### Failing Jobs — Root Cause

**Error signature:** `RuntimeError: [Errno 32] Broken pipe`
**Common pattern across all failing jobs:** [pattern]
**Root cause:** [one-sentence explanation]
**Proof:** [specific evidence — e.g., "SOD Brief ran fine Jun 5-7, failed Jun 8. Same data, same prompt — only delivery target changed/blocked."]

### Fix Applied / Recommended
1. [action taken]
2. [action needed from Seun]
```

## Pitfalls

- **Don't assume "error" means agent failed.** Broken pipe means the agent *succeeded* but delivery failed. Check the output logs!
- **A job showing `last_status: "ok"` may still have delivery failures.** Check the `last_delivery_error` field — it can be non-null even when status is ok.
- **Jobs that never ran are not "failing"** — they may not have reached their first schedule time yet. Check `next_run_at`.
- **Don't recreate jobs to fix delivery.** Update the existing job's delivery target or pause it — don't delete and recreate.
- **SILENT response is not an error.** Some jobs suppress delivery to reduce noise. The `[SILENT]` in a log means the job ran but chose not to produce output.
