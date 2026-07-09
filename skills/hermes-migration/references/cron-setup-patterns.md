# Cron Job Setup Patterns (Consigliere System)

## Overview

The Consigliere monitoring system runs 7 cron jobs on a daily/weekly schedule.
All output destinations use **Outline** (not Obsidian). This is a hard rule.

## Schedule Conversion: Lagos (WAT, UTC+1)

Cron schedules run in UTC. Convert Lagos time to UTC by subtracting 1 hour:

| Lagos Time | UTC Time | Cron Expression |
|:----------:|:--------:|:---------------:|
| 7:00 AM | 06:00 | `0 6 * * *` |
| 8:00 AM | 07:00 | `0 7 * * *` |
| 9:00 AM | 08:00 | `0 8 * * *` |
| 10:00 AM | 09:00 | `0 9 * * *` |
| 5:00 PM | 16:00 | `0 16 * * *` |
| Mon 9:00 AM | Mon 08:00 | `0 8 * * 1` |

## Toolset Scoping

Always scope the `enabled_toolsets` to reduce token burn:

| Job Type | Recommended Toolsets |
|----------|---------------------|
| Supabase-only queries | `["web","terminal","file"]` |
| File processing | `["file","terminal","web"]` |
| Complex/delegation | `["web","terminal","file","delegation"]` |

## Delivery Targets

| Target | When | `deliver` Value |
|--------|------|----------------|
| Current session | Always safe | `"origin"` |
| Telegram | When user needs alert | `"telegram"` |
| Outline | When report should persist | Written via MCP, delivered to origin |

## Cron Job Naming Convention

- **Consigliere prefix** for monitoring/scheduled tasks: `"Consigliere — <Task Description>"`
- **Client prefix** for client-specific briefs: `"<Client Name> — <Brief Type>"`
- **Lowercase** for internal/infrastructure tasks: `"weekly-cost-digest"`

## Outline as Obsidian Replacement

**This system does NOT use Obsidian.** All persistent reports go to Outline (outline.velocit8.com) via MCP.

When a cron prompt says "write to Obsidian", translate it to "write a document in Outline titled `<Title> — YYYY-MM-DD`".

## Active Cron Jobs (Reference)

| Name | Schedule (Lagos) | Toolsets | Deliver | Description |
|------|:----------------:|:--------:|:-------:|-------------|
| Consigliere — Daily Credential Health Report | 7:00 AM daily | web,terminal,file,delegation | origin | Supabase credentials_status → Outline |
| Consigliere — Daily Pending Sync Check | 8:00 AM daily | file,terminal,web | origin | pending-sync/ → Outline |
| Consigliere — Weekly Learning Report | Mon 9:00 AM | web,terminal,file,delegation | origin | Agent runs/decisions → Outline |
| weekly-cost-digest | Mon 9:00 AM | web,terminal,file | origin | billing_events → Outline |
| consigliere-daily-health-check | 10:00 AM daily | web,terminal,file | origin | Full system health → Outline |
| Foremost Capital — SOD Brief | 8:00 AM daily | web,terminal,file | telegram | Project state → Telegram |
| Foremost Capital EOD Reminder | 5:00 PM daily | web,terminal,file | telegram | Pending tasks → Telegram |
