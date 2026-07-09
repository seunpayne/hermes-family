# Dual Resolution Drift — Auth Guard vs Service

## Problem

When both `JwtAuthGuard.resolveAuthContext()` and `AuthContextService.resolve()` implement the same role resolution logic, they drift.

## Root Cause

Sub-agent fixes the service's priority order (UserRole first, ownerClerkId fallback) but leaves the guard with the old order (ownerClerkId first, UserRole second).

## Why It's Critical

`JwtAuthGuard.resolveAuthContext()` sets `request.user.roles` for **every API call**. The service's `GET /v1/auth/context` is only called once on mount. The guard always returned `['estate_admin']` from ownerClerkId — the UserRole table was never consulted.

## Detection

```bash
grep -rn "resolveAuthContext\|findByUserId\|ownerClerkId" backend/src --include="*.ts"
```

Both files must have identical priority ordering.

## Instance (Streetwise, June 2026)

- `auth-context.service.ts`: Priority 1=UserRole, Priority 2=ownerClerkId (FIXED)
- `jwt-auth.guard.ts`: Priority 1=ownerClerkId, Priority 2=UserRole (STALE — never updated)
- Result: `request.user.roles` always `['estate_admin']` regardless of UserRole table

## Fix

Update BOTH files simultaneously. Verify with grep that priority order matches.

## Verification (post-fix)

After fixing both files, verify the resolution path works end-to-end:

1. Set a user's roles in UserRole table (e.g. `['super_admin']`)
2. Call `GET /v1/auth/context` — should return the DB roles, NOT `['estate_admin']`
3. If it still returns `estate_admin`, the guard's resolveAuthContext hasn't been fixed