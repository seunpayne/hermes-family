# Frontend Multi-Tenant Patterns (Clerk + Next.js)

Companion to `nestjs-multi-tenant-patterns.md` (backend side).

## Architecture

In a multi-tenant SaaS, the frontend must do three things to scope every request to the correct tenant:

1. **Authenticate** — get a JWT from the auth provider (Clerk)
2. **Extract tenant ID** — from Clerk user metadata or session claims
3. **Pass tenant ID** — in every API request so the backend can scope queries

## Pattern: Clerk Auth + community_id in JWT

### 1. Root layout wraps ClerkProvider

```tsx
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### 2. Auth token is set on the API client

Clerk's `useAuth().getToken()` returns a signed JWT. This token is then set on the API client's Bearer header:

```tsx
// app/admin/layout.tsx (client component)
'use client';
import { useAuth } from '@clerk/nextjs';
import { setAuthToken } from '@/lib/api';
import { useEffect } from 'react';

export default function AdminLayout({ children }) {
  const { getToken } = useAuth();

  useEffect(() => {
    getToken().then(token => {
      if (token) setAuthToken(token);
    });
  }, [getToken]);

  return <div>{children}</div>;
}
```

### 3. API client sends Bearer token

```ts
// lib/api.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/v1';

let _authToken: string | null = null;

export function setAuthToken(token: string) { _authToken = token; }

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (_authToken) {
    headers['Authorization'] = `Bearer ${_authToken}`;
  }
  const res = await fetch(`${BASE_URL}${endpoint}`, { ...options, headers });
  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(error.message || `API Error: ${res.status}`);
  }
  return res.json();
}
```

### 4. Backend extracts community_id from verified JWT

The backend JWT guard (see `nestjs-multi-tenant-patterns.md`) verifies the token using Clerk's JWKS, then reads `community_id` from the decoded payload to scope all queries.

## How community_id gets into the Clerk JWT

Clerk stores `community_id` in user metadata. During session creation, Clerk optionally includes this metadata as a custom JWT claim. The backend JWT guard then reads `payload.community_id`.

Two approaches:

**A. Clerk JWT Template (recommended)**
Configure a Clerk JWT template that includes `community_id` from `user.public_metadata.community_id` as a custom claim. The template is selected by the frontend when calling `getToken({ template: 'streetwise' })`.

**B. Frontend passes it manually**
The frontend reads `community_id` from Clerk's `useUser().user.publicMetadata.community_id` and includes it as a header or in the request body. Less secure — easier to tamper with.

**Preferred: A.** The backend trusts the JWT claim because it was signed by Clerk.

## Context Provider Pattern (URL-free)

If the tenant (community) is determined from the authenticated user rather than from the URL:

```tsx
// lib/community-context.tsx
'use client';
import { createContext, useContext } from 'react';
import { useUser } from '@clerk/nextjs';

interface CommunityContextValue {
  communityId: string | null;
  communityName: string | null;
}

const CommunityContext = createContext<CommunityContextValue>({
  communityId: null,
  communityName: null,
});

export function CommunityProvider({ children }) {
  const { user } = useUser();
  const communityId = user?.publicMetadata?.community_id as string ?? null;
  const communityName = user?.publicMetadata?.community_name as string ?? null;

  return (
    <CommunityContext.Provider value={{ communityId, communityName }}>
      {children}
    </CommunityContext.Provider>
  );
}

export const useCommunity = () => useContext(CommunityContext);
```

Then wrap relevant layouts:

```tsx
// app/admin/layout.tsx
<ClerkProvider>
  <CommunityProvider>
    <AdminSidebar />
    <main>{children}</main>
  </CommunityProvider>
</ClerkProvider>
```

## URL-based tenant scoping (alternative)

Some apps scope by URL path — `/admin/:communityId/compounds`. In that case:

1. Extract `communityId` from route params: `const { communityId } = useParams()`
2. Pass it in the request: either as a header (`x-community-id`) or query param
3. The backend middleware reads it from the header/param as a fallback

This is useful when a single user manages multiple communities (e.g. a super-admin). The URL tells you which community they're acting on.

## Walk-Back: What Streetwise Frontend Was Missing

During review, the Streetwise frontend had these gaps:

| Required | Status | Impact |
|----------|--------|--------|
| `<ClerkProvider>` in root layout | **Missing** | No Clerk auth at all |
| `useAuth().getToken()` to set Bearer token on API client | **Missing** | All API calls have no auth header |
| Community context provider | **Missing** | No user metadata available in components |
| community_id in API requests | **Missing** | Backend has no tenant context |
| Admin pages calling real API | **Missing** | Hardcoded mock data, not live |

**Result:** The backend had `SKIP_AUTH=*** in production because the frontend never sent a valid token. The auth system was circular — backend needs token, frontend never sends one.

## Implementation Checklist

When building a multi-tenant frontend, verify:

1. [ ] ClerkProvider wraps the app root layout
2. [ ] Layout-level `useEffect` calls `getToken()` and `setAuthToken()`
3. [ ] Clerk JWT template configured to include `community_id` claim
4. [ ] API client sends Bearer header on every non-public request
5. [ ] Community context provider wraps authenticated routes
6. [ ] Pages call real API functions (not mock data)
7. [ ] Backend verifies Clerk JWT via JWKS (see `jwt-auth.guard.ts`)
8. [ ] Backend reads `community_id` from decoded JWT payload
9. [ ] `SKIP_AUTH` removed from production env vars after frontend integration is live

## Pitfalls

- **Clerk JWT templates are on Clerk's dashboard** — not in code. You must configure them at `https://dashboard.clerk.com`.
- **`getToken()` is async** — the token isn't available immediately on page load. Use a loading state.
- **Public routes (signup, health) don't need auth** — the backend `@Public()` decorator skips JWT verification for these.
- **Mock data is fine for early dev** — but swap to real API calls before removing `SKIP_AUTH`.
- **Multiple auth layouts** — resident and admin layouts may need separate token flows or different Clerk templates.
