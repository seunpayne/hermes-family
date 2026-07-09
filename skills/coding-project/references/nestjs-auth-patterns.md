# NestJS Backend Auth Patterns (Clerk + JWKS + RBAC)

## Overview

This reference covers the auth architecture used in the Streetwise backend.

### Current architecture (ADD-025): Authorization from Database
The JWT's only job is identity (`sub` claim). Roles and community context come from the database via `GET /v1/auth/context`. See `references/auth-context-decoupling.md` for the full pattern.

### Legacy architecture (DEPRECATED): Authorization from sessionClaims
Previously, roles and community_id were read from Clerk session metadata via `sessionClaims`. This failed on first page load because Clerk snapshots session metadata at creation time. All workarounds (retry, session refresh, loading page, sidebar fallbacks) were removed by ADD-025.

---

## Clerk JWKS JWT Verification

### Architecture

```
Browser (Clerk session token)
  → Authorization: Bearer <JWT>
  → NestJS JwtAuthGuard
    → Extracts token from header
    → Calls jwks-rsa to fetch Clerk's public key from JWKS endpoint
    → Verifies RS256 signature + issuer claim
    → Sets req.user.id = payload.sub (Clerk user ID)
    → Attaches roles, community_id from custom claims
```

### Backend setup

**Dependencies:**
```
npm install jwks-rsa
# jsonwebtoken is already a NestJS dependency
```

**JwtAuthGuard pattern:**
```typescript
import * as jwt from 'jsonwebtoken';
import JwksRsa from 'jwks-rsa';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  private readonly client: JwksRsa.JwksClient | null;
  private readonly skipAuth: boolean;

  constructor(
    private readonly config: ConfigService,
    private readonly reflector: Reflector,
  ) {
    this.skipAuth = this.config.get<string>('SKIP_AUTH') === 'true';
    if (!this.skipAuth) {
      const issuer = this.config.get<string>('CLERK_JWT_ISSUER');
      this.client = JwksRsa({
        jwksUri: `${issuer}/.well-known/jwks.json`,
        cache: true,
        cacheMaxEntries: 5,
        cacheMaxAge: 600000, // 10 minutes
        rateLimit: true,
        jwksRequestsPerMinute: 10,
      });
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.skipAuth) {
      request.user = { id: 'dev-user-id', roles: ['super_admin'], community_id: null };
      return true;
    }
    const token = this.extractToken(request);
    const payload = await this.verifyClerkToken(token);
    request.user = {
      id: payload.sub,
      roles: (payload as any).roles ?? [],
      community_id: (payload as any).community_id ?? null,
      ...payload,
    };
    return true;
  }

  private verifyClerkToken(token: string): Promise<jwt.JwtPayload> {
    return new Promise((resolve, reject) => {
      const getKey: jwt.GetPublicKeyOrSecret = (header, callback) => {
        this.client!.getSigningKey(header.kid, (err, key) => {
          if (err) return callback(err);
          callback(null, key!.getPublicKey());
        });
      };
      jwt.verify(token, getKey, { algorithms: ['RS256'], issuer }, (err, decoded) => {
        if (err) return reject(err);
        resolve(decoded as jwt.JwtPayload);
      });
    });
  }
}
```

### Env vars
| Variable | Value | Purpose |
|----------|-------|---------|
| `CLERK_JWT_ISSUER` | `https://<app>.clerk.accounts.dev` | **Must be the Issuer URL, NOT the JWKS Endpoint URL.** Used both to construct the JWKS URI (`${issuer}/.well-known/jwks.json`) and to verify the JWT's `iss` claim. |
| `SKIP_AUTH` | `true` | Dev bypass — skips verification, sets mock super_admin user. Remove in production. |

### Critical: Issuer vs JWKS Endpoint
The `CLERK_JWT_ISSUER` variable is used for TWO purposes:
1. **JWKS URI construction:** `${issuer}/.well-known/jwks.json`
2. **JWT issuer verification:** `jwt.verify(token, key, { issuer })`

It must be the **Issuer** URL from the Clerk Dashboard (JWT Templates → your template → Issuer field). If you set it to the JWKS Endpoint URL, two things break:
- The JWKS URI becomes a double path (e.g. `https://.../jwks/.well-known/jwks.json`)
- The issuer check compares against the JWKS URL but the JWT contains the Issuer → mismatch → 401

### Clerk JWT Template
The Clerk JWT Template 'streetwise' must be created in Clerk Dashboard → JWT Templates:
```json
{
  "roles": ["{{user.public_metadata.roles}}"],
  "community_id": "{{user.public_metadata.community_id}}"
}
```
The frontend calls `getToken({ template: 'streetwise' })` to get a token with these claims.
If the template doesn't exist, `getToken()` returns `null` → no token sent → 401.

---

## RBAC Role Hierarchy

### Constants pattern
Create a central constants file at `src/common/constants/roles.constants.ts`:
```typescript
export const ADMIN_ROLES = ['super_admin', 'estate_admin'];
export const STAFF_ROLES = ['super_admin', 'estate_admin', 'secretariat'];
export const SECURITY_ROLES = ['super_admin', 'estate_admin', 'secretariat', 'security'];
export const ALL_AUTHENTICATED = ['super_admin', 'estate_admin', 'secretariat', 'security', 'resident', 'institution_admin'];
```

### Usage in controllers
```typescript
import { ADMIN_ROLES, STAFF_ROLES, SECURITY_ROLES } from '../../common/constants/roles.constants';

@Roles(...STAFF_ROLES)  // instead of @Roles('super_admin', 'estate_admin', 'secretariat')
```

### Role hierarchy rules
- `super_admin` inherits ALL permissions
- `estate_admin` inherits all `secretariat` permissions
- `secretariat` is the base staff role
- `security` has limited gate/scan permissions only
- `resident` is self-service only
- `institution_admin` is separate (invite-token-based access)

When auditing controllers: every `@Roles()` containing `secretariat` must also include `estate_admin` and `super_admin`. Every `@Roles()` containing `estate_admin` must include `super_admin`.

---

## AuthProvider — Frontend Token Sync

### Architecture
```
AuthProvider (client component, wraps admin layout)
  → Checks isLoaded, isSignedIn from Clerk
  → Calls getToken({ template: 'streetwise' })
  → Sets _authToken in api.ts module variable
  → Refreshes every 50 seconds (before Clerk's 60s expiry)
  → Blocks rendering children until token is ready (ready state)
  → Retries with exponential backoff if community_id is null in JWT
```

### Base64url-safe JWT decoding

`atob()` does NOT handle base64url (it chokes on `-` and `_`).
Use this pattern when decoding JWT payloads:

```typescript
function safeDecodeJwt(token: string): Record<string, unknown> | null {
  try {
    const base64 = token.split('.')[1]
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    const jsonStr = decodeURIComponent(
      atob(base64).split('').map(c => 
        '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
      ).join('')
    );
    return JSON.parse(jsonStr);
  } catch {
    return null;
  }
}
```

### Clerk session metadata race condition — exponential backoff retry

When a Clerk webhook sets user metadata (roles, community_id), the user's ACTIVE
session keeps the old metadata snapshot. `PATCH /v1/users/:id/metadata` updates
the user record — NOT the session. `getToken()` returns JWTs from the stale session.

The backend fix is `POST /v1/sessions/:id/refresh` (see nestjs-clerk-webhook.md).
The frontend fix is an exponential backoff retry in AuthProvider:

```typescript
const fetchToken = async (retriesLeft = 3) => {
  try {
    const token = await getToken({ template: 'streetwise' });
    if (!token) { clearAuthToken(); setReady(true); return; }

    const claims = safeDecodeJwt(token);
    if (claims?.community_id) {
      setAuthToken(token);
      setReady(true);
      return;
    }

    // community_id is null — webhook may still be processing
    if (retriesLeft > 0) {
      const delay = 2000 * (4 - retriesLeft); // 2s, 4s, 8s
      await new Promise(r => setTimeout(r, delay));
      return fetchToken(retriesLeft - 1);
    }

    // Exhausted retries — set token anyway (backend null guards handle it)
    setAuthToken(token);
    setReady(true);
  } catch (err) {
    console.error('[AuthProvider] getToken failed:', err);
    clearAuthToken();
    setReady(true);
  }
};
### Full AuthProvider pattern

```typescript
'use client';
import { useAuth } from '@clerk/nextjs';
import { useEffect, useRef, useState } from 'react';
import { setAuthToken, clearAuthToken } from '@/lib/api';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { isLoaded, isSignedIn, getToken } = useAuth();
  const [ready, setReady] = useState(false);
  const readyRef = useRef(false);  // Prevents double-fetch in StrictMode

  useEffect(() => {
    if (!isLoaded) return;
    if (readyRef.current) return;

    if (!isSignedIn) {
      clearAuthToken();
      readyRef.current = true;
      setReady(true);
      return;
    }

    // Initial token fetch with backoff retry
    const fetchToken = async (retries = 3) => {
      try {
        const token = await getToken({ template: 'streetwise' });
        if (!token) { clearAuthToken(); setReady(true); return; }

        const claims = safeDecodeJwt(token);
        if (claims?.community_id || retries <= 0) {
          setAuthToken(token);
          setReady(true);
          return;
        }

        // Wait 2s/4s/8s then retry
        await new Promise(r => setTimeout(r, 2000 * (4 - retries)));
        return fetchToken(retries - 1);
      } catch {
        clearAuthToken();
        setReady(true);
      }
    };

    fetchToken();
    readyRef.current = true;

    // Refresh every 50 seconds
    const interval = setInterval(async () => {
      const token = await getToken({ template: 'streetwise' });
      if (token) setAuthToken(token);
    }, 50000);

    return () => clearInterval(interval);
  }, [isLoaded, isSignedIn, getToken]);

  if (!ready) return null; // or spinner
  return <>{children}</>;
}
```

### Ready state guards race condition
```typescript
const [ready, setReady] = useState(false);
useEffect(() => { ... .finally(() => setReady(true)); }, [getToken]);
if (!ready) return null; // blocks children until token resolved
```

### 50-second refresh interval prevents stale tokens
```typescript
useEffect(() => {
  fetchToken();
  const interval = setInterval(fetchToken, 50000);
  return () => clearInterval(interval);
}, [isLoaded, isSignedIn, getToken]);
```

Middleware (`authMiddleware` / `clerkMiddleware`) handles route protection server-side.
AuthProvider handles token injection into API calls client-side.
Both are needed — they solve different problems.

---

## Community Scoping (Multi-tenant)

### Backend flow
1. Clerk JWT template embeds `community_id` from user's public metadata
2. `JwtAuthGuard` attaches `community_id` to `req.user`
3. Controller methods pass `req.user.community_id` to service layer
4. Service layer filters all queries by `compound: { communityId }`

### Null safety
When a Clerk user has no `community_id` set in their public metadata:
```typescript
if (!communityId) {
  return { data: [], total: 0, page, limit };
}
```
Without this guard, Prisma `findMany({ where: { compound: { communityId: null } } })` on a required `String` field throws a validation error → 500.

### Clerk user metadata setup
```json
{
  "roles": ["estate_admin", "secretariat"],
  "community_id": "cmq..."
}
```
Set in Clerk Dashboard → Users → select user → Public Metadata → Edit.
Sign out and back in after changing metadata (the old token has old claims).

---

## Design Decisions

### resident identity reconciliation (linkedClerkUserId)

As of ADD-035, `resident.id` is a **permanent `cuid()` — never mutated**.
The Clerk user ID (`sub` claim) is stored in `linkedClerkUserId`, a nullable
field on the Resident model. This separation exists because Clerk invitations
don't produce real user IDs immediately — only when the invitee completes sign-up.

**Two-field identity pattern:**
```
resident.id          = permanent cuid() — referenced by QR codes, visitor passes, payments
linkedClerkUserId    = Clerk user_xxx — set from invitation placeholder OR via webhook
```

**Reconciliation flow:**
1. Resident created via invitation → `linkedClerkUserId` set to Clerk invitation ID (`inv_xxx`)
2. Clerk `user.created` webhook fires when invitee signs up
3. Webhook handler calls `resident.updateMany({ where: { email, linkedClerkUserId: { not: null } }, data: { linkedClerkUserId: user.id } })`
4. `findByUserId()` now queries `findFirst({ where: { linkedClerkUserId: userId } })` — NOT `findUnique({ where: { id: userId } })`

**Why not `resident.id = Clerk.sub`?**
- QR codes, visitor passes, and payments reference `resident.id` as a foreign key
- Mutating a PK referenced by dozens of rows is dangerous and cascade-heavy
- Invitation IDs (`inv_xxx`) are not real user IDs and can't be used as PKs

**Careful:** `findUnique` requires the query field to have a `@@unique` constraint. `linkedClerkUserId` may not have one — prefer `findFirst` to avoid Prisma `findUnique` constraints on non-unique fields.

### Resident-owned resources: resolve via linkedClerkUserId first

Any endpoint scoped to "the current resident" must resolve via `linkedClerkUserId`
BEFORE performing an ownership check — never compare `req.user.sub` against
`resident.id` directly, since they are now different values:

```typescript
const resident = await this.residentsService.findByUserId(req.user.sub);
// Now use resident.id for DB queries and ownership checks
if (someResource.residentId !== resident.id) throw new ForbiddenException();
```

This applies to: SOS trigger, QR generation, levy payment, support ticket creation,
visitor pass creation, and any other resident-scoped endpoint.

### TierGuard: decorator-based tier gating

When feature access depends on a resident's `identityTier`, build a shared guard
with a decorator rather than duplicating tier checks in every service method:

```typescript
// tier.guard.ts
const TIER_ORDER: Record<string, number> = { basic: 0, verified: 1, full_kyc: 2 };

export const RequireTier = (tier: string) => SetMetadata('requiredTier', tier);

@Injectable()
export class TierGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredTier = this.reflector.get<string>('requiredTier', context.getHandler());
    if (!requiredTier) return true; // no tier requirement on this route

    const req = context.switchToHttp().getRequest();
    const resident = await this.residentsService.findByUserId(req.user?.sub);
    if (!resident) return true; // non-resident (staff/admin) — allow

    if (TIER_ORDER[resident.identityTier] < TIER_ORDER[requiredTier]) {
      throw new ForbiddenException(
        `Requires ${requiredTier} tier. Currently: ${resident.identityTier}.`
      );
    }
    return true;
  }
}

// In controller:
@UseGuards(JwtAuthGuard, RolesGuard, TierGuard)
@RequireTier('verified')
@Post()
```

Applied to: visitor-passes POST, payments/initiate POST, support-staff POST,
short-let-guests POST. All require 'verified' tier.

### Guard dashboard as public route
`/guard(.*)` is excluded from Clerk auth middleware for these reasons:
1. Security guards are low-tech users — auth at the gate creates friction
2. QR verification is read-only, served from offline cache
3. Backend `JwtAuthGuard` + `RolesGuard` protects all write operations
4. Offline-first design: guard dashboard must work without network

### Admin `/sign-in` and `/sign-up` routes
Clerk's `<SignIn>` / `<SignUp>` components need `[[...sign-in]]` and `[[...sign-up]]` catch-all route folders. These are not optional — Clerk's multi-step auth flow (email verification, SSO callbacks, MFA) needs the catch-all to handle intermediate URLs within the same route.

---

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| 401 "Invalid or expired token" | `CLERK_JWT_ISSUER` set to JWKS Endpoint not Issuer | Set to Issuer URL |
| 401 "No token provided" | JWT template 'streetwise' doesn't exist | Create template in Clerk Dashboard |
| 401 "No token provided" | AuthProvider race condition | Add ready-state that blocks children |
| 500 "PrismaClientValidationError" | `communityId` is null in Prisma query | Add `!communityId` guard returning empty set |
| 401 "Insufficient permissions" | `@Roles()` missing `estate_admin`/`super_admin` | Audit all controllers with RBAC constants |
| Sign Out doesn't work | `<Link href="/">` instead of Clerk `signOut()` | Use `useClerk().signOut()` then `router.push('/')` |
| community_id null in JWT after webhook | Session metadata is snapshotted at creation | Webhook must `POST /sessions/:id/refresh` after metadata update |
| Wizard never fires after signup | JWT has community_id: null AND session refresh hasn't propagated | Add AuthProvider exponential backoff retry AND community resolver fallback endpoint |
| All endpoints 401 after auth refactor | JwtAuthGuard and AuthContextService have DIFFERENT resolution priority orders | Audit both files — when duplicating resolution logic, keep ALL copies in sync. Run `grep -rn resolveAuthContext src/`. Every occurrence must have same priority. |
| 401 but can't access backend logs | Guard throws generic "Invalid or expired token" | Add verbose JwtAuthGuard: include jwt.verify error in 401 body |

## Verbose JwtAuthGuard Error Messages

When you can't access Railway logs, embed the failure reason in the 401 response:
```typescript
if (!this.client) { throw new UnauthorizedException('Authentication not configured'); }
try { payload = await this.verifyClerkToken(token); }
catch (err) { throw new UnauthorizedException(`Invalid token (${err.message.substring(0,80)})`); }
```
Maps: "No token"→sign out/in, "not configured"→set CLERK_JWT_ISSUER, "jwt expired"→reissue, "jwt issuer invalid"→fix issuer match.

## Dual Resolution Logic Pitfall

When `resolveAuthContext()` exists in BOTH `jwt-auth.guard.ts` AND `auth-context.service.ts`, a priority change in one MUST be mirrored in the other. The guard sets `request.user.roles` for every API call; the service answers `GET /v1/auth/context`. Audit with:
```bash
grep -rn "resolveAuthContext\|ownerClerkId\|UserRole" src/ --include="*.ts"
```

## @SkipAudit() on Webhook Controllers

Global `AuditLogInterceptor` fires on POST routes, uses `request.community_id || 'unknown'` → 'unknown' isn't a valid UUID → FK violation. Fix: `@SkipAudit()` class decorator on all webhook controllers.

