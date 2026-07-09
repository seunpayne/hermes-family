# NestJS Module Circular Dependencies

## The "All Three Sides" Rule

When breaking a circular dependency between NestJS modules with `forwardRef()`, **all edges of the circle must use `forwardRef`**, not just one.

### The Failure Case

Circle: `WhatsAppModule → ResidentsModule → NotificationModule → WhatsAppModule`

❌ **Wrong** (only one edge uses forwardRef):
```
WhatsAppModule:  imports: [ResidentsModule]           // direct — crashes
ResidentsModule: imports: [NotificationModule]        // direct — at risk
NotificationModule: imports: [forwardRef(() => WhatsAppModule)]
```
Result: `UndefinedModuleException` at startup — WhatsAppModule's import of ResidentsModule is `undefined` because ResidentsModule is still mid-load.

✅ **Correct** (all three edges):
```
WhatsAppModule:  imports: [forwardRef(() => ResidentsModule)]
ResidentsModule: imports: [forwardRef(() => NotificationModule)]
NotificationModule: imports: [forwardRef(() => WhatsAppModule)]
```

### Detection

The error looks like:
```
UndefinedModuleException [Error]: Nest cannot create the WhatsAppModule instance.
The module at index [1] of the WhatsAppModule "imports" array is undefined.
Scope [AppModule -> ResidentsModule -> NotificationModule]
```
The "Scope" line traces the resolution chain. The first module in the chain is the one crashing.

## Prisma Schema: Shared Fields via Relations

In Prisma/NestJS, `Resident` has `compoundId` (FK to Compound), and Compound has `communityId` (FK to Community). **Resident does NOT have a direct `communityId` field.**

❌ Wrong: `resident.communityId` — TypeScript error, field doesn't exist
✅ Right: Include the relation in the query:
```typescript
const resident = await this.prisma.resident.findUnique({
  where: { id },
  include: { compound: { select: { communityId: true } } },
});
// Use: resident.compound.communityId
```

This pattern applies to any deeply nested relation access in Prisma.

## Feature Audit Checklist

Before declaring a NestJS feature complete:

1. **State machine**: Map all states and transitions. Check guards on every transition.
2. **Notification paths**: Both directions — who gets notified when? (e.g., resident→admin on submit, admin→resident on approve/reject)
3. **Re-submit guards**: Can a user re-submit after rejection? After approval? Are those intentional?
4. **Module dependency graph**: Any new `imports` added? Check for circular dependency potential.
5. **Prisma relations**: Any `include` needed for fields accessed via relations (not direct columns)?
6. **Dynamic require() calls**: Any `require()` loading TypeScript files at runtime? These won't compile to `dist/` — see `references/nestjs-notification-processor-pitfalls.md`. Replace with static imports or inline templates.
