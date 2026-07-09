# Dynamic `require()` for TypeScript Files — Always Undefined

## The failure

```typescript
// notification.processor.ts — resolveBody()
const copy = require('../../common/i18n/notification.en').default;
// copy is ALWAYS undefined on Railway
```

This fails for TWO independent reasons:

1. **No default export** — The file uses `export const namedVar = { ... }` but `require().default` is `undefined` (no `export default` exists).

2. **File never compiled** — `tsc` only compiles files that are IMPORTED (static `import`). A `require()` is a dynamic import — TSC doesn't track it, so the file is never compiled to `dist/`. At runtime, `require()` resolves to nothing.

## Why it's silent

No crash at module resolution time. The `require()` call returns `{}` (or `undefined`), then every switch-case that accesses `copy.something()` fails with `Cannot read properties of undefined` — but only when a notification job is PROCESSED, not when the module is loaded. The queue accepts jobs fine, they all fail in the processor.

## Detection

```
[Nest] ERROR [NotificationProcessor] Notification job 5 failed after 0 attempt(s):
Cannot read properties of undefined (reading 'broadcast')
```

The signal: every notification TYPE fails with the same error pattern, regardless of channel.

## Fix patterns

### Option A — Inline templates (best for small data)
```typescript
private resolveBody(type: NotificationType, metadata: Record<string, unknown>): string {
  switch (type) {
    case NotificationType.BROADCAST:
      return `📢 Announcement from ${metadata.senderName || 'Estate Office'}\n\n${metadata.message}`;
    // ...
  }
}
```
No import needed. No runtime dependency. Works everywhere. Good for notification templates, error messages, and static copy.

### Option B — Static import + default export (if the file must be shared)
```typescript
// notification.en.ts
export default { broadcast: (msg: string) => `📢 ${msg}` };

// consumer
import copy from '../../common/i18n/notification.en';  // ← static import
```

The static `import` guarantees TSC compiles the file to `dist/`. The `default` export matches the consumer's `copy.function()` access pattern.

### Option C — Named export + static import
```typescript
// notification.en.ts
export const notificationCopy = { broadcast: (msg: string) => `📢 ${msg}` };

// consumer
import { notificationCopy } from '../../common/i18n/notification.en';
const message = notificationCopy.broadcast(metadata.message);
```

## The pre-flight check

Before pushing any file that uses `require()`:
```bash
# Does the required file have a default export?
grep "export default" path/to/file.ts

# Will it be compiled? (static import check)
grep -r "import.*from.*notification.en" src/ --include="*.ts"
```
If no static import exists AND it's loaded via `require()`, it will NOT be in `dist/` on Railway.
