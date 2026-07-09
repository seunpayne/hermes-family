# Supabase Migration Pitfalls

## exec_sql RPC Does Not Exist By Default

Some Supabase instances have the `exec_sql` RPC function. Most do not.

### Symptoms
- 404 error: "Could not find the function public.exec_sql(query)"
- 403 Cloudflare Error 1010: "Access denied" — Management API blocked even with valid SUPABASE_SECRET_KEY
- Script runs but no tables are created
- Verification fails with "table does not exist"

### Management API may be Cloudflare-blocked (Hermes WebUI)
The Management API at `https://api.supabase.com/v1/projects/{ref}/database/query` may return
**403 Cloudflare Error 1010** even with a valid service_role key. This is a WAF block,
not an auth problem. Neither the service_role key nor any access token resolves this
from the Hermes WebUI Docker environment. Fall back to the Supabase Dashboard SQL Editor.

### Fallback Options (in order)

**1. Supabase Dashboard SQL Editor** — Most reliable
```
URL: https://supabase.com/dashboard/project/[project-id]/sql/new
```
Paste CREATE TABLE statements and run manually.

**2. Individual REST API Calls Per Table** — Slower but reliable
```javascript
await supabase.from('proto_products').insert({...})
```

**3. Direct PostgreSQL Connection** — Requires DATABASE_URL
```javascript
const { Client } = require('pg')
const client = new Client(process.env.DATABASE_URL)
await client.connect()
await client.query(sql)
```

### Best Practices

When writing Supabase migration scripts:
- Always include manual SQL as a comment block at the end
- Provide the dashboard URL in the error message
- Test verification via `.from(table).select()` not RPC calls
- Do not rely on `supabase.rpc('exec_sql')` existing

### Session Reference: Sync Engine Prototype (T-001)

**Failed approach:**
```javascript
const { error } = await supabase.rpc('exec_sql', { query: sql })
// Returns 404: Could not find the function public.exec_sql(query)
```

**Successful alternative:**
Manual execution via Supabase dashboard at:
`https://supabase.com/dashboard/project/tqacwivrwfsdsjdnxblp/sql/new`

Tables created with `proto_` prefix to isolate from production ERP schema:
- proto_products
- proto_transactions
- proto_sync_events
- proto_registered_devices

---

## Related Skills
- `coding-project` — Full project delivery protocol
- `erp-migration` — ERP data migration workflows
