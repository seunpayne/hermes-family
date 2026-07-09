# NestJS Webhook Raw Body

## The Problem

When using NestJS with Paystack (or Stripe, Meta, GitHub) webhooks, `@Body()` receives the parsed JSON body — but HMAC signature verification requires the **raw, unparsed request body** as a buffer.

## The Fix

In `main.ts`, add `rawBody: true` to the NestJS factory options:

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    rawBody: true,  // ← REQUIRED for webhook signature verification
  });
  // ...
}
```

Then in your webhook controller, access the raw body via:

```typescript
@Post('webhook')
@Public()
async handleWebhook(
  @Req() req: Request,
  @Headers('x-paystack-signature') signature: string,
) {
  // req.body is the parsed JSON
  // The raw body is available as a Buffer from NestJS internals
  // Use a custom decorator or access it via the underlying Express request
}
```

## Paystack-Specific

```typescript
import * as crypto from 'crypto';

function verifyPaystackSignature(payload: string, signature: string, secret: string): boolean {
  const expected = crypto
    .createHmac('sha512', secret)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}
```

Without `rawBody: true`, `JSON.stringify(req.body)` will NOT produce the same string as the raw payload because Express parses and reformats the JSON — whitespace and key order differ, breaking the HMAC.
