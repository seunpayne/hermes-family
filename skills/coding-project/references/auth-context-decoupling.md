# ADD-025: Decouple Authorization from Clerk Session Metadata

## The Problem

Clerk snapshots user metadata into the session at creation time. When a user signs up, the session starts with whatever metadata existed at that moment (usually empty). The webhook sets `roles` and `community_id` via `PATCH /v1/users/:id/metadata` — but this updates the user RECORD, not the active SESSION. `getToken()` returns JWTs from the session snapshot. The browser's Clerk client caches the session token. No amount of retry or backend session refresh fixes this.

## The Solution

**The JWT's only job becomes identity (`sub` claim, always present). Roles and community context come from the database.**

```
JWT → identity only (sub) → backend resolves roles+community from DB
Frontend → AuthProvider → GET /v1/auth/context → React Context → all pages use useAuthContext()
Backend → JwtAuthGuard → resolveAuthContext() → UserRole table (Priority 1), Community.ownerClerkId fallback (Priority 2)
Webhook → creates Community + seeds UserRole (no session refresh needed)
```

## Backend: GET /v1/auth/context

### Prisma Schema
```prisma
model UserRole {
  id            String    @id @default(cuid())
  clerkUserId   String    @unique
  roles         String[]  // ['estate_admin'], ['security'], etc.
  communityId   String    @unique
  communityName String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}
```

### Controller
```typescript
@Controller('v1/auth/context')
export class AuthContextController {
  @Get()
  @UseGuards(JwtAuthGuard)  // No RolesGuard — always returns 200
  async getContext(@Req() req: any) {
    return this.authContextService.resolve(req.user.sub);
  }
}
```

### Service — Resolution Priorities
```typescript
async resolve(clerkUserId: string): Promise<AuthContext> {
  // Priority 1: UserRole table (authoritative — seeded by webhook/invitations)
  const userRole = await this.prisma.userRole.findUnique({ where: { clerkUserId } });
  if (userRole?.communityId) {
    return { userId: clerkUserId, roles: userRole.roles, communityId: userRole.communityId, ... };
  }

  // Priority 2: Community.ownerClerkId fallback (seeds UserRole on first call)
  const owned = await this.prisma.community.findFirst({ where: { ownerClerkId: clerkUserId } });
  if (owned) {
    await this.seedUserRole(clerkUserId, ['estate_admin'], owned.id, owned.name);
    return { userId: clerkUserId, roles: ['estate_admin'], communityId: owned.id, ... };
  }

  // Priority 3: Clerk API fallback (reads metadata from Clerk user record)
  // Priority 4: Empty context — always returns 200 OK
  return empty;
}
```

### JwtAuthGuard — Must Use Same Priority Order
The guard sets `request.user.roles` and `request.user.community_id` on every request.

```typescript
private async resolveAuthContext(clerkUserId: string) {
  // Priority 1: UserRole table
  const userRole = await this.prisma.userRole.findUnique({ where: { clerkUserId } });
  if (userRole) return { roles: userRole.roles, communityId: userRole.communityId };

  // Priority 2: Community.ownerClerkId
  const owned = await this.prisma.community.findFirst({ where: { ownerClerkId: clerkUserId } });
  if (owned) return { roles: ['estate_admin'], communityId: owned.id };

  return { roles: [], communityId: null };
}
```

**PITFALL — Dual priority order:** Both the service AND the guard must use the same resolution order. If they disagree (service: UserRole first, guard: owner first), `GET /v1/auth/context` returns correct roles but every API call still uses stale roles from the guard. Always update both files when changing the priority order. Additionally, if the guard has Community.ownerClerkId as Priority 1, it hardcodes `['estate_admin']` and never reaches the UserRole table — so manual role updates via Supabase SQL have no effect. The exact bug: user manually sets `roles: ['super_admin']` in UserRole table, but API calls still return `estate_admin` because the guard's `resolveAuthContext()` finds `ownerClerkId` first and returns `['estate_admin']` before ever querying UserRole.

### Webhook Seeds UserRole (Not Session Refresh)
```typescript
// In clerk-webhook.controller.ts, after creating community:
await this.prisma.userRole.upsert({
  where: { clerkUserId: ownerClerkId },
  create: { clerkUserId: ownerClerkId, roles: ['estate_admin'], communityId: community.id, communityName: community.name },
  update: { roles: ['estate_admin'], communityId: community.id, communityName: community.name },
});
// DELETE the POST /v1/sessions/:id/refresh block — no longer needed
```

## Frontend: AuthContext Provider

```typescript
// auth-context.tsx
export function useAuthContext() {
  const ctx = useContext(AuthContext);
  return ctx; // { roles, communityId, communityName, phase, dpaSignedAt }
}
```

### All Components Migrate
```typescript
// OLD (deleted):
const { sessionClaims } = useAuth();
const roles = (sessionClaims as any)?.roles ?? [];

// NEW:
const { roles, communityId } = useAuthContext();
```

## What Gets Deleted
- AuthProvider exponential backoff retry (2s/4s/8s)
- `/loading` page
- `getMyCommunity()` backend fallback
- Sidebar `effectiveRoles` fallback
- Webhook `POST /v1/sessions/:id/refresh`
- Middleware role-based routing from sessionClaims
- All `sessionClaims.roles` and `sessionClaims.community_id` reads

## Verification (Browser Console)
```javascript
const token = await window.Clerk.session.getToken({ template: 'streetwise' });
const res = await fetch('https://backend.../v1/auth/context', {
  headers: { Authorization: `Bearer ${token}` }
});
console.log(await res.json());
// Should return { roles: ['super_admin'], communityId: '...' } from DB
```
