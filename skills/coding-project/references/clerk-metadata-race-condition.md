# Clerk Session Metadata Race Condition — Pattern

## Root Cause
Clerk snapshots user metadata into the session at creation time. When a user signs up, the session starts with whatever metadata existed at that moment (usually empty). Any backend updates via the REST API (`PATCH /v1/users/:id/metadata`) update the user record but NOT the active session. `getToken()` returns JWTs from the session snapshot, not the user record.

## Symptoms
- `sessionClaims.roles` is `[]` on first page load
- `sessionClaims.community_id` is `null`
- Guards land on `/admin` instead of `/guard`
- Sidebar renders blank (all items filtered by empty roles)
- All API calls return 401 (no community context)

## Failed Workarounds (do not repeat)
1. **AuthProvider retry** — `getToken()` with exponential backoff (2s/4s/8s). Still returns stale token because session metadata hasn't changed.
2. **Session refresh via REST API** — `POST /v1/sessions/:id/refresh` after setting metadata. Browser Clerk client doesn't pick up the server-side refresh.
3. **Loading page with sessionClaims retry** — Retries `useAuth().sessionClaims` with backoff. Same stale data, different polling target.
4. **getToken() + JWT decode** — Requests a fresh token, but Clerk still issues from the stale session.
5. **getMyCommunity() backend fallback** — Resolves community from `Community.ownerClerkId` but doesn't resolve ROLE. Guards get sent to `/admin` because the query only checks community existence.

## Solution (ADD-025): Decouple Authorization from Clerk Metadata
The JWT's only job becomes identity (`sub` claim, which is ALWAYS present). Roles and community context come from the database.

**CRITICAL**: Two files must use the same resolution order — the auth-context.service (for `GET /v1/auth/context`) AND the JwtAuthGuard's internal `resolveAuthContext()` (for every API call). If the guard checks `Community.ownerClerkId` before `UserRole`, manual Supabase role updates have zero effect — the guard hardcodes `['estate_admin']` on every request and never reaches the UserRole table. This exact bug was hit: user manually set `super_admin` in UserRole table but every API call still returned `estate_admin`.

### Architecture
```
JWT → identity only (sub) → backend resolves roles+community from DB
Frontend → AuthProvider → GET /v1/auth/context → React Context → all pages use useAuthContext()
Backend → JwtAuthGuard → resolveAuthContext() → Community.ownerClerkId or UserRole table
Webhook → creates Community + seeds UserRole (no session refresh needed)
```

### Key components
1. **UserRole table** (Prisma): `clerkUserId`, `roles`, `communityId`, `communityName` — authoritative role storage
2. **GET /v1/auth/context** endpoint: resolves roles+community from UserRole table (Priority 1), then `Community.ownerClerkId` fallback (Priority 2, also seeds UserRole), then Clerk API fallback (Priority 3), then empty context (Priority 4, always returns 200)
3. **AuthContext React context**: `useAuthContext()` hook that all pages import instead of reading `sessionClaims`
4. **Webhook seeds UserRole**: `user.created` handler upserts into UserRole table with `roles: ['estate_admin']` for new signups, `roles: ['security']` for guard invitations

### What gets removed
- AuthProvider exponential backoff retry
- Loading page retry with backoff
- `getMyCommunity()` fallback in admin dashboard
- Sidebar `effectiveRoles` fallback
- Webhook session refresh
- Middleware role-based routing from sessionClaims

### Post-deploy
Run SQL migration to create UserRole table. Existing users are seeded on first `GET /v1/auth/context` call via Priority 2 fallback.
