# Supabase Data Verification

## First Principle: Don't Trust the First Answer

When querying Supabase and getting empty or unexpected results, the **first answer may be a permission boundary, not a data boundary.** The anon key (SUPABASE_ANON_KEY) has Row-Level Security (RLS) restrictions that may make data invisible. The secret key (SUPABASE_SECRET_KEY / SERVICE_ROLE_KEY) sees everything.

## Systematic Verification Workflow

### Step 1 — Identify Your Key Format

Supabase has two key formats that authenticate differently:

| Key Prefix | Works as `apikey` | Works as `Authorization: Bearer` |
|------------|-------------------|----------------------------------|
| `eyJ...` (classic JWT) | ✅ Both work | ✅ Both work |
| `sb_publishable_...` | ✅ | ❌ 401 PGRST301 |
| `sb_secret_...` | ✅ | ❌ 401 PGRST301 |

**Rule:** If key starts with `sb_`, send only the `apikey` header. Never send `Authorization: Bearer`.

### Step 2 — Test the Secret Key

When the anon key returns `[]` (empty array), **always test the secret key before reporting "no data":**

```python
import os, urllib.request, json

url = os.environ['SUPABASE_URL']
secret = os.environ.get('SUPABASE_SECRET_KEY', '')
anon = os.environ.get('SUPABASE_ANON_KEY', '')

# Test with anon key first
try:
    req = urllib.request.Request(f'{url}/rest/v1/projects?select=id,name&limit=5',
        headers={'apikey': anon, 'Content-Type': 'application/json'})
    data = json.loads(urllib.request.urlopen(req).read())
    print(f'Anon key: {len(data)} rows returned')
except Exception as e:
    print(f'Anon key failed: {e}')

# Test with secret key (apikey only for sb_ prefix keys)
try:
    req = urllib.request.Request(f'{url}/rest/v1/projects?select=id,name&limit=5',
        headers={'apikey': secret, 'Content-Type': 'application/json'})
    data = json.loads(urllib.request.urlopen(req).read())
    print(f'Secret key: {len(data)} rows returned')
except urllib.error.HTTPError as e:
    body = e.read().decode()[:100]
    print(f'Secret key failed: {e.code} - {body}')
```

### Step 3 — Interpret the Results

| Anon result | Secret result | Meaning |
|-------------|---------------|---------|
| `[]` | `[]` | Table is **truly empty**. No records exist. |
| `[]` | Data returned | RLS blocks anon access. **Data exists but secret key needed to see it.** |
| Data | Data | RLS permits anon read. Table has records. |

### Step 4 — When Secret Key Fails

If the secret key also returns an error:
1. **401 PGRST301: Expected 3 parts in JWT** — Wrong auth method. Key has `sb_` prefix, use `apikey` only (not Bearer).
2. **401 Unauthorized** — Key may be expired. Check environment variable length vs expected length.
3. **400 Bad Request** — Invalid table name or column in query. Verify schema first with `select=*&limit=1`.

### Key Length Validation

The terminal display may truncate env values (e.g., showing `sb_sec...G5bx` as 14 chars). Always verify with Python:

```python
k = os.environ.get('SUPABASE_SECRET_KEY', '')
print(f'Secret key length: {len(k)}')
# Expected: 41 chars for sb_secret_ keys
```

## Live Example (from session 2026-06-04)

The anon key returned `[]` for all tables (projects, clients, tasks, decisions). After user said "Not possible. Verify," testing the secret key with `apikey` header revealed **6 active projects, 5 clients, 28 decisions, and 6 agent runs.** The data was there all along — the first answer was RLS-restricted, not empty.
