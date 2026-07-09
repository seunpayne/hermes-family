# Consigliere Cron Job Setup — Outline-Based Reporting

This reference documents the 5 Consigliere cron jobs configured on
this Hermes WebUI installation. All reports write to **Outline**
(outline.velocit8.com) instead of Obsidian.

## Outline MCP Server Configuration

The Outline MCP server must be configured in `config.yaml` before
any cron job that writes to Outline will work:

```yaml
mcp_servers:
  outline:
    url: https://outline.velocit8.com/mcp
    auth:
      type: bearer
      token_env: OUTLINE_API_KEY
    timeout: 180
    connect_timeout: 60
```

The `OUTLINE_API_KEY` env var must be set in `~/.hermes/.env`.

## Cron Job Definitions

All schedules are in Africa/Lagos timezone (UTC+1). The cron expressions
below are in UTC (subtract 1 hour from Lagos time).

### 1. Daily Credential Health Report — 7am Lagos

```python
cronjob(
    action='create',
    name='Consigliere — Daily Credential Health Report',
    schedule='0 6 * * *',  # 6am UTC = 7am Lagos
    prompt='''
Run the daily credential health check. Query the credentials_status
table in Supabase for any expiring or failed credentials. Write the
findings as a document in Outline titled "Daily Credential Health —
YYYY-MM-DD".
''',
    enabled_toolsets=['web', 'terminal', 'file', 'delegation'],
    deliver='origin'
)
```

### 2. Daily Pending Sync Check — 8am Lagos

```python
cronjob(
    action='create',
    name='Consigliere — Daily Pending Sync Check',
    schedule='0 7 * * *',  # 7am UTC = 8am Lagos
    prompt='''
Check ~/.hermes/pending-sync/ for any pending reconciliation
packages. Process each package found, then write a summary document
to Outline titled "Daily Sync Summary — YYYY-MM-DD".
''',
    enabled_toolsets=['file', 'terminal', 'web'],
    deliver='origin'
)
```

### 3. Daily Health Check — 10am Lagos

```python
cronjob(
    action='create',
    name='consigliere-daily-health-check',
    schedule='0 9 * * *',  # 9am UTC = 10am Lagos
    prompt='''
Run a full system health check. Verify Supabase connectivity,
check all agent heartbeats, review any stalled tasks in the
tasks table. Report findings as a document in Outline titled
"Daily Health Check — YYYY-MM-DD".
''',
    enabled_toolsets=['web', 'terminal', 'file'],
    deliver='origin'
)
```

### 4. Weekly Cost Digest — Monday 9am Lagos

```python
cronjob(
    action='create',
    name='weekly-cost-digest',
    schedule='0 8 * * 1',  # 8am UTC = 9am Lagos Monday
    prompt='''
Generate a weekly cost digest from the billing_events table in
Supabase. Summarize costs by provider, project, and agent. Flag
any anomalies. Write to Outline titled "Weekly Cost Digest —
YYYY-MM-DD".
''',
    skills=['supabase-postgres-best-practices'],
    enabled_toolsets=['web', 'terminal', 'file'],
    deliver='origin'
)
```

### 5. Weekly Learning Report — Monday 9am Lagos

```python
cronjob(
    action='create',
    name='Consigliere — Weekly Learning Report',
    schedule='0 8 * * 1',  # 8am UTC = 9am Lagos Monday
    prompt='''
Generate a weekly learning report. Review recent agent runs,
decisions, and escalations from Supabase. Summarize patterns and
insights. Write to Outline titled "Weekly Learning Report —
YYYY-MM-DD".
''',
    enabled_toolsets=['web', 'terminal', 'file', 'delegation'],
    deliver='origin'
)
```

## Key Patterns

### Outline Document Title Convention

All cron job reports use the title format:
`<Report Name> — YYYY-MM-DD`

This keeps documents findable and sortable in Outline's collection.

### No `skills` Parameter Unless Necessary

Most cron jobs do NOT load a skill. They use the agent's built-in
capabilities (Supabase queries via REST API, file operations, Outline
MCP). Only `weekly-cost-digest` loads a skill (`supabase-postgres-best-practices`)
because it needs Postgres query optimization guidance for cost analysis.

### Toolsets Are Scoped

Each cron job restricts its toolsets to only what it needs:
- Health checks: `['web', 'terminal', 'file']` (Supabase API, file ops)
- Sync processing: `['file', 'terminal', 'web']` (file reads, processing)
- Learning report: `['web', 'terminal', 'file', 'delegation']` (may spawn subagents)

### UTC Conversion for Lagos

Africa/Lagos is UTC+1 year-round (no DST). Conversion:
- Lagos 7am = UTC 6am → `0 6 * * *`
- Lagos 8am = UTC 7am → `0 7 * * *`
- Lagos 9am = UTC 8am → `0 8 * * 1` (Monday)
- Lagos 10am = UTC 9am → `0 9 * * *`

### Scheduling One-Time Runs

To test a cron job immediately, use `action='run'`:
```python
cronjob(action='run', job_id='<job-id>')
```

Note: In WebUI-only mode (no gateway), cron jobs may not execute
automatically on schedule. The scheduler's `tick()` function must
be called periodically (usually done by the Hermes gateway on a
60-second loop). For automated execution, start the gateway or set
up a background process that calls `cron.scheduler.tick()`.
