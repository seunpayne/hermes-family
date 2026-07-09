# Supabase Key Formats

Supabase has two key formats in active use. Both are valid.

## Classic JWT Format (older projects)

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxYWN3aXZyd2ZzZHNqZG54YmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc0MTc2ODYsImV4cCI6MjA0Mjk5MzY4Nn0.OBrYBAHRsXJkOqQ5nyUqRLj2p1zBs5meGHeIhaDNtPA
```

- Starts with `eyJ` (base64-encoded JSON header)
- Contains role (`anon` or `service_role`) in the payload
- Can be decoded at jwt.io (but the secret key is not revealed — only the payload is readable)
- The `anon` key and `service_role` key are separate JWTs

## New Publishable/Secret Key Format (newer projects, Supabase UI v2+)

```
sb_publishable_Tln3cHqhieiI-cLVpt3WSA_-bDELnjg
sb_secret_zWuJ8HYRfXKZ2RHtHy8F5Q_3hm6G5bx
```

- `sb_publishable_` prefix = anon/public role — safe to expose in client-side code
- `sb_secret_` prefix = service_role — secret, never expose client-side
- These are the same underlying keys as the JWT format, just a different encoding for the Supabase dashboard UI
- Both formats work identically via the REST API

## ⚠️ Auth Method Difference: New format keys are NOT JWTs

**Critical distinction:** `sb_publishable_` and `sb_secret_` prefixed keys are **NOT valid JWT tokens**. They only work via the `apikey` header. The `Authorization: Bearer` header will return `401 PGRST301: Expected 3 parts in JWT` for these keys.

| Key prefix | Works as `apikey` | Works as `Authorization: Bearer` |
|------------|-------------------|----------------------------------|
| `eyJ...` (classic JWT) | ✅ | ✅ |
| `sb_publishable_...` | ✅ | ❌ 401 |
| `sb_secret_...` | ✅ | ❌ 401 |

**When you see a `sb_*` key, only send `apikey`. Never send it as Bearer.**

**Why sending both headers is misleading:** The old pattern of sending both `apikey` and `Authorization: Bearer` together (seen in older reference docs) works because the REST API silently ignores the failing Bearer and uses `apikey`. But if you test `Bearer` alone, it fails. This confuses diagnostics — you need to test each header separately to know which auth actually works.

### Correct patterns for `sb_*` keys:
```bash
# ✅ CORRECT for sb_secret_ / sb_publishable_ keys
curl -s "$SUPABASE_URL/rest/v1/projects?limit=1" \
  -H "apikey: $SUPABASE_SECRET_KEY"

# ❌ WRONG — will return 401
curl -s "$SUPABASE_URL/rest/v1/projects?limit=1" \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY"
```

### Sequential auth diagnostic
When you don't know the key format, test each header separately:
```bash
python3 -c "
import os, urllib.request
u = os.environ['SUPABASE_URL']

for label, k in [('SECRET_KEY','SUPABASE_SECRET_KEY'),('ANON_KEY','SUPABASE_ANON_KEY')]:
    v = os.environ.get(k,'')
    if not v: continue
    # Test apikey only
    try:
        r = urllib.request.Request(u + '/rest/v1/projects?limit=1',
            headers={'apikey': v, 'Content-Type': 'application/json'})
        d = urllib.request.urlopen(r).read()
        print(f'{label} apikey: {len(d)} bytes - OK')
    except Exception as e:
        print(f'{label} apikey: FAIL - {e}')
    # Test Bearer only
    try:
        r = urllib.request.Request(u + '/rest/v1/projects?limit=1',
            headers={'Authorization': f'Bearer {v}', 'Content-Type': 'application/json'})
        d = urllib.request.urlopen(r).read()
        print(f'{label} Bearer: {len(d)} bytes - OK')
    except Exception as e:
        print(f'{label} Bearer: FAIL - {e}')
"
```

### Empty result ≠ broken key
A `200 OK` with `[]` (empty array) means **the key works but:**
- For anon keys: RLS policies block access to that table, OR the table is truly empty
- For secret keys: you have full access but the table is empty

**Don't assume empty = no data.** If the anon key returns `[]` and the secret key also returns `[]`, then the table is truly empty. But if anon returns `[]` and secret returns data, it's an RLS issue, not a key problem.

## Exhaust-Verification Protocol

When a Supabase query returns `[]` (empty), **test every available auth key before concluding the table has no data.** A single key's response is never sufficient.

### Procedure

1. **Inventory** — check which Supabase keys exist in the environment:
   ```python
   import os
   for k in ['SUPABASE_ANON_KEY', 'SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY']:
       v = os.environ.get(k, '')
       if v:
           print(f'{k}: present, len={len(v)}, starts with {v[:6]}...')
   ```
2. **Test each separately** — use the sequential diagnostic script in the section above
3. **For `sb_` prefix keys** — use `apikey` header only (never `Authorization: Bearer`)
4. **For `eyJ...` JWT keys** — both `apikey` and Bearer work
5. **Only conclude empty** when ALL available keys return `[]`

### Why Exhaustiveness Matters

- Anon keys are RLS-restricted — `[]` means the anon role can't see data, not that no data exists
- Environment displays may **truncate key values visually** (e.g., `export` shows `sb_sec...G5bx`) while the actual env var holds the full key. Always check length with Python before declaring a key invalid
- Secret/service_role keys bypass all RLS — their `[]` is the authoritative "table is empty" signal
- Testing only one auth method when the key uses a different format produces a **false 401** that looks like a broken credential

### Real-World Counterexample

In this system (June 2026): `SUPABASE_ANON_KEY` (46-char `sb_publishable_` prefix) returned `[]` via apikey. Initial conclusion: "tables are empty." But `SUPABASE_SECRET_KEY` (41-char `sb_secret_` prefix) returned actual data. Real conclusion: "tables have data, RLS blocked anon access."

## Quick Test — Which Tables Can Anon Access?

```bash
# Test anon key (apikey only for sb_ prefix keys)
curl -s "$SUPABASE_URL/rest/v1/decisions?limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY"

# Response [] (empty array) with HTTP 200 = key valid, but RLS blocks that table with anon
# Response with data and HTTP 200 = key valid AND anon has RLS access to that table
# HTTP 401 = key is invalid/expired
```

## Root Endpoint Behavior

`GET $SUPABASE_URL/rest/v1/` — returns HTTP 401 with `{"message":"Secret API key required"}` for anon keys. This is expected. Only service_role keys can access the root. Always test against a real table instead.

## Key Regeneration

If keys are expired, generate new ones from:
- Supabase Dashboard → Project Settings → API → Project API keys section
- The "anon public" and "service_role" keys listed there
