---
name: supabase-postgres-best-practices
description: Postgres performance optimization and best practices from Supabase. Use this skill when writing, reviewing, or optimizing Postgres queries, schema designs, or database configurations.
license: MIT
metadata:
  author: supabase
  version: "1.1.1"
  organization: Supabase
  date: January 2026
  abstract: Comprehensive Postgres performance optimization guide for developers using Supabase and Postgres. Contains performance rules across 8 categories, prioritized by impact from critical (query performance, connection management) to incremental (advanced features). Each rule includes detailed explanations, incorrect vs. correct SQL examples, query plan analysis, and specific performance metrics to guide automated optimization and code generation.
---

# Supabase Postgres Best Practices

Comprehensive performance optimization guide for Postgres, maintained by Supabase. Contains rules across 8 categories, prioritized by impact to guide automated query optimization and schema design.

## When to Apply

Reference these guidelines when:
- Writing SQL queries or designing schemas
- Implementing indexes or query optimization
- Reviewing database performance issues
- Configuring connection pooling or scaling
- Optimizing for Postgres-specific features
- Working with Row-Level Security (RLS)

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Query Performance | CRITICAL | `query-` |
| 2 | Connection Management | CRITICAL | `conn-` |
| 3 | Security & RLS | CRITICAL | `security-` |
| 4 | Schema Design | HIGH | `schema-` |
| 5 | Concurrency & Locking | MEDIUM-HIGH | `lock-` |
| 6 | Data Access Patterns | MEDIUM | `data-` |
| 7 | Monitoring & Diagnostics | LOW-MEDIUM | `monitor-` |
| 8 | Advanced Features | LOW | `advanced-` |

## How to Use
## How to Use

Read individual rule files for detailed explanations and SQL examples:

```
references/query-missing-indexes.md
references/query-partial-indexes.md
references/_sections.md
```

Each rule file contains:
- Brief explanation of why it matters
- Incorrect SQL example with explanation
- Correct SQL example with explanation
- Optional EXPLAIN output or metrics
- Additional context and references
- Supabase-specific notes (when applicable)

---

## Common Pitfalls

### Postgres Array Literal Syntax

When inserting arrays via raw SQL (e.g., `supabase db query --linked`), Postgres requires curly brace syntax, NOT JSON array syntax:

**Incorrect (JSON style):**
```sql
INSERT INTO decisions (affects) VALUES ('["timeline","cost"]');
-- ERROR: malformed array literal: "["timeline","cost"]"
```

**Incorrect (comma-separated string):**
```sql
INSERT INTO decisions (affects) VALUES ('timeline, cost');
-- ERROR: malformed array literal: "timeline, cost"
```

**Correct (Postgres array literal):**
```sql
INSERT INTO decisions (affects) VALUES ('{timeline,cost}');
-- SUCCESS
```

**Rule:** For `text[]` or any array column in raw SQL, use `{value1,value2,value3}` with no spaces after commas. Quote individual elements only if they contain commas or special characters: `{"value with space",simple}`.

**Note:** This applies only to raw SQL execution. When using the Supabase JS client (`@supabase/supabase-js`), pass normal JavaScript arrays — the client handles serialization.

### Supabase decisions table schema

The `decisions` table uses these columns (verify before inserting):

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'decisions' 
ORDER BY ordinal_position;
```

Typical schema:
- `id` uuid PRIMARY KEY
- `project_id` uuid (FK to projects)
- `client_id` uuid (FK to clients)
- `made_by` text
- `decision` text
- `rationale` text
- `affects` text[] (ARRAY type — use curly brace syntax)
- `reversible` boolean
- `reversed` boolean
- `reversed_by` text
- `reversed_at` timestamp
- `created_at` timestamp

**Note:** Column `decision_type` does NOT exist — use `decision` for the decision text and `made_by` for who decided.

### Supabase CLI: Linked Project Queries

The `--linked` flag requires an active project link in the current directory:

**Incorrect:**
```bash
# Running from anywhere without linking first
supabase db query --linked "SELECT..."
-- ERROR: Cannot find project ref. Have you run supabase link?
```

**Correct:**
```bash
# Step 1: Link project (one-time per directory)
cd ~/Projects/supabase
supabase link --project-ref tqacwivrwfsdsjdnxblp

# Step 2: Query using --linked (must be in same directory)
cd ~/Projects/supabase
supabase db query --linked "SELECT..."

# Alternative: Use SQL file
supabase db query -f /path/to/migration.sql --linked
```

**Note:** The link state is directory-specific. If you move to a different directory, you must either `cd` back or re-run `supabase link` in the new directory.

**Common CLI mistakes:**
- `--sql` flag does not exist — use positional argument or `-f`
- Link is per-directory, not global — link state lives in `.supabase` folder
- Project ref found in dashboard URL: `supabase.com/dashboard/project/[REF]`

See: `references/supabase-linked-queries.md` for full troubleshooting guide.

### Creating Unique Constraints

When adding unique constraints to existing tables with data:

```sql
-- Check for duplicates FIRST
SELECT google_maps_url, COUNT(*) 
FROM sales_prospects 
GROUP BY google_maps_url 
HAVING COUNT(*) > 1;

-- If duplicates exist, resolve them before adding constraint
-- Then add constraint
ALTER TABLE sales_prospects
ADD CONSTRAINT unique_google_maps_url UNIQUE (google_maps_url);
```

**Warning:** If duplicate values exist, the ALTER TABLE will fail. Always check and clean data first.

### Prisma + RLS: Column Names Must Match Prisma Casing

When writing RLS policies on tables managed by a **Prisma schema**, column names in policy `USING` and `WITH CHECK` expressions must use Prisma's camelCase convention, **not** Postgres snake_case — even though the SQL statement is raw SQL.

**Why this traps people:** Prisma generates camelCase field names (e.g. `"communityId"`) from snake_case column definitions (`community_id`). RLS policies are raw SQL where natural Postgres convention is snake_case. The mismatch produces `ERROR: column "community_id" does not exist` or silent policy failure.

**Incorrect (snake_case — natural Postgres, but fails with Prisma schema):**
```sql
CREATE POLICY "Members can view their community"
  ON members FOR SELECT
  USING (community_id = set_community_id());
-- ERROR: column "community_id" does not exist
-- Schema uses "communityId" because Prisma maps it that way
```

**Correct (camelCase — matches Prisma schema):**
```sql
CREATE POLICY "Members can view their community"
  ON members FOR SELECT
  USING ("communityId" = set_community_id());
```

**What is NOT affected:**
- **Function names** (`set_community_id`) — these are not columns, they can use any convention
- **GUC setting strings** (`current_setting('app.current_community_id')`) — these are string literals, not identifiers
- **Table names** — Prisma typically keeps these snake_case in the database
- **Parameters** — function parameters like `community_id TEXT` can use any convention

**Rule of thumb:** Every unquoted identifier in a `USING`/`WITH CHECK` expression that references a column must use the same casing as the Prisma model field. When in doubt, check the Prisma schema file:

```prisma
model Member {
  communityId String @map("community_id")  // ← use "communityId" in RLS
  userId      String @map("user_id")       // ← use "userId" in RLS
}
```

The `@map` attribute tells you the DB column name, but Prisma resolves it to camelCase — always double-quote and use Prisma casing in policy expressions.

**Quick verification query:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'members' 
ORDER BY ordinal_position;
-- Shows actual DB column names (snake_case)
-- But RLS policies must reference Prisma names (camelCase)
-- unless you quote the literal DB name: "community_id"
```

### Schema Verification Before Insert

Before inserting into any Supabase table via raw SQL:

```sql
-- Verify actual column names and types
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'projects' 
ORDER BY ordinal_position;
```

**Common mistake:** Assuming columns like `prd_path` or `status` exist when they may not. The `projects` table has: `client_id`, `name`, `type`, `status`, `budget`, `spent`, `timeline_start`, `timeline_end`, `production_url`, `staging_url`, `github_repo`, `stack`, `created_at`, `updated_at`.

**Rule:** Always verify schema before writing. Do not assume column names from memory or documentation — schemas drift over time.

## References

- `references/supabase-pooler-connection.md` — Connecting through the IPv4 session pooler (mandatory for Docker/cloud environments without IPv6)
- `references/prisma-migration-drift.md` — Idempotent migration pattern (IF NOT EXISTS) and _prisma_migrations cleanup when manual SQL Editor runs create drift
- https://www.postgresql.org/docs/current/
- https://supabase.com/docs
- https://wiki.postgresql.org/wiki/Performance_Optimization
- https://supabase.com/docs/guides/database/overview
- https://supabase.com/docs/guides/auth/row-level-security
