# Multi-Tenant JWT Scoping (Streetwise Pattern)

Clean multi-tenant isolation where the **backend** handles tenant scoping entirely via JWT claims. The frontend never manages community context.

## Architecture

```
Frontend (no tenant context)
  ↕ JWT with community_id claim
Backend (reads community_id from JWT)
  ↕ scoped queries WHERE community_id = $1
Database (tenant data isolated by community_id)
```

## How it works

### 1. Clerk JWT template embeds community_id

In Clerk Dashboard → JWT Templates → `streetwise` template:

```json
{
  "community_id": "{{user.public_metadata.community_id}}",
  "roles": "{{user.public_metadata.roles}}"
}
```

### 2. Backend guard extracts it

```ts
// In the JwtAuthGuard / JwtAuthGuard:
request.user = {
  id: payload.sub,
  roles: (payload as any).roles ?? [],
  community_id: (payload as any).community_id ?? null,
  ...payload,
};
```

### 3. Controllers use it for scoping

```ts
@Get(':id')
@UseGuards(JwtAuthGuard, RolesGuard)
async findOne(@Param('id') id: string, @Req() req: any) {
  // req.user.community_id is available without any frontend input
  return this.service.findOne(id, req.user.community_id);
}
```

### 4. Services filter by community_id

```ts
async findResidents(communityId: string) {
  return this.prisma.resident.findMany({
    where: { communityId }, // scoped automatically
  });
}
```

## Benefits

- **Frontend never needs to pass community_id** — no context providers, no URL params, no extra request body fields
- **JWT is the source of truth** — users can only see data from their community
- **No tenant leak** — even if a frontend sends a different community_id, the backend overrides with the JWT value
- **Role-based access** — `super_admin` role can see all communities; regular users are scoped

## Pitfalls

- **Middleware/community-scope must also read from JWT** — don't rely on request body or URL params for tenant identity
- **Super admin bypass** — check for `super_admin` role before applying community scope filter
- **JWT template must be configured** — without the `streetwise` template, the JWT won't have custom claims. `getToken()` without a template name returns a JWT with only standard claims (sub, exp, iat, etc.)
- **Cross-community operations** (broadcast, system admin) require explicit role checks, not just community_id
