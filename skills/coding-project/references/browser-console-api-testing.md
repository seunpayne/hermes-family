# Browser Console API Testing Pattern

## When to use
When the backend is deployed on Railway, the frontend is on staging, and you don't have terminal access to the backend. The browser console lets you test endpoints with a real Clerk JWT token.

## Pattern

```javascript
// 1. Get a fresh Clerk JWT
const token = await window.Clerk?.session?.getToken({ template: 'streetwise' });

// 2. Test an endpoint
const res = await fetch('https://backend-production-xxxx.up.railway.app/v1/auth/context', {
  headers: { Authorization: `Bearer ${token}` }
});
console.log(await res.json());

// 3. For verbose 401 errors (when JwtAuthGuard has debug messages):
const res = await fetch('https://backend.../v1/auth/context', {
  headers: { Authorization: `Bearer ${token}` }
});
console.log('Status:', res.status);
console.log('Body:', await res.text());
```

## Common test endpoints

| Endpoint | What it tests |
|----------|--------------|
| `GET /v1/auth/context` | Roles + community resolution (no RolesGuard) |
| `GET /v1/community/announcements` | JWT verification (JwtAuthGuard only) |
| `GET /v1/demo/slots` | Public endpoint (no auth — should return 200) |
| `POST /v1/demo/request` | Demo flow end-to-end |

## Diagnostic sequence for 401 issues

1. `GET /v1/demo/slots` (no token) → 200? Backend is up ✅. 401? Server not running or wrong URL.
2. `GET /v1/auth/context` (no token) → 401 with "No token provided"? Guard is running ✅. Different error? Check JwtAuthGuard code.
3. `GET /v1/auth/context` (with token) → 200 with roles? Auth works ✅. 401? JWT verification is failing.
4. Read the error message body — if verbose logging is enabled in JwtAuthGuard, it tells you the exact reason (expired token, issuer mismatch, JWKS unavailable).

## Pitfalls
- `window.Clerk?.session` may be null if not signed in — check first
- Tokens expire after ~60s — get a fresh one for each test batch
- CORS may block preflight on OPTIONS requests — the endpoint must handle CORS
- Railway deployments take 2-5 minutes to roll out — wait after pushing before testing
- **`browser_console(expression=...)` does NOT work with async fetch** — the expression evaluates synchronously. `fetch().then(console.log)` returns immediately, the Promise resolves after the tool returns `null`. Use the browser's actual DevTools console (F12) or run the fetch via `browser_navigate` + `browser_snapshot` to see results on the page.
- **Use `curl` from terminal when possible** — for backend health checks without tokens, `curl -s -o /dev/null -w "%{http_code}" URL` is faster and more reliable than browser console.
