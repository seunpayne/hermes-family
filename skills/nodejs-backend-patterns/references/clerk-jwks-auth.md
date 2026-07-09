# Clerk JWKS JWT Verification in NestJS

Verifying Clerk-issued JWTs on a NestJS backend, replacing a custom HMAC guard with Clerk's RS256 JWKS.

## Dependency

```bash
npm install jwks-rsa
```

Already has `jsonwebtoken` as a dependency. `@nestjs/jwt` / `@nestjs/passport` are NOT required — this pattern uses a plain `CanActivate` guard.

## Import quirk

`jwks-rsa` uses `export =` (CommonJS-style module export). With `esModuleInterop: true` in tsconfig:

```ts
import JwksRsa from 'jwks-rsa';
// NOT: import * as JwksRsa from 'jwks-rsa';
// NOT: import { JwksClient } from 'jwks-rsa';
```

The module's default export IS the callable factory function. The type namespace is `JwksRsa.JwksClient`, `JwksRsa.Options`, etc.

## Guard structure (three-mode)

| Mode | Trigger | Behaviour |
|------|---------|-----------|
| Public route | `@Public()` decorator | Skip auth entirely |
| Dev bypass | `SKIP_AUTH=*** | Mock user with `super_admin` role |
| Production | Neither of the above | Verify RS256 JWT via Clerk's JWKS |

## Dev bypass

Only `SKIP_AUTH=*** — **not** a dev-looking `JWT_SECRET`. This is stricter than the old pattern of checking if the secret contains 'dev'.

```ts
if (this.skipAuth) {
  request.user = {
    id: 'dev-user-id',
    roles: ['super_admin'],
    community_id: null,
  };
  return true;
}
```

## Production verification

```ts
private readonly client: JwksRsa.JwksClient;

// Constructor
this.client = JwksRsa({
  jwksUri: `${issuer}/.well-known/jwks.json`,
  cache: true,
  cacheMaxEntries: 5,
  cacheMaxAge: 600000, // 10 minutes
  rateLimit: true,
  jwksRequestsPerMinute: 10,
});

// Verification
private verifyClerkToken(token: string): Promise<jwt.JwtPayload> {
  return new Promise((resolve, reject) => {
    const getKey: jwt.GetPublicKeyOrSecret = (header, callback) => {
      this.client!.getSigningKey(header.kid, (err, key) => {
        if (err) return callback(err);
        callback(null, key!.getPublicKey());
      });
    };

    const issuer = this.config.get<string>('CLERK_JWT_ISSUER');

    jwt.verify(token, getKey, {
      algorithms: ['RS256'],
      issuer,
    }, (err, decoded) => {
      if (err) return reject(err);
      resolve(decoded as jwt.JwtPayload);
    });
  });
}
```

### Key points

- `getSigningKey(kid, callback)` — the callback overload is used here because `jwt.GetPublicKeyOrSecret` expects a callback-based function
- `algorithms: ['RS256']` — Clerk signs with RS256, NOT HS256
- `issuer` — must match `CLERK_JWT_ISSUER` env var exactly
- `header.kid` — the key ID in the JWT header tells jwks-rsa which signing key to fetch from Clerk's JWKS endpoint
- JWKS response is cached for 10 minutes with rate limiting (10 req/min)

## Attaching user from decoded payload

```ts
request.user = {
  id: payload.sub,
  roles: (payload as any).roles ?? [],
  community_id: (payload as any).community_id ?? null,
  ...payload,
};
```

Clerk's JWT `sub` claim contains the Clerk user ID. Custom claims (roles, community_id) are in the token's private claims.
