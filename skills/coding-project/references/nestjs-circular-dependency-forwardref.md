# NestJS Circular Dependency — Module Imports Chain

## The failure

```
UndefinedModuleException: Nest cannot create the WhatsAppModule instance.
The module at index [1] of the WhatsAppModule "imports" array is undefined.

Scope [AppModule -> ResidentsModule -> NotificationModule]
```

This happens when one feature's module import completes a loop:
```
WhatsAppModule → imports ResidentsModule
ResidentsModule → imports NotificationModule  (added for admin KYC notifications)
NotificationModule → imports WhatsAppModule
```

NestJS encounters the circular import during module scanning and one module resolves as `undefined` before the other finishes initialising.

## Root cause

Adding a new module import (like `NotificationModule` to `ResidentsModule` for admin KYC notifications) without checking whether the new import chain creates a loop back to the original module.

## Detection — Pre-flight check

When adding `XModule` to `YModule`'s imports:
```bash
# Check if XModule imports YModule (or anything that imports YModule)
grep "YModule" path/to/XModule/*.ts
grep "XModule" path/to/YModule/*.ts

# Trace the full chain
# WhatsAppModule imports ResidentsModule
# ResidentsModule now imports NotificationModule  ← the new addition
# NotificationModule imports WhatsAppModule       ← the loop back
```

If the chain loops, use `forwardRef`.

## Fix

```typescript
import { Module, forwardRef } from '@nestjs/common';

@Module({
  imports: [
    // ...
    forwardRef(() => WhatsAppModule),  // ← break the cycle
  ],
})
export class NotificationModule {}
```

Apply `forwardRef()` to the import that COMPLETES the cycle — the last link in the chain. In this case, `NotificationModule` importing `WhatsAppModule` was the closing link.

**CRITICAL — one-sided forwardRef is often insufficient:** NestJS may still crash because the error propagates from the OTHER side of the circle. In this case, wrapping ONLY `NotificationModule → forwardRef(WhatsAppModule)` wasn't enough — the crash was `WhatsAppModule → ResidentsModule` at index [1]. The fix requires `forwardRef` on ALL edges that participate in the cycle:

```typescript
// WhatsAppModule — side 1
imports: [PrismaModule, forwardRef(() => ResidentsModule)]

// ResidentsModule — side 2
imports: [PrismaModule, forwardRef(() => NotificationModule)]

// NotificationModule — side 3
imports: [..., forwardRef(() => WhatsAppModule)]
```

The rule: when the chain is bidirectional, wrap every import in the circle. Don't try to fix just the "closing link" — the crash can originate from any point in the chain.

## Pattern: which import to wrap?

Look at the scope trace from the error:
```
Scope [AppModule -> ResidentsModule -> NotificationModule]
```

The trace shows the first three modules. The fourth (`WhatsAppModule`) is the one that loops back. Find which of the three imports it, and wrap THAT import:

1. AppModule imports ResidentsModule → fine (top-down)
2. ResidentsModule imports NotificationModule → fine (down the tree)
3. NotificationModule imports WhatsAppModule → THIS ONE closes the circle
4. WhatsAppModule imports ResidentsModule → back to (1)

Wrap `forwardRef(() => WhatsAppModule)` in NotificationModule — that's the import that closes the loop.
