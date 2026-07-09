# NestJS JWT Field Name Mismatches — Catalog

Two recurring bug classes in the Streetwise codebase where JWT payload field
names don't match what controllers read. Both produce silent failures — no
crash, just wrong behavior.

---

## Bug Class 1: `req.user.id` vs `req.user.sub`

**Root cause:** Clerk JWTs store the user identifier as `sub`, not `id`.
Controllers written from memory or copied from non-Clerk projects use
`req.user.id` — which is always `undefined`.

**Affected:** Found 6 occurrences across 4 files:
- SOS controller
- Levy/payment controller
- QR page backend
- Resident profile lookup

**Symptoms:**
- `POST /v1/sos/trigger` — `req.user.id` → `undefined` → SOS fails silently
- `GET /v1/payments/my-levies` — `req.user.id` → `undefined` → levy page blank
- `GET /v1/residents/me/qr` — `req.user.id` → `undefined` → QR page broken

**Fix pattern:**
```typescript
// BEFORE — never works with Clerk JWTs
const userId = req.user.id;

// AFTER — Clerk puts the user identifier in `sub`
const userId = req.user.sub;
```

**Detection:**
```bash
grep -rn "req\.user\.id[^e]" backend/src/ | grep -v ".spec.ts"
```
Zero results should remain. The `[^e]` avoids matching `req.user.identityTier`.

---

## Bug Class 2: `req.communityId` vs `req.user?.community_id`

**Root cause:** `JwtAuthGuard` sets `request.user.community_id` in snake_case
(from DB column name). The `@CommunityId()` decorator reads
`request.user?.community_id`. Controllers that read `req.communityId` or
`req.user?.communityId` get `undefined`.

**Affected:** Found in:
- Levy-bill controller (100% of estates — levy creation broken)
- Maintenance controller (8 occurrences)
- Guard-shift controller (3 occurrences)

**Fix:**
```typescript
// BEFORE — always undefined
const communityId = req.user?.communityId;

// AFTER — JwtAuthGuard uses snake_case
const communityId = req.user?.community_id;
```

**Or use the decorator:**
```typescript
@CommunityId() communityId: string,
```

**Detection:**
```bash
grep -rn "req\.user\?\.communityId\b" backend/src/
```

---

## Prevention

When adding a new controller method that reads from `req.user`:
1. Confirm the field name matches what `JwtAuthGuard` sets
2. `req.user.sub` — always correct for Clerk user ID
3. `req.user.community_id` — always correct for community (snake_case)
4. Never `req.user.id` or `req.communityId`
