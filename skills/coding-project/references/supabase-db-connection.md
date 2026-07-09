# Debugging Supabase PostgreSQL Connection from Docker

## Problem

From inside a Docker/headless container, `prisma migrate deploy` fails with:
- `Can't reach database server` — socket timeout on port 5432
- `Tenant or user not found` — pooler auth failure

## Step-by-Step Diagnosis

```python
# 1. Check DNS resolution (IPv4 vs IPv6)
import socket
info = socket.getaddrinfo('db.[project-ref].supabase.co', 5432)
for i in info:
    print(i[0].name, i[4][0])  # AF_INET6 = IPv6 only

# 2. Test port connectivity
for port in [443, 5432, 6543]:
    s = socket.socket()
    s.settimeout(3)
    try:
        s.connect(('[host]', port))
        print(f'Port {port}: OPEN')
    except Exception as e:
        print(f'Port {port}: {str(e)[:60]}')
    s.close()
```

## Connection Options (in priority order)

### Option A: Supabase SQL Editor (fastest, no connectivity needed)
Open `supabase.com/dashboard/project/[ref]/sql/new`, paste migration SQL, run.

### Option B: Connection Pooler must be ENABLED in Supabase Dashboard
**Project Settings → Database → Connection Pooling** must be toggled ON.

Connection string (with SSL — required by pooler):
```
postgresql://postgres.[project-ref]:***@aws-0-[region].pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true&connection_limit=1
```

### Option C: Find the pooler region

**PITFALL — the pooler counter `{N}` and `{region}` may NOT match your project's compute region.** The pooler hostname format is `aws-{N}-{region}.pooler.supabase.com` where `{N}` is a counter (0, 1, 2...) and `{region}` is the AWS region code. Both may differ from what the project dashboard shows. Example: compute was `eu-west-2` but pooler was `aws-1-eu-west-1`.

Scan multiple combinations:
```python
import socket
for region in ['eu-west-2', 'eu-west-1', 'us-east-1', 'eu-central-1']:
    for n in ['0', '1', '2']:
        host = f'aws-{n}-{region}.pooler.supabase.com'
        try:
            ip = socket.gethostbyname(host)
            s = socket.socket()
            s.settimeout(2)
            s.connect((ip, 5432))
            print(f'✅ {host}')
            s.close()
        except:
            pass
```

If socket connects but `prisma migrate deploy` shows `password authentication failed`, the pooler IS routing correctly — the password is wrong. Ask user to check Supabase Dashboard → Project Settings → Database → Database password (click Reveal).

## Pooler Error Meanings

| Error | Likely Cause |
|-------|-------------|
| `Tenant or user not found` | Pooler not enabled, wrong project ref, or wrong password |
| `no tenant identifier provided` | SSL/SNI missing — add `sslmode=require` |
| `ENOTFOUND` hostname | IPv6-only DNS — use pooler or SQL Editor |
| `password authentication failed` | Valid connection, wrong password value |

## prisma migrate deploy vs db push

| Command | When |
|---------|------|
| `prisma migrate deploy` | Production — sequential, transactional |
| `prisma db push --accept-data-loss` | Dev/quick — no migration file needed |
| `prisma migrate diff --from-empty --to-schema-datamodel --script` | Generate SQL without DB access |

## Password Handling

When the user gives a readable mixed-case string like `aKqvyXqIgouj4kEu`, it may NOT be the database password. Database passwords are typically auto-generated random strings shown in Supabase Dashboard → Database settings. The provided string might be the service role key.

**Safe password handling:** Write test scripts to files with `write_file` (never inline heredocs — bash expands `***`). Base64-encode credentials for maximum safety across tool boundaries.
