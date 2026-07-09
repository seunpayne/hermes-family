# Supabase Connection Pooler — Connectivity Guide

## When to Use the Pooler

Supabase project databases are often **IPv6-only** by default for the direct connection (`db.[project-ref].supabase.co:5432`). If your client environment (Docker container, cloud VM, corporate network) lacks IPv6 routing, use the **Session Pooler** for IPv4 connectivity.

## Pooler Connection String Format

```
postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-{N}-{REGION}.pooler.supabase.com:{PORT}/postgres?sslmode=require
```

| Component | Value | Notes |
|-----------|-------|-------|
| Username | `postgres.[PROJECT_REF]` | Project ref from Supabase dashboard URL, e.g. `tqacwivrwfsdsjdnxblp` |
| Password | Database password | From Supabase Dashboard → Project Settings → Database |
| Host | `aws-{N}-{REGION}.pooler.supabase.com` | Region found in pooler string from dashboard, e.g. `aws-1-eu-west-1` |
| Port | `5432` (session) or `6543` (transaction) | Prefer 5432 for Prisma migrations |
| SSL | `sslmode=require` | **Mandatory.** Pooler uses SNI to identify the tenant; no SSL = no tenant routing |

## Finding the Region

The pooler hostname differs by region. Do not guess — ask the user to copy the connection string from:

**Supabase Dashboard → Project Settings → Database → Connection string dropdown → select "Pooled"**

Example hostnames:
- `aws-1-eu-west-1.pooler.supabase.com`
- `aws-0-eu-west-2.pooler.supabase.com`
- `aws-0-us-east-1.pooler.supabase.com`

## Error Diagnosis

| Error | Meaning | Fix |
|-------|---------|-----|
| `(ENOTFOUND) tenant/user not found` | Wrong pooler hostname or project ref | Double-check region and project ref in username |
| `Authentication failed... credentials are not valid` | Wrong password | Get correct DB password from Supabase Dashboard |
| `no tenant identifier provided` | SSL not enabled | Add `?sslmode=require` to connection string |
| Connection timeout (direct) | IPv6 only, no IPv4 | Switch to pooler or enable IPv4 add-on |
| Connection refused / timeout (pooler) | Pooler not enabled | User must enable in Dashboard → Database → Connection Pooling |

## Prisma Configuration

For Prisma with the pooler:

```env
# Session pooler (recommended for migrations)
DATABASE_URL="postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-{N}-{REGION}.pooler.supabase.com:5432/postgres?sslmode=require&pgbouncer=true&connection_limit=1"
DIRECT_URL="postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-{N}-{REGION}.pooler.supabase.com:5432/postgres?sslmode=require"
```

- `pgbouncer=true` tells Prisma to use PgBouncer-compatible settings
- `connection_limit=1` prevents Prisma from opening multiple connections (PgBouncer limitation)
- `sslmode=require` is mandatory for SNI-based tenant routing

## Region Discovery

If the user cannot find the pooler hostname, ask them to check:
1. Supabase Dashboard → Project Settings → Database
2. Scroll to "Connection string" section
3. Switch the dropdown from "Direct" to "Pooled"
4. Copy the displayed connection string

The region suffix (e.g. `eu-west-1`) and the pooler index (e.g. `aws-1`) are embedded in that string.
