# Prisma Indirect Relation Joins — The `communityId` Trap

## The Problem

When a Prisma model has a compound/indirect relationship (e.g., `Resident` has `compoundId` → `Compound` has `communityId`), there is NO direct `resident.communityId` field. Accessing `resident.communityId` produces a TypeScript error at build time.

## The Solution

Always `include` the intermediate relation with a `select` for the needed field:

```typescript
// ❌ WRONG — Resident has no direct communityId
const resident = await this.prisma.resident.findUnique({ where: { id } });
this.notificationService.send({
  communityId: resident.communityId, // TS2339 error at build time
});

// ✅ RIGHT — include the compound join
const resident = await this.prisma.resident.findUnique({
  where: { id },
  include: { compound: { select: { communityId: true } } },
});
this.notificationService.send({
  communityId: resident.compound.communityId, // works
});
```

## Audit Checklist

When working with Prisma models that link through intermediate relations:
1. Check the schema: does the model have the field directly, or only via a relation?
2. If indirect, add `include: { intermediate: { select: { field: true } } }` to every `findUnique`/`findFirst` that needs it.
3. Verify with `npx tsc --noEmit` — Prisma client types will catch the mismatch at build time (NOT runtime).

## Common Patterns on This Project

| Model | Needs | Via | Select |
|-------|-------|-----|--------|
| Resident | `communityId` | `compound` | `{ compound: { select: { communityId: true } } }` |
| SOSAlert | `resident.phone` | `resident` | `{ resident: { select: { fullName: true, phone: true } } }` |
| LevyBill | `resident.fullName` | `resident` | `{ resident: { select: { fullName: true } } }` |
