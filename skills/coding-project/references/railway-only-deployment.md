# Railway-Only Deployment Constraint

## Rule: No local dev servers, no local test runs

Streetwise development happens entirely on Railway. The Hermes Docker container has:

- No PostgreSQL database access (no `psql`, no Supabase pooler from this container)
- No browser dependencies (`libglib-2.0.so.0` missing — Playwright/Chromium won't run)
- No root access (`sudo` unavailable — can't install system packages)
- No Cler k test users stored in this environment

**DO NOT:**
- Start `npx next dev` — the local dev server serves no purpose. Tests run against the staging URL
- Run `npx playwright test` — browser dependencies aren't available
- Run `npx prisma migrate dev` — no database connection exists
- Run `npm run test:e2e` for backend — requires a real PostgreSQL connection

**DO:**
- Push to GitHub → Railway auto-deploys → test against the staging URL
- Use `browser_navigate` to test against `https://frontend-production-8569.up.railway.app`
- Use `curl` to test backend health (`https://backend-production-c6dc2.up.railway.app`)
- Provide SQL migration statements for the user to run manually in Supabase SQL editor
- Write test files for the user to run on their machine

## SQL Migration Format

Always provide SQL as manual Supabase editor statements, NEVER `prisma migrate deploy`:

```sql
CREATE TABLE "Example" (...);

INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'baseline', NOW(), 'add_example', NULL, NULL, NOW(), 1);
```
