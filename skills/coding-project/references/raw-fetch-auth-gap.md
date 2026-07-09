# Raw fetch() without Authorization header — ops/admin page pattern

## The bug

Ops and admin pages that use raw `fetch()` to call backend endpoints send NO auth token,
causing 401 "No token provided" even when the user is authenticated:

```tsx
// ❌ BAD — raw fetch without Authorization header
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/v1';
const res = await fetch(`${API_BASE}/ops/leads/${id}/convert`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ plan, startFresh: true }),
});
```

## Fix

Add a centralized API function in `@/lib/api.ts` that uses the `request()` wrapper
(which automatically includes the `Authorization: Bearer <token>` header):

```typescript
// In @/lib/api.ts:
export async function convertOpsLead(id: string, dto: { plan: string; startFresh: boolean }) {
  return request<unknown>(`/ops/leads/${id}/convert`, {
    method: 'POST',
    body: JSON.stringify(dto),
  });
}

// In the page:
import { convertOpsLead } from '@/lib/api';
await convertOpsLead(id, { plan, startFresh: true });
```

## Detection

Any `fetch(...)` or `fetch('https://backend-production-...')` in page code
that doesn't include `Authorization` header. Search:

```bash
grep -rn "fetch(" src/app/ --include="*.tsx" | grep -v "node_modules" | grep -v "api.ts"
```

## Rule

All authenticated API calls MUST go through the centralized `request()` function
in `@/lib/api.ts`. Raw `fetch()` is only acceptable for:
- Public endpoints (demo/slots, community/early-access-slots)
- Third-party APIs (Paystack, Clerk, etc.)
- The initialization code in `api.ts` itself

If a raw `fetch()` needs auth, add the API function to `api.ts` and import it.
