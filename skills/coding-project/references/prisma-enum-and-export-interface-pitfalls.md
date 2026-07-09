# Prisma Enum vs TypeScript Union + NestJS Export Interface Pitfalls

## Pitfall 1: Prisma enum member name mismatch

When a DTO field is typed as `'starter' | 'growth' | 'estate'` but the
Prisma-generated `$Enums` uses different names (e.g. `SubscriptionTier` =
`free | starter | growth | enterprise`), TypeScript rejects the assignment:

```
error TS2322: Type '"starter" | "growth" | "estate"' is not assignable
to type 'SubscriptionTier | undefined'.
  Type '"estate"' is not assignable to type 'SubscriptionTier | undefined'.
```

**Fix:** Map the DTO value to the enum member, or cast:
```typescript
// If DTO uses 'estate' but enum uses 'enterprise'
planTier: dto.plan as SubscriptionTier,

// Or map explicitly
const tierMap: Record<string, SubscriptionTier> = {
  starter: 'starter', growth: 'growth', estate: 'enterprise',
};
planTier: tierMap[dto.plan],
```

## Pitfall 2: Controller return type references private interface

When a controller method's return type references a service interface that
is NOT exported:

```typescript
// service.ts — WRONG
interface Bank { name: string; code: string; }

// controller.ts
async getBanks(): Promise<Bank[]> { ... }
```

NestJS TypeScript compilation fails:
```
error TS4053: Return type of public method ... uses name 'Bank' from
external module but cannot be named.
```

**Fix:** Always `export` interfaces used in controller return types:
```typescript
// service.ts — CORRECT
export interface Bank { name: string; code: string; }
```
