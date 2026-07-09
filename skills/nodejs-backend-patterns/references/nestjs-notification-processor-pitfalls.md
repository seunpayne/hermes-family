# NestJS Notification Processor Pitfalls

## The Silent `require()` Failure

When a NestJS module uses `require()` to dynamically load a TypeScript file at runtime, **the file is never compiled to `dist/`**. TSC only compiles files that are statically imported by another module. An orphan file loaded via `require()` is invisible to the compiler.

### The Bug

```typescript
// notification.processor.ts
private resolveBody(type: NotificationType, metadata: Record<string, unknown>): string {
  // ❌ BROKEN — this file is never compiled to dist/
  const copy = require('../../common/i18n/notification.en').default;
  return copy.broadcast({ title, message, senderName });
}
```

**Three reasons this fails:**

1. `notification.en.ts` has no static import anywhere → not compiled to `dist/`
2. Even if compiled, it uses `export const notificationCopy = ...` (named) not `export default`
3. `.default` on a named-export module returns `undefined`

**Result:** `copy` is `undefined`, `copy.broadcast(...)` throws `TypeError: Cannot read properties of undefined (reading 'broadcast')`. Every notification job silently fails 3 retries and dies permanently.

**Detection:** Look for BullMQ jobs that fail with `Cannot read properties of undefined (reading 'X')` where `X` is a template function name.

### The Fix

Use **inline template strings** in the processor itself, or import statically:

```typescript
// ✅ Inline templates — no dynamic imports
case NotificationType.SOS_DISPATCH: {
  const name = String(metadata.name || 'Unknown');
  const compound = String(metadata.compound || 'Unknown');
  const location = metadata.location ? `📍 ${String(metadata.location)}` : '';
  return `🚨 *SOS ALERT* from ${name} at ${compound}${location}\n\nRespond immediately.`;
}
```

Alternatively, if you MUST have a separate copy file, import it statically:

```typescript
// ✅ Static import ensures compilation
import { notificationCopy } from '../../common/i18n/notification.en';

// Then use named exports directly (no .default)
```

### When to Suspect This Bug

- Any BullMQ/Redis/Bull job that fails silently on ALL notification types
- Error: `Cannot read properties of undefined (reading '<templateName>')`
- File exists in `src/` but is missing from `dist/`
- The file is only loaded via `require()` or dynamic `import()`, never statically

### Prevention Checklist

Before deploying notification processors:
1. Run `npm run build` and check that all referenced files exist under `dist/`
2. Verify `dist/` has `.js` counterparts for every `.ts` template file
3. Unit test with a known-good notification type — if ALL types fail, suspect missing dist files
