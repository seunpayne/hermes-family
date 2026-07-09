# Clerk Webhook Handler — NestJS

## Installation

```bash
npm install svix
```

The `svix` package is required. **Do NOT implement manual HMAC verification** — the official package handles:
- Body canonicalization
- Secret format (whsec_ prefix is handled internally)
- Multi-signature matching (Svix sends `v1,sig1 v1,sig2...`)

## CRITICAL — Raw Body Required

Svix `Webhook.verify()` requires the **raw request body as a Buffer**, not a parsed JSON object.
NestJS's `@Body()` decorator returns a parsed object — passing it to `wh.verify()` produces:

```
Error: Expected payload to be of type string or Buffer.
```

**Fix — two-step configuration:**

### Step 1 — Enable rawBody in main.ts

```typescript
const app = await NestFactory.create(AppModule, {
  rawBody: true,  // Required for webhook signature verification
});
```

### Step 2 — Use RawBodyRequest in the controller

```typescript
import { Controller, Post, Req, Headers, BadRequestException, RawBodyRequest, Logger } from '@nestjs/common';
import { Request } from 'express';
import { Webhook } from 'svix';

@Controller('v1/webhooks/clerk')
export class ClerkWebhookController {
  private readonly wh: Webhook | null = null;

  constructor() {
    const secret = process.env.CLERK_WEBHOOK_SECRET;
    if (secret) this.wh = new Webhook(secret);
  }

  @Post()
  @Public()
  async handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('svix-id') svixId: string,
    @Headers('svix-timestamp') svixTimestamp: string,
    @Headers('svix-signature') svixSignature: string,
  ) {
    if (this.wh) {
      if (!req.rawBody) {
        throw new BadRequestException('No raw body available for verification');
      }
      try {
        this.wh.verify(req.rawBody, {
          'svix-id': svixId,
          'svix-timestamp': svixTimestamp,
          'svix-signature': svixSignature,
        });
      } catch (err) {
        this.logger.error(`Webhook signature verification failed: ${(err as Error).message}`);
        throw new BadRequestException('Invalid webhook signature');
      }
    }

    // Parse raw body AFTER signature verification
    const body = JSON.parse(req.rawBody.toString());
    const { type, data } = body;
    // ... handle event
  }
}
```

**Why svix needs the raw body:** When NestJS parses the JSON into an object and you `JSON.stringify()` it back, whitespace and key ordering may differ from the original bytes. Svix's HMAC is computed against the original unchanged bytes. Only `req.rawBody` (a Buffer) preserves the exact bytes.

## SkipAudit Required

Webhook controllers receive requests WITHOUT auth context. The global `AuditLogInterceptor` fires on all `POST` routes and uses `request.communityId || 'unknown'`. Webhook requests have no `communityId` → falls back to `'unknown'` → violates the AuditLog FK constraint (references Community.id).

**Fix:**
```typescript
import { SkipAudit } from '../../common/decorators/skip-audit.decorator';

@SkipAudit()  // Class-level decorator
@Controller('v1/webhooks/clerk')
export class ClerkWebhookController { ... }
```

## User.Created Handler — Full Pattern

```typescript
private async handleUserCreated(userData: any) {
  const email = userData.email_addresses?.[0]?.email_address;
  const metadata = userData.public_metadata ?? {};

  // Skip demo users
  if (metadata.is_demo) return { message: 'Demo user skipped' };
  // Skip pre-configured users (guard invites, etc)
  if (metadata.roles?.length > 0 && metadata.community_id) {
    return { message: 'Pre-configured user skipped' };
  }

  const community = await this.communityService.createFromWebhook({
    name: metadata.estate_name || `${email.split('@')[0]}'s Estate`,
    ownerEmail: email,
    ownerClerkId: userData.id,
  });

  // Step A — Set Clerk user metadata
  await fetch(`https://api.clerk.com/v1/users/${userData.id}/metadata`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${process.env.CLERK_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      public_metadata: {
        roles: ['estate_admin'],
        community_id: community.id,
      },
    }),
  });

  // Step B — Seed UserRole table (ADD-025 pattern — preferred)
  // This is the permanent fix. Roles come from the DB, never from session metadata.
  await this.prisma.userRole.upsert({
    where: { clerkUserId: userData.id },
    create: {
      clerkUserId: userData.id,
      roles: ['estate_admin'],
      communityId: community.id,
      communityName: community.name,
    },
    update: {
      roles: ['estate_admin'],
      communityId: community.id,
      communityName: community.name,
    },
  });

  // Session refresh (DEPRECATED — remove when using ADD-025 UserRole table)

  return { message: 'Community auto-provisioned', communityId: community.id };
}
```

### Session Refresh Pattern

`PATCH /v1/users/:id/metadata` updates the **user record**, not the **active session token cache**. The browser's Clerk client caches the old session token. `getToken()` continues returning JWTs without `community_id` — no amount of frontend retry fixes this.

**Fix — refresh all active sessions after setting metadata:**

```typescript
private async refreshActiveSessions(clerkUserId: string): Promise<void> {
  try {
    const sessionsRes = await fetch(
      `https://api.clerk.com/v1/users/${clerkUserId}/sessions`,
      {
        headers: { 'Authorization': `Bearer ${process.env.CLERK_SECRET_KEY}` },
      },
    );
    if (!sessionsRes.ok) return;
    const sessions = await sessionsRes.json();
    for (const session of sessions) {
      if (session.status === 'active') {
        await fetch(`https://api.clerk.com/v1/sessions/${session.id}/refresh`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${process.env.CLERK_SECRET_KEY}` },
        });
      }
    }
  } catch (err) {
    // Non-fatal — community is already created
    this.logger.error(`Failed to refresh sessions: ${(err as Error).message}`);
  }
}
```

**Why this is needed:**
1. User signs up → Clerk creates user + session (metadata snapshot: null)
2. Webhook fires → `PATCH /v1/users/:id/metadata` updates user record
3. Active session still has the OLD metadata snapshot
4. `getToken()` returns JWT from the stale session → `community_id: null`
5. `POST /v1/sessions/:id/refresh` forces Clerk to rebuild the session's JWT template with current metadata
6. Next `getToken()` call returns JWT with `community_id` populated

## Community Resolver Fallback

Even with session refresh, the browser Clerk client may cache the old token. Add a backup resolver endpoint that uses the JWT `sub` claim (always present regardless of metadata):

### Backend — community.controller.ts

```typescript
@Get('my-community')
@UseGuards(JwtAuthGuard)
async getMyCommunity(@Req() req: any) {
  return this.communityService.findByOwnerOrMember(req.user?.sub);
}
```

### Backend — community.service.ts

```typescript
async findByOwnerOrMember(clerkUserId: string) {
  if (!clerkUserId) throw new NotFoundException('User not identified');

  const owned = await this.prisma.community.findFirst({
    where: { ownerClerkId: clerkUserId },
    select: { id: true, name: true, phase: true, dpaSignedAt: true },
  });
  if (owned) return owned;

  throw new NotFoundException('No community found for this user');
}
```

### Frontend — admin dashboard fallback

```typescript
const [communityId, setCommunityId] = useState<string | null>(
  (sessionClaims as any)?.community_id ?? null
);

useEffect(() => {
  if (!communityId && userId) {
    getMyCommunity()
      .then(community => setCommunityId(community.id))
      .catch(() => {
        // Retry once after 5s (webhook may still be processing)
        setTimeout(async () => {
          try {
            const c = await getMyCommunity();
            setCommunityId(c.id);
          } catch { /* give up — empty dashboard */ }
        }, 5000);
      });
  }
}, [communityId, userId]);
```

## Webhook Auto-Provisioning — Community Service

### createFromWebhook pattern

```typescript
async createFromWebhook(dto: { name: string; ownerEmail: string; ownerClerkId: string }) {
  // Check for existing community
  const existing = await this.prisma.community.findFirst({
    where: { ownerClerkId: dto.ownerClerkId },
  });
  if (existing) return existing;

  // Generate unique slug
  let slug = this.generateSlug(dto.name);
  const slugExists = await this.prisma.community.findUnique({ where: { slug } });
  if (slugExists) slug = `${slug}-${Math.random().toString(36).substring(2, 6)}`;

  // Assign early access slot
  const earlyAccessCount = await this.prisma.community.count({
    where: { isEarlyAccess: true, earlyAccessSlotNumber: { not: null } },
  });
  const hasSlot = earlyAccessCount < this.MAX_EARLY_ACCESS_SLOTS;

  // Create Community + Subscription in transaction
  return this.prisma.$transaction(async (tx) => {
    const comm = await tx.community.create({
      data: {
        name: dto.name, slug, phase: 'foundation', status: 'active',
        isEarlyAccess: hasSlot, earlyAccessSlotNumber: hasSlot ? earlyAccessCount + 1 : null,
        ownerClerkId: dto.ownerClerkId,
      },
    });
    await tx.subscription.create({
      data: {
        communityId: comm.id, planTier: 'starter', billingCycle: 'monthly',
        amount: hasSlot ? EARLY_ACCESS_PRICE : FULL_PRICE,
        isEarlyAccess: hasSlot, earlyAccessSlotNumber: hasSlot ? earlyAccessCount + 1 : null,
        status: 'active',
      },
    });
    return comm;
  });
}
```

### Prisma schema addition

```prisma
model Community {
  // existing fields...
  ownerClerkId String? @unique  // Clerk user ID of the estate admin who created this community
}
```

## Module Registration

```typescript
// webhooks.module.ts
@Module({
  imports: [CommunityModule],
  controllers: [ClerkWebhookController],
})
export class WebhooksModule {}

// app.module.ts — add to imports array
WebhooksModule,
```

## Clerk Dashboard Configuration

1. Clerk Dashboard → Webhooks → Add endpoint
2. URL: `https://<your-backend>.railway.app/v1/webhooks/clerk`
3. Events: select `user.created`
4. Save → copy **Signing Secret** (starts with `whsec_`)
5. Set Railway backend env vars:
   - `CLERK_WEBHOOK_SECRET=whsec_...`
   - `CLERK_SECRET_KEY=sk_...` (already needed for metadata writes)
   - `FRONTEND_URL=https://frontend-xxx.up.railway.app`

## Body Parsing Summary

| Webhook type | Method | Reason |
|-------------|--------|--------|
| Clerk (svix) | `req.rawBody` Buffer → `wh.verify(buffer)` | Session metadata race condition fix requires raw bytes |
| Paystack | `req.rawBody` Buffer (rawBody: true) | HMAC computed against raw JSON bytes |
| Meta/WhatsApp | `req.rawBody` Buffer (rawBody: true) | Signature based on raw payload |
| Svix library | `@Body()` object → `wh.verify(object)` works for svix 1.x+ | Library handles canonicalization |

**Rule of thumb:** If the webhook provider gives a signing secret (`whsec_`, `sk_live_`), always use `req.rawBody`. If the library claims to accept objects (svix), verify with a real webhook call before trusting the docs — the library may need raw bytes depending on the version.
