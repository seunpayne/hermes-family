# Prisma Migration Drift — Manual SQL Editor Conflicts

## The Problem

When a migration column is applied **manually** via Supabase SQL Editor (skipping Prisma's migration runner), Prisma's `_prisma_migrations` tracking table doesn't know it happened. On the next deploy, Prisma tries to run the migration, hits `ERROR: column already exists`, and blocks ALL subsequent migrations with `P3009`/`P3018`.

## The Fix

### 1. Make migrations idempotent

Use `DO $$ ... IF NOT EXISTS ... END $$` blocks so migrations succeed whether or not the column/type already exists:

```sql
-- ❌ Fragile — fails if column already exists
ALTER TABLE "Resident" ADD COLUMN "kycReviewStatus" TEXT;

-- ✅ Idempotent — succeeds regardless
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Resident' AND column_name = 'kycReviewStatus'
  ) THEN
    ALTER TABLE "Resident" ADD COLUMN "kycReviewStatus" TEXT;
  END IF;
END $$;
```

For enum types, also check `pg_type`:
```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'RecurringLevyInterval') THEN
    CREATE TYPE "RecurringLevyInterval" AS ENUM ('weekly', 'monthly', 'quarterly', 'annually');
  END IF;
END $$;
```

### 2. Clear the failed migration marker

When a migration has already failed in the tracking table, delete the row so Prisma retries:

```sql
DELETE FROM "_prisma_migrations"
WHERE "migration_name" = '20260707000000_add_kyc_review_fields';
```

### 3. Verify migration state

```sql
SELECT migration_name, started_at, finished_at, rolled_back_at, logs
FROM "_prisma_migrations"
ORDER BY started_at DESC;
```

## Prevention

- **Never run migration SQL manually** in the SQL Editor if Prisma migrations are the canonical source.
- **If you must run manual SQL**, always use `IF NOT EXISTS` guards so Prisma can re-run the migration safely.
- **Consider using `npx prisma migrate resolve --applied <name>`** from the Railway shell as an alternative to raw `DELETE`.
