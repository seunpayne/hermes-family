# Project Registration in Don's Supabase

Registering a new project happens BEFORE Phase 1 PRD shaping.
Uses the Don's system Supabase at `tqacwivrwfsdsjdnxblp.supabase.co`.

## Credentials

From `~/.hermes/.env`:
- `SUPABASE_URL=https://tqacwivrwfsdsjdnxblp.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY=sb_secret_...`

## Schema

### clients table
```
id          UUID (auto)     — primary key
name        TEXT            — client display name
company     TEXT (nullable) — legal entity name
email       TEXT (nullable) — primary contact email
phone       TEXT (nullable)
address     TEXT (nullable)
brand_assets_path TEXT (nullable)
policy      JSONB           — default: {}
created_at  TIMESTAMPTZ (auto)
updated_at  TIMESTAMPTZ (auto)
```

### projects table
```
id              UUID (auto)     — primary key
client_id       UUID (nullable) — FK to clients
name            TEXT            — project display name
type            TEXT (nullable) — "fintech", "website", "erp", etc.
status          TEXT            — "active", "paused", "complete", "archived"
budget          NUMERIC         — default: 0
spent           NUMERIC         — default: 0
timeline_start  DATE (nullable)
timeline_end    DATE (nullable)
production_url  TEXT (nullable)
staging_url     TEXT (nullable)
github_repo     TEXT (nullable)
stack           TEXT (nullable) — e.g. "TanStack Start, Vite 7, Supabase"
created_at      TIMESTAMPTZ (auto)
updated_at      TIMESTAMPTZ (auto)
```

## REST API Registration

### 1. Check if client exists
```bash
curl -s "$SUPABASE_URL/rest/v1/clients?select=id,name&name=ilike.*searchterm*" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

### 2. Create client (if needed)
```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/clients" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"name":"Client Name","company":"Company Ltd","email":"hello@domain.com","policy":{}}'
```

### 3. Create project
```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/projects" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"name":"Project Name","status":"active","client_id":"<UUID>","github_repo":"https://github.com/owner/repo","stack":"stack description","type":"fintech","budget":0,"spent":0}'
```

### 4. Log a decision (after PRD approval or any gate)
```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/decisions" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "project_id":"<PROJECT_UUID>",
    "made_by":"Seun",
    "decision":"PRD v2.1 approved. T-001 unblocked.",
    "rationale":"Quality gate passed, all blindspots resolved.",
    "affects":["scope","timeline","team"],
    "reversible":false
  }'
```

### 5. Create tasks
```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/tasks" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "project_id":"<PROJECT_UUID>",
    "agent":"Clemenza",
    "title":"T-001 — Multi-tenant SaaS Scaffold",
    "description":"NestJS + Prisma + PostgreSQL scaffold...",
    "status":"pending",
    "assigned_to":"Clemenza"
  }'
```

### 6. Update task status
```bash
curl -s -X PATCH "$SUPABASE_URL/rest/v1/tasks?id=eq.<TASK_UUID>" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status":"done"}'
```

## Task status constraint

The `tasks` table `status` column has a **check constraint**. Only these values are valid:
`pending`, `in_progress`, `blocked`, `done`

**Invalid values** (trigger `23514` error): `ready`, `completed`, `cancelled`, `open`

## Important

- Use `SUPABASE_SERVICE_ROLE_KEY`, not the anon key — anon can't write to these tables
- Always `select=*&limit=1` first to see which columns actually exist — schemas evolve
- The `projects` table does NOT have a `branch`, `description`, or `prd_path` column
- The `clients` table does NOT have a `status` column
