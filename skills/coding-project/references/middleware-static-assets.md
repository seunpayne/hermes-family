# Middleware Blocks Static Assets

## Problem

When using `clerkMiddleware` with `createRouteMatcher` for `isPublicRoute`, any route NOT in the public matcher is intercepted. This includes static files served from `public/`:

```
Browser: GET /images/streetwise.png
Middleware: Route not in isPublicRoute → redirect to /sign-in
Result: All <img src="/images/..."> tags show broken images
```

This also affects:
- `/images/icons/*.png`
- `/images/screenshot-*.png`
- `/images/hero-illustration.png`
- `/landing` (if it's a separate route)
- `/sandbox` (demo flow)

## Diagnosis

- Images appear broken on the landing page
- Opening an image URL in the browser redirects to `/sign-in`
- Browser console shows no explicit error — images just fail silently
- DevTools Network tab shows 302 redirect to `/sign-in`

## Fix

Add static asset paths to the `isPublicRoute` matcher:

```typescript
const isPublicRoute = createRouteMatcher([
  '/',
  '/images(.*)',       // ← Static images
  '/landing',           // ← Marketing page
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/privacy',
  '/terms',
  '/institution-portal(.*)',
  '/guard(.*)',
  '/sandbox(.*)',
]);
```

## Why this happens

Clerk's `clerkMiddleware` wraps all routes. Static files in `public/` are served by Next.js's built-in file server, but the middleware runs BEFORE the static file handler. If the path isn't in `isPublicRoute`, the middleware redirects to the sign-in URL before Next.js can serve the file.

This is a Next.js + Clerk integration issue, not a configuration error. The fix is always to include static asset paths in the public route matcher.
