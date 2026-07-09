# Supabase CLI Authentication Failures — Workaround

**Problem:** `supabase db push` and `supabase db pull` fail with:
```
failed to connect to postgres: failed SASL auth
(FATAL: password authentication failed for user "postgres")
```

Even when:
- Password is correct (just rotated/reset)
- `supabase unlink` + `supabase link` performed
- `SUPABASE_DB_PASSWORD` exported correctly
- Migration files are valid

**Root Cause:** Supabase CLI migration history tracking gets out of sync with remote database state, especially when:
- Local migration files use non-timestamp naming (e.g., `001_init_schema.sql` instead of `20260509213644_init.sql`)
- Database password was rotated
- Remote has migrations that local doesn't track

---

## Fastest Fix: Manual SQL Editor Execution

When CLI authentication loops persist, bypass the CLI entirely:

1. **Go to:** `https://<project-ref>.supabase.co/dashboard/project/<ref>/editor/new`

2. **Paste migration SQL** (from your local `supabase/migrations/` file)

3. **Click Run** (or Cmd/Ctrl + Enter)

4. **Verify:** Run a quick query to confirm tables exist:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

**Why this works:** The SQL Editor uses your browser session authentication, bypassing the CLI's database password requirement entirely.

---

## Alternative: CLI Repair Commands

If you prefer to fix the CLI state:

```bash
# Step 1: Unlink and relink
supabase unlink
supabase link --project-ref <project-ref>

# Step 2: Export password explicitly
export SUPABASE_DB_PASSWORD='your-new-password'

# Step 3: Try repair
supabase migration repair --status applied <migration-name>

# Step 4: If that fails, pull remote schema
supabase db pull
```

**Note:** Step 3 may fail with `failed to parse <name>: invalid version number` if your migration files don't use timestamp prefixes. This is expected — proceed to manual SQL Editor execution.

---

## Prevention

For future projects:

1. **Use timestamped migration names:**
   ```bash
   supabase migration new init_schema
   # Creates: supabase/migrations/20260522123456_init_schema.sql
   ```

2. **Keep CLI updated:**
   ```bash
   brew upgrade supabase
   ```

3. **When rotating passwords:** Plan to run pending migrations via SQL Editor immediately after rotation, then sync CLI state afterward.

---

## Session Example

**Project:** oryx-v1 (rrgnxuyjcnurkrsqdjjq)
**Date:** 2026-05-22
**What happened:**
- User rotated database password
- `supabase db push` failed with auth error
- `supabase unlink` + `supabase link` performed
- `supabase db pull` failed with migration mismatch
- `supabase migration repair` failed with "invalid version number"
- **Resolution:** User ran migration manually in SQL Editor
- **Time saved:** ~15 minutes of CLI debugging

**Migration applied:** `001_init_schema.sql` (users, proofs, proof_events tables + RLS)
