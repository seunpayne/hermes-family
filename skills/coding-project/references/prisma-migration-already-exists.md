# P3018 / P3009 — Migration Already Exists on Production

## The failure

```
ERROR: column "kycReviewStatus" of relation "Resident" already exists
Error: P3018 — A migration failed to apply.
Error: P3009 — migrate found failed migrations in the target database,
       new migrations will not be applied.
```

This happens when Seun runs a migration SQL manually via the Supabase SQL Editor BEFORE the migration file is committed to the repo. The Prisma migration tracking table (`_prisma_migrations`) doesn't know the migration was already applied, so it tries to `ALTER TABLE ADD COLUMN` on columns that already exist.

## Why it's blocking

Once ANY migration fails, Prisma blocks ALL subsequent migrations (`P3009`). Even if the next migration (`20260707000001_add_recurring_levy_config`) is completely unrelated, it won't run until the failed migration is resolved.

## Fix path

### Step 1 — Make the migration idempotent

Replace bare `ALTER TABLE ADD COLUMN` with `IF NOT EXISTS` checks:

```sql
-- BEFORE (will fail if column exists)
ALTER TABLE "Resident" ADD COLUMN "kycReviewStatus" TEXT NOT NULL DEFAULT 'none';

-- AFTER (idempotent — succeeds regardless)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Resident' AND column_name = 'kycReviewStatus'
  ) THEN
    ALTER TABLE "Resident" ADD COLUMN "kycReviewStatus" TEXT NOT NULL DEFAULT 'none';
  END IF;
END $$;
```

Same pattern for `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, and `CREATE TYPE` (check `pg_type` first).

### Step 2 — Clear the failed migration marker

From Supabase SQL Editor:
```sql
DELETE FROM "_prisma_migrations" WHERE "migration_name" = '20260707000000_add_kyc_review_fields';
```

### Step 3 — Railway redeploys

On the next deploy, the idempotent migration runs successfully (columns already exist, so the `IF NOT EXISTS` skips them), Prisma records it as applied, and subsequent migrations proceed normally.

## Prevention

- When Seun runs SQL manually, immediately create the migration file with idempotent SQL
- Never use bare `ALTER TABLE ADD COLUMN` — always wrap in `IF NOT EXISTS`
- For enums: check `pg_type` before `CREATE TYPE`
- For tables: use `CREATE TABLE IF NOT EXISTS`
- For indexes: use `CREATE INDEX IF NOT EXISTS`
