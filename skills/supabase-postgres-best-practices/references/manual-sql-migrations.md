# Manual SQL Migrations for Railway + Supabase

## Rule
Always provide raw SQL for Supabase SQL Editor instead of `prisma migrate deploy` commands. The user runs migrations manually.

## Pattern
```sql
CREATE TABLE IF NOT EXISTS "TableName" (
  "id" TEXT NOT NULL,
  ...columns...
  CONSTRAINT "TableName_pkey" PRIMARY KEY ("id")
);

INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'baseline', NOW(), 'migration_name', NULL, NULL, NOW(), 1);
```

The `INSERT INTO _prisma_migrations` line is REQUIRED — Prisma checks this table to determine which migrations have been applied. Without it, `prisma migrate deploy` or `prisma migrate resolve` will complain.

## Recovery — Migration already run manually (P3018/P3009)

When Seun runs migration SQL manually via the SQL Editor BEFORE the migration file is committed, the next Railway deploy fails:

```
ERROR: column "kycReviewStatus" of relation "Resident" already exists
Error: P3018 — A migration failed to apply.
Error: P3009 — migrate found failed migrations in the target database,
       new migrations will not be applied.
```

Once ANY migration fails, Prisma blocks ALL subsequent migrations.

**Fix (two steps):**

1. **Clear the failed marker** from Supabase SQL Editor:
```sql
DELETE FROM "_prisma_migrations" WHERE "migration_name" = '20260707000000_add_kyc_review_fields';
```

2. **Make the code migration idempotent** so it succeeds on retry:
```sql
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

The same pattern applies to enums (`pg_type`), tables (`information_schema.tables`), and indexes (`CREATE INDEX IF NOT EXISTS`).

**Prevention:** Always use `IF NOT EXISTS` in migration SQL. Never assume the migration file is the only path to production.

## Example
```sql
ALTER TABLE "Community"
ADD COLUMN IF NOT EXISTS "ownerClerkId" TEXT UNIQUE;

INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'baseline', NOW(), 'add_community_owner_clerk_id', NULL, NULL, NOW(), 1);
```
