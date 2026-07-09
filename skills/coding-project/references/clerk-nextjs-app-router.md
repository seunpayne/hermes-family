# Clerk Next.js App Router Integration

## Core Rules (Seun, Streetwise project)

### Server Components (no `'use client'`)
```ts
import { auth } from '@clerk/nextjs/server';

// In an async Server Component page:
export default async function Page() {
  const { getToken } = auth();
  const token = await getToken({ template: 'streetwise' });
  // ...fetch data with token
}
```

### Client Components (`'use client'`)
```ts
import { useAuth } from '@clerk/nextjs';

function MyComponent() {
  const { getToken } = useAuth();

  useEffect(() => {
    getToken({ template: 'streetwise' }).then(token => {
      // ...set token or make API call
    });
  }, [getToken]);
}
```

### Critical Distinction
| Context | Import | Hook/Function | When |
|---------|--------|---------------|------|
| Server component | `@clerk/nextjs/server` | `auth()` async call | Top-level in async page/layout |
| Client component | `@clerk/nextjs` | `useAuth()` hook | Inside `useEffect`, never at render |
| Middleware | `@clerk/nextjs/server` | `clerkMiddleware()` | Route-level protection |

Mixing these will throw runtime errors:
- `auth()` from server in client component → import error (server module not available in browser bundle)
- `useAuth()` in server component → React hooks error (hooks only valid in client components)

### Client Token Sync Pattern (Production)

For the `api.ts` pattern (module functions, not React hooks) — the production-ready version includes three critical improvements over the basic pattern:

1. **Ready state** — blocks rendering children until the token is obtained, preventing race conditions where API calls fire before the auth token is set
2. **50-second refresh interval** — Clerk session tokens expire after 60 seconds. Refreshing at 50s prevents stale token errors on long-running admin sessions
3. **`isLoaded`/`isSignedIn` guards** — Clerk's `useAuth()` returns empty values before initialization completes; checking these prevents `getToken()` from being called before Clerk is ready

```tsx
'use client';
import { useAuth } from '@clerk/nextjs';
import { useEffect } from 'react';
import { setAuthToken, clearAuthToken } from '@/lib/api';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { isLoaded, isSignedIn, getToken } = useAuth();

  useEffect(() => {
    if (!isLoaded || !isSignedIn) {
      clearAuthToken();
      return;
    }

    const fetchToken = async () => {
      try {
        const token = await getToken({ template: 'streetwise' });
        if (token) {
          setAuthToken(token);
        } else {
          clearAuthToken();
        }
      } catch (err) {
        console.error('[AuthProvider] getToken failed:', err);
        clearAuthToken();
      }
    };

    fetchToken();

    // Refresh every 50 seconds — before Clerk's 60-second token expiry
    const interval = setInterval(fetchToken, 50000);

    return () => clearInterval(interval);
  }, [isLoaded, isSignedIn, getToken]);

  return <>{children}</>;
}
```

2. Wrap the layout with `<AuthProvider>` (inside `<ClerkProvider>`):
```tsx
// Root layout (server)
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>{children}</html>
    </ClerkProvider>
  );
}

// Admin layout (client)
'use client';
import { AuthProvider } from '@/components/AuthProvider';

export default function AdminLayout({ children }) {
  return <AuthProvider><div>{children}</div></AuthProvider>;
}
```

3. API client functions use the stored token:
```ts
let _authToken: string | null = null;

export function setAuthToken(token: string) { _authToken = token; }
export function clearAuthToken() { _authToken = null; }

async function request<T>(endpoint: string, options = {}): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (_authToken) headers['Authorization'] = `Bearer ${_authToken}`;
  const res = await fetch(`${BASE_URL}${endpoint}`, { ...options, headers });
  if (!res.ok) throw new Error(`API error ${res.status}: ${await res.text()}`);
  return res.json();
}
```

## Middleware

In Clerk 6.x, `authMiddleware` was replaced by `clerkMiddleware`:
```ts
import { clerkMiddleware } from '@clerk/nextjs/server';

const publicRoutes = ['/', '/sign-in', '/sign-up', '/api/webhooks'];

export default clerkMiddleware((auth, req) => {
  const pathname = req.nextUrl.pathname;
  const isPublic = publicRoutes.some(route =>
    pathname === route || pathname.startsWith(route + '/')
  );
  if (!isPublic) auth.protect();
});
```

### Role-Based Redirect (Advanced Middleware)

For multi-role apps (resident, admin, security), use `createRouteMatcher` + role-based redirect:

```ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

const isPublicRoute = createRouteMatcher([
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/api/webhooks(.*)',
  '/guard(.*)',           // Guard dashboard is public — low-tech users, read-only ops
]);

export default clerkMiddleware(async (auth, req) => {
  if (isPublicRoute(req)) return;

  const { userId, sessionClaims } = await auth();
  if (!userId) return NextResponse.redirect(new URL('/sign-in', req.url));

  // Role routing from root
  if (req.nextUrl.pathname === '/') {
    const roles = (sessionClaims as any)?.roles ?? [];

    if (roles.includes('estate_admin') || roles.includes('secretariat') || roles.includes('super_admin'))
      return NextResponse.redirect(new URL('/admin', req.url));
    if (roles.includes('resident'))
      return NextResponse.redirect(new URL('/resident', req.url));
    if (roles.includes('security'))
      return NextResponse.redirect(new URL('/guard', req.url));
    if (roles.includes('institution_admin'))
      return NextResponse.redirect(new URL('/sign-in', req.url));
    return NextResponse.redirect(new URL('/admin', req.url)); // fallback
  }
});
```

### Guard Dashboard as Public Route — Design Rationale

Making `/guard` a public route is intentional:
1. **Low-tech users:** Security personnel are not Clerk account holders. Adding auth at the gate creates abandonment risk.
2. **Read-only operations:** QR code verification is a read from the offline cache — no destructive action.
3. **Backend enforcement:** All write operations (incident logging, SOS acknowledge) are protected by JwtAuthGuard + RolesGuard on the API side.
4. **Offline-first:** The guard dashboard must function without network — adding auth dependency undermines that.

**Production consideration:** Obfuscate the guard URL with a community-specific token (e.g. `/guard/<community_token>`) to prevent unauthorised URL access to the scan interface. Not a blocker for staging.

### Root Page Auth Routing

The root page (`/`) acts as the central routing hub:

```tsx
// frontend/src/app/page.tsx  (server component)
import { redirect } from 'next/navigation';
import { auth } from '@clerk/nextjs/server';

export default async function RootPage() {
  const { userId } = await auth();
  if (!userId) redirect('/sign-in');
  // Authenticated — middleware handles role-based redirect
  redirect('/admin'); // safe fallback
}
```

This creates a two-layer routing system:
1. **Middleware** (edge) — checks auth + role, redirects from `/` to the correct surface
2. **Root page** (server component) — fallback if middleware doesn't fire on `/`

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

## JWT Template

When creating a Clerk JWT template for the backend:
- Name should match the template parameter: `template: 'streetwise'`
- Template embeds `community_id` and `roles` in the JWT payload
- Backend verifies RS256 signature via Clerk's JWKS endpoint
- See backend `jwt-auth.guard.ts` with `jwks-rsa` for verification

**CRITICAL — Template must be created in the Clerk dashboard:**
If `getToken({ template: 'streetwise' })` returns null or the backend returns 401s:
1. **Create the template:** Clerk Dashboard → JWT Templates → New template
2. Name it exactly `streetwise` (case-sensitive)
3. Add custom claims:
   ```json
   { "roles": ["{{user.public_metadata.roles}}"],
     "community_id": "{{user.public_metadata.community_id}}" }
   ```
4. Save — the template becomes available immediately
5. Without this template, `getToken({ template: 'streetwise' })` returns null,
   the API client sends no auth header, and the backend rejects with 401.

## Key URLs
- Clerk Dashboard: https://dashboard.clerk.com
- JWT Templates: Clerk Dashboard → JWT Templates → New template
- JWKS endpoint: `{CLERK_JWT_ISSUER}/.well-known/jwks.json`

## Version-Specific Gotchas (Clerk 6.x)

### Middleware: `clerkMiddleware` vs `authMiddleware`

Clerk 6.x removed `authMiddleware` in favour of `clerkMiddleware`. The APIs are different:

| Aspect | Clerk 5 (`authMiddleware`) | Clerk 6 (`clerkMiddleware`) |
|--------|---------------------------|---------------------------|
| Import | `@clerk/nextjs` | `@clerk/nextjs/server` |
| Public routes | `publicRoutes` option in options object | Handler function checks path + calls `auth.protect()` |
| Return | Next middleware | Next middleware |

**Does NOT work (Clerk 6):**
```ts
export default clerkMiddleware({
  publicRoutes: ['/', '/sign-in'], // ❌ ClerkMiddlewareOptions has no publicRoutes
});
```

**Works (Clerk 6):**
```ts
export default clerkMiddleware((auth, req) => {
  const publicRoutes = ['/', '/sign-in'];
  const isPublic = publicRoutes.some(r => req.nextUrl.pathname === r);
  if (!isPublic) auth.protect();
});
```

### `auth.protect()` — called on the function, not its return value

```ts
// ✅ Correct — protect is a method on the auth function itself
auth.protect();

// ❌ Wrong — this tries to call .protect() on a Promise
auth().protect();
```

The type is `AuthFn = GetAuthFnNoRequest<SessionAuthWithRedirect, true> & { protect: AuthProtect }`.
`auth` is a callable function (that returns a Promise) AND has a `protect` property directly.

### Backend Route Ordering: `@Get('me')` before `@Get(':id')`

When adding a new endpoint like `GET /v1/residents/me` to a NestJS controller that already has `GET /v1/residents/:id`:

```ts
// ❌ Wrong — NestJS will try to match "me" as an id parameter
@Get(':id')
async findOne(@Param('id') id: string) { ... }

@Get('me')  // Never reached — "me" matched by :id above
async getMe() { ... }

// ✅ Correct — 'me' route declared before ':id'
@Get('me')
async getMe() { ... }

@Get(':id')
async findOne(@Param('id') id: string) { ... }
```

NestJS registers routes in declaration order and matches the first handler. Since `:id` is a wildcard, it will match `me` as a literal id value if declared first. Always put literal route segments (`me`, `mine`, `active`) before dynamic params (`:id`, `:slug`).
