# Clerk v6 Frontend Integration — Next.js App Router

Clerk v6 (installed as `@clerk/nextjs`) has API differences from v5. Key changes: `clerkMiddleware` replaces `authMiddleware`, and route protection uses a handler-based pattern.

## Installation

```bash
npm install @clerk/nextjs
```

## Step 1 — Wrap RootLayout with ClerkProvider

`src/app/layout.tsx`:

```tsx
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

## Step 2 — Middleware with clerkMiddleware

Clerk v6 uses `clerkMiddleware` from `@clerk/nextjs/server` (NOT `authMiddleware` from `@clerk/nextjs`).

The API is handler-based — the options object does NOT have a `publicRoutes` property like v5 did.

`src/middleware.ts`:

```ts
import { clerkMiddleware } from '@clerk/nextjs/server';

const publicRoutes = [
  '/',
  '/sign-in',
  '/sign-up',
  '/api/webhooks',
  '/institution-portal',
];

export default clerkMiddleware((auth, req) => {
  const pathname = req.nextUrl.pathname;

  const isPublic = publicRoutes.some((route) =>
    pathname === route || pathname.startsWith(route + '/'),
  );

  if (!isPublic) {
    auth.protect();  // NOT auth().protect() — protect is on the auth function itself
  }
});

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

### Key differences from v5

| v5 (`authMiddleware`) | v6 (`clerkMiddleware`) |
|---|---|
| `import { authMiddleware } from '@clerk/nextjs'` | `import { clerkMiddleware } from '@clerk/nextjs/server'` |
| Options object with `publicRoutes: [...]` | Handler callback; check paths yourself |
| Routes NOT in `publicRoutes` are auto-protected | Nothing is auto-protected; call `auth.protect()` explicitly |

## Step 3 — Client-side token sync (for custom API clients)

If you have a custom API client (`api.ts`) that stores a token in a module-level variable, create a client-side provider that syncs the Clerk session token to it.

`src/components/AuthProvider.tsx`:

```tsx
'use client';

import { useAuth } from '@clerk/nextjs';
import { useEffect } from 'react';
import { setAuthToken, clearAuthToken } from '@/lib/api';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { getToken } = useAuth();

  useEffect(() => {
    getToken({ template: 'streetwise' }).then((token) => {
      if (token) {
        setAuthToken(token);
      } else {
        clearAuthToken();
      }
    });
  }, [getToken]);

  return <>{children}</>;
}
```

### JWT template parameter

`getToken({ template: 'streetwise' })` references a JWT template created in the Clerk Dashboard. The template defines which custom claims (`roles`, `community_id`, etc.) are embedded in every token the backend validates.

**Clerk Dashboard:** Go to JWT Templates → New Template → set name `streetwise` → add claims like `{{user.public_metadata.roles}}` and `{{user.public_metadata.community_id}}`.

This is required for the backend guard to receive `community_id` and `roles` in the token payload.

## Step 4 — API client with token plumbing

Keep a simple `setAuthToken`/`clearAuthToken` pattern in your API client:

```ts
let _authToken: string | null = null;

export function setAuthToken(token: string) {
  _authToken = token;
}

export function clearAuthToken() {
  _authToken = null;
}

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (_authToken) {
    headers['Authorization'] = `Bearer ${_authToken}`;
  }

  const res = await fetch(`${BASE_URL}${endpoint}`, { ...options, headers });

  if (!res.ok) {
    const error = await res.text();
    throw new Error(`API error ${res.status}: ${error}`);
  }

  return res.json();
}
```

## 🔴 Critical: Server vs Client Component Rules

Mixing these throws **runtime errors**. Apply strictly:

| Component type | Import | Usage pattern |
|---|---|---|
| **Server component** (no `'use client'`, plain async function) | `auth` from `@clerk/nextjs/server` | Call `auth()` at the top of async page components. `getToken({ template: 'streetwise' })` is async — `await` it before fetching data. |
| **Client component** (`'use client'` at top) | `useAuth` from `@clerk/nextjs` | Call `useAuth().getToken({ template: 'streetwise' })` inside a `useEffect`. |
| **Middleware** (always server) | `clerkMiddleware` from `@clerk/nextjs/server` | Use the handler pattern — `auth.protect()` (NOT `auth().protect()`) on the auth function itself. |

### Pitfalls

- **Do NOT import `auth` or `clerkMiddleware` from server into a `'use client'` component** — it will throw at runtime
- **Do NOT import `useAuth` into a server component** — hooks are client-only
- **`getToken()` is async** — you must `await` it or `.then()` it. Forgetting this gives you a Promise object instead of a token string
- **`auth.protect()` vs `auth().protect()`**: In middleware handlers, `protect()` is on the `auth` function itself (first arg to the handler callback), NOT on the return value of calling `auth()`

### Real-world implementation pattern

The cleanest approach for a mixed server/client app:

1. **Root layout** (server) wraps `<ClerkProvider>`
2. **Each admin/resident layout** (client) wraps an `<AuthProvider>` that syncs `getToken()` to the API client's module-level token
3. **Individual pages** (client) call API functions from `@/lib/api` — they don't import Clerk at all
4. **Individual pages** (server) call `auth().getToken()` at the top and pass the token down

## Import paths — what comes from where

| Import | Source | Use |
|--------|--------|-----|
| `ClerkProvider` | `@clerk/nextjs` | Root layout wrapper |
| `useAuth` | `@clerk/nextjs` | Client components (getToken, userId) |
| `clerkMiddleware` | `@clerk/nextjs/server` | Middleware file |
| `auth` | `@clerk/nextjs/server` | Server components / Route Handlers |

## Environment variables

Required on the deployment (Railway, Vercel, etc.):

- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` — from Clerk Dashboard > API Keys
- `CLERK_SECRET_KEY` — from Clerk Dashboard > API Keys
