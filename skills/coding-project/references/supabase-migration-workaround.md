# Supabase Migration Push Workaround

## Problem
When local migration history doesn't match remote database, `supabase db push` fails with:
```
Remote migration versions not found in local migrations directory.
Make sure your local git repo is up-to-date...
```

This happens when:
- Creating a new Supabase project in an existing directory
- Local `supabase/` folder has no migration history
- Remote database already has migrations tracked

## Solution: Use `supabase db query --file`

Instead of `supabase db push`, run the migration file directly:

```bash
supabase db query --file supabase/migrations/YYYYMMDD_description.sql --linked
```

This executes the SQL file against the linked remote database without checking migration history.

## Alternative: Repair Migration History

If you need to track migrations properly:

```bash
# Mark existing remote migrations as applied locally
supabase migration repair --status applied <migration_timestamp> --linked

# Then push new migrations
supabase db push
```

## When to Use Each

| Method | Use Case |
|--------|----------|
| `db query --file` | Quick deployment, one-off migrations, testing |
| `migration repair` + `db push` | Proper migration tracking, team projects |
| `db pull` | Sync local schema with remote (destructive - overwrites local migrations) |

## Session Example: Sani General Stores

Created migration `20260520_sani_erp_schema.sql` in new project directory.

Failed:
```bash
supabase db push
# → Remote migration versions not found
```

Succeeded:
```bash
supabase db query --file supabase/migrations/20260520_sani_erp_schema.sql --linked
# → Schema deployed successfully
```

Verified with:
```bash
curl "https://<project>.supabase.co/rest/v1/" \
  -H "apikey: <service_key>" \
  -H "Authorization: Bearer <service_key>" \
  | grep -o '"proto_[^"]*"' | sort -u
```
