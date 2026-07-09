# Supabase CLI — Command Patterns

Quick reference for executing SQL and managing Supabase projects via CLI.

---

## Project Linking

```bash
# Link local directory to Supabase project
supabase link --project-ref <project-ref>

# Project ref is the subdomain from your Supabase URL:
# https://tqacwivrwfsdsjdnxblp.supabase.co → tqacwivrwfsdsjdnxblp
```

---

## Executing SQL

### From file (recommended for multi-statement migrations):

```bash
supabase db query -f /path/to/migration.sql --linked
```

### Inline SQL (positional argument, NOT `--sql` flag):

```bash
supabase db query --linked "SELECT table_name FROM information_schema.tables;"
```

**Common mistake:** `--sql` flag does not exist. Use positional argument or `-f`.

---

## Schema Discovery

### List tables matching pattern:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_name LIKE 'sales_%'
ORDER BY table_name;
```

### Get column schema for a table:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'clients'
ORDER BY ordinal_position;
```

---

## PostgreSQL Array Literals

When inserting into `text[]` or similar array columns, use PostgreSQL array syntax:

```sql
-- CORRECT:
INSERT INTO decisions (affects) VALUES ('{timeline,cost,scope}');

-- WRONG (JSON syntax):
INSERT INTO decisions (affects) VALUES ('["timeline","cost","scope"]');

-- WRONG (comma-separated string):
INSERT INTO decisions (affects) VALUES ('timeline,cost,scope');
```

**Syntax rules:**
- Wrap in curly braces: `{value1,value2,value3}`
- No quotes needed for simple text values
- Use double quotes for values containing commas: `{"value, with comma",simple}`
- Empty array: `{}`

---

## INSERT with ON CONFLICT

```sql
-- When table has UNIQUE constraint:
INSERT INTO clients (name, email, created_at)
VALUES ('Oryx Platform', 'seun@example.com', now())
ON CONFLICT (email) DO UPDATE
SET name = EXCLUDED.name, updated_at = now()
RETURNING id, name;

-- When NO UNIQUE constraint exists (simple insert):
INSERT INTO clients (name, email, created_at)
VALUES ('Oryx Platform', 'seun@example.com', now())
RETURNING id, name;
```

**Note:** `ON CONFLICT` requires a UNIQUE or exclusion constraint on the specified column.

---

## Common Error Patterns

| Error | Cause | Fix |
|-------|-------|-----|
| `unknown flag: --sql` | `--sql` flag doesn't exist | Use positional argument or `-f` |
| `Cannot find project ref` | Not linked to project | Run `supabase link --project-ref <ref>` first |
| `column "status" does not exist` | Schema mismatch | Query `information_schema.columns` first |
| `malformed array literal` | Using JSON or string instead of PG array | Use `{value,value}` syntax |
| `no unique or exclusion constraint` | `ON CONFLICT` without UNIQUE column | Remove `ON CONFLICT` or add constraint |

---

## Environment Variables

CLI reads from `.env.local` or environment:

```bash
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<secret>
```

For `--linked` mode, the project ref comes from `.supabase/config.toml` after linking.
