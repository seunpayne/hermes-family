# TypeScript Strict Array Initialization

## The Problem

In TypeScript with `strictNullChecks: true` and `noImplicitAny: false`, empty array literals are inferred as `never[]`:

```typescript
const compounds = [];  // Type: never[]
compounds.push(someObject);  // Error: Argument not assignable to never
```

This happens because TypeScript infers the type from the initial empty literal, which has no elements to infer from.

## The Fix

Always annotate empty arrays with an explicit type when you'll push to them later:

```typescript
const compounds: any[] = [];                    // Quick fix for complex objects
const compounds: Compound[] = [];                // Typed (preferred)
const createdResidents: any[] = [];              // For Prisma create results
const accessLogsData: any[] = [];                // For bulk data arrays
```

## Common Occurrence

This pattern appears frequently in:
- Prisma seed scripts (building arrays of created records)
- Test factories
- Bulk data processing (collecting results then writing)

## Root Cause

`strictNullChecks: true` in tsconfig.json changes array inference from `never[]` — if the file also uses `isolatedModules: true`, the inference is even stricter.
