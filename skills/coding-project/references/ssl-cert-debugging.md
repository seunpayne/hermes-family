# SSL Certificate Debugging for Supabase Pooler Connections

When connecting to a Supabase connection pooler (`*.pooler.supabase.com:5432`) from
Node.js, Prisma, or any client that validates TLS certificates, the pooler's
**self-signed certificate** causes authentication-like error messages that
are misleading. This reference covers how to diagnose whether the real
problem is SSL or password.

## Symptoms

| Error message | Likely real cause |
|---|---|
| Prisma: `Authentication failed for user 'postgres'` | SSL cert validation failure — Prisma reports it as auth failure |
| pg module: `self-signed certificate in certificate chain` | SSL verify-full mode rejects self-signed pooler cert |
| pg module: `password authentication failed for user 'postgres'` | Either actual wrong password, OR SSL failure masked as auth failure |
| `no tenant identifier provided` | SSL/SNI missing entirely — `sslmode=require` not set |

## Key Insight: `sslmode=require` is treated as `verify-full`

The `pg-connection-string` module (used by Prisma and the `pg` npm module)
maps `sslmode=require` to **`rejectUnauthorized: true`** — same as
`verify-full`. This means the client will reject the pooler's self-signed
certificate.

**From the pg-connection-string source (pg@8.x):**

```
'require' → rejectUnauthorized=true (verify-full behavior, despite "require" name)
'verify-full' → rejectUnauthorized=true + check hostname
'no-verify' → rejectUnauthorized=false (the one that actually works with self-signed)
'prefer' → try SSL first, fall back to plain
'disable' → no SSL
```

Contrary to PostgreSQL's own behavior where `sslmode=require` skips certificate
validation, the Node.js `pg` module treats it the same as `verify-full`.

**This means:** `sslmode=require` in your DATABASE_URL will fail against
Supabase poolers because the pooler uses a self-signed certificate that
doesn't match the hostname verification chain.

## Diagnostic Scripts

### 1. Is the pooler even reachable?

```python
import socket
host = 'aws-1-eu-west-1.pooler.supabase.com'
s = socket.socket()
s.settimeout(5)
try:
    s.connect((host, 5432))
    print(f'✅ {host}:5432 reachable')
except Exception as e:
    print(f'❌ {host}:5432 — {str(e)[:80]}')
s.close()
```

### 2. Is the password correct? (Raw TLS test)

This test performs a TLS handshake with the pooler using SNI (Server Name
Indication) to identify the tenant project. It verifies the password without
relying on the pg module's SSL handling:

```javascript
const tls = require('tls');
const net = require('net');

const poolerHost = 'aws-1-eu-west-1.pooler.supabase.com';
const port = 5432;
const password = 'your-password-here';

const socket = net.connect(port, poolerHost, () => {
    // Upgrade to TLS with SNI for pooler tenant routing
    const tlsSocket = tls.connect({
        socket: socket,
        servername: poolerHost,                // SNI — tells pooler which project
        rejectUnauthorized: false,              // Bypass self-signed cert check
    }, () => {
        console.log('✅ TLS established with SNI');
        console.log(`Authorized: ${tlsSocket.authorized}`);
        // Send startup packet to authenticate
        const user = 'postgres.project_ref';
        const startupLen = 4 + 4 + user.length + 1 + password.length + 1 + 1;
        const buf = Buffer.alloc(startupLen);
        buf.writeUInt32BE(startupLen, 0);           // Length
        buf.writeUInt32BE(0x00030000, 4);            // Protocol 3.0
        buf.write(user, 8, 'utf8');                  // User
        buf.write(Buffer.from([0]), 8 + user.length); // null
        buf.write(password, 9 + user.length, 'utf8'); // Password
        buf.write(Buffer.from([0]), 9 + user.length + password.length);
        tlsSocket.write(buf);
        tlsSocket.on('data', (data) => {
            const code = data.readUInt8(0);
            if (code === 0x52) console.log('✅ Authentication OK');
            else if (code === 0x45) {
                const msg = data.toString('utf8', data.indexOf('\0', 5) + 1, data.length - 1);
                console.log(`❌ Auth failed: ${msg}`);
            }
        });
    });
});
socket.on('error', (e) => console.log('❌ Socket:', e.message));
tlsSocket.on('error', (e) => console.log('❌ TLS:', e.message));
```

**Reading the result:**
- `"TLS established with SNI"` = network AND SSL work. The password was
  accepted by the TLS layer. This means the pooler IS routing to your project.
- `"Authentication OK"` (0x52) = password is definitively correct.
- `"Auth failed"` (0x45) = password is definitively wrong — reset it.

### 3. Inspect the certificate chain with openssl

```bash
openssl s_client -connect aws-1-eu-west-1.pooler.supabase.com:5432 \
  -servername aws-1-eu-west-1.pooler.supabase.com \
  -starttls postgres 2>&1 | head -30
```

Look for:
- `Certificate chain` — if it shows a single self-signed cert, the pooler
  is using a self-signed cert. This is expected for Supabase poolers.
- `Verify return code: 19 (self-signed certificate in certificate chain)` —
  confirms the issue is SSL cert validation, not password.

### 4. Test pg module connection with SSL bypass

```javascript
const { Client } = require('pg');
const client = new Client({
    host: 'aws-1-eu-west-1.pooler.supabase.com',
    port: 5432,
    user: 'postgres.project_ref',
    password: 'your-password-here',
    database: 'postgres',
    ssl: {
        rejectUnauthorized: false,    // Accept self-signed cert
        servername: 'aws-1-eu-west-1.pooler.supabase.com'  // SNI
    },
    connectionTimeoutMillis: 10000,
});
try {
    await client.connect();
    const res = await client.query('SELECT 1 AS test');
    console.log('✅ Connected:', res.rows[0]);
} catch(e) {
    console.log('❌', e.message.slice(0, 120));
}
```

If this works with `rejectUnauthorized: false` but fails with
`rejectUnauthorized: true` (or omitted), the issue is definitively the
self-signed certificate — not the password.

## What DOESN'T work to fix this

| Approach | Result |
|---|---|
| `sslmode=require` in connection string | Treated as verify-full — fails on self-signed cert |
| downgrade pg from 8.21.0 to 8.11.0 | Same behavior — verify-full is consistent across versions |
| `NODE_TLS_REJECT_UNAUTHORIZED=*** | Bypasses SSL but password auth then fails differently |
| `pgbouncer=true` | Only affects transaction mode, not SSL handling |

## What DOES work (pick one)

### A. Prisma: use `sslmode=no-verify`

If your Prisma version supports this syntax:

```
DATABASE_URL="postgresql://postgres.project_ref:***@aws-N-region.pooler.supabase.com:5432/postgres?sslmode=no-verify&pgbouncer=true&connection_limit=1"
```

### B. Session-mode pooler on port 5432

Supabase poolers listen on TWO ports:
- 6543 = transaction mode (PgBouncer — supports `pgbouncer=true`)
- 5432 = session mode (direct — supports migrate deploy)

If the pooler accepts connections on 5432, use that port:

```
DATABASE_URL="postgresql://postgres.project_ref:***@aws-N-region.pooler.supabase.com:5432/postgres?sslmode=require&connection_limit=1"
```

### C. Fallback: SQL Editor (always works)

1. `npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script > migration.sql`
2. Open `https://supabase.com/dashboard/project/<ref>/sql/new`
3. Paste and run
4. `npx prisma generate`
5. For seed data, run the seed script from a machine with working DB access

## Error Message Translation Guide

| What you see | What it REALLY means |
|---|---|
| `password authentication failed for user "postgres"` (Prisma) | Could be actual wrong password, OR SSL cert rejection reported as auth error. Run the raw TLS test above to distinguish. |
| `self-signed certificate in certificate chain` | Definitively SSL. Password may be correct. |
| `no tenant identifier provided` | SSL/SNI not used — add `sslmode=require` to URL |
| `Tenant or user not found` | Pooler can't route — wrong project ref or pooler not enabled |
| `Can't reach database server` | IPv6-only DNS or port blocked — use pooler or SQL Editor |
| `connect ETIMEDOUT` | Port blocked by firewall — try pooler on 5432 or use SQL Editor |
| `JWT could not be decoded` (Supabase API) | Using new `sb_*` API key format against Management API that expects classic JWT. Use SQL Editor instead. |

## Summary Diagnostic Flow

```
Is port 5432/6543 reachable?
  ├── NO → SQL Editor (fastest bypass)
  └── YES → openssl s_client for SSL chain
      ├── Self-signed cert → use rejectUnauthorized: false in pg code,
      │                      or use raw TLS test to verify password
      └── Cert chain OK → test with pg module directly
          ├── Works → check Prisma config / migration approach
          └── Fails → password is wrong, reset in Supabase Dashboard
```
