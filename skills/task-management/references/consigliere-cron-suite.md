# Consigliere Cron Job Suite

The Consigliere monitoring system runs 5 daily/weekly cron jobs plus 2 client-facing alerts.
All persistent reports go to **Outline** (never Obsidian). Alert-style briefs go to Telegram.

## Schedule (Lagos WAT, UTC+1)

| # | Job | Schedule (Lagos) | UTC | Deliver | Data Source |
|:-:|-----|:----------------:|:---:|:-------:|-------------|
| 1 | Daily Credential Health Report | 7:00 AM daily | `0 6 * * *` | origin → Outline | `credentials_status` table |
| 2 | Daily Pending Sync Check | 8:00 AM daily | `0 7 * * *` | origin → Outline | `~/.hermes/pending-sync/` |
| 3 | Daily Health Check | 10:00 AM daily | `0 9 * * *` | origin → Outline | `projects`, `tasks`, `credentials_status` |
| 4 | Weekly Learning Report | Mon 9:00 AM | `0 8 * * 1` | origin → Outline | Agent runs, decisions, escalations |
| 5 | Weekly Cost Digest | Mon 9:00 AM | `0 8 * * 1` | origin → Outline | `billing_events` table |
| 6 | Foremost Capital SOD Brief | 8:00 AM daily | `0 7 * * *` | telegram ⚠️ BROKEN | Foremost Capital project state |
| 7 | Foremost Capital EOD Reminder | 5:00 PM daily | `0 16 * * *` | telegram ⚠️ BROKEN | Pending tasks |

### ⚠️ Delivery Status — June 2026

Jobs 1–5 use `deliver=origin` and jobs 6–7 use `deliver=telegram`. In the WebUI-only environment
(no Telegram configured, no messaging platform connected), **all 7 jobs fail delivery** with
`no delivery target resolved for deliver=origin|telegram` and a downstream `Broken pipe` error.

**Fix:** Either connect a messaging platform (Slack, Telegram) and update delivery targets, or
switch to `deliver=local` to save output to disk without attempting delivery.

For Slack setup procedure, see `references/slack-delivery-setup.md`.

## Credential Health Check (Job #1)

Query `credentials_status` for expiring or failed credentials. Write findings as
a document in Outline titled `Daily Credential Health — YYYY-MM-DD` under the
"Consigliere Reports" collection.

Include: service name, status, expiry date (if applicable), recommended action.
Highlight anything expiring within 7 days or already failed.

Credentials to check: `replicate`, `stability_ai`, `google_oauth`, `google_analytics`,
`fal_ai`, `supabase`, `resend`, `github`, `google_drive`, `deploy_kit`.

## Pending Sync Check (Job #2)

Check `~/.hermes/pending-sync/` for reconciliation packages (files/directories).
Process each package:
1. Read and parse
2. Reconcile against Supabase state
3. Archive processed packages
4. Write summary to Outline: `Daily Sync Summary — YYYY-MM-DD`

## Daily Health Check (Job #3)

Triple check executed every morning:

1. **Supabase connectivity** — Query `projects` table (expect 5+ active projects)
2. **Stalled tasks** — Count tasks with `status = 'stalled'`
3. **Credential health** — List all entries, flag `missing`/`expired`/`failed`

Output to Outline: `Daily Health Check — YYYY-MM-DD` in "Consigliere Reports" collection.

## Outline Document Convention

All Consigliere reports go into the **Consigliere Reports** collection in Outline.
Document titles follow the pattern: `<Report Type> — YYYY-MM-DD`.

The MCP create_document call must include `collectionId` (no bare documents).
List collections first if the collection ID is unknown.

## Outline MCP Auth Note

The Outline MCP at `outline.velocit8.com/mcp` is behind Cloudflare. Standard
Python `urllib` requests get blocked with Error 1010 unless proper browser-like
headers are sent. The Hermes MCP client handles this automatically, but raw
HTTP tests need:
- `User-Agent`: Chrome browser string
- `Sec-Fetch-*` headers set to `cors`/`empty`/`same-origin`
- `Referer` + `Origin` matching the target domain
- `Accept` including `text/event-stream`

See `Family Skills/hermes-migration/references/cloudflare-waf-troubleshooting.md`.
