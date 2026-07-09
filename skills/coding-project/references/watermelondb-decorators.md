# WatermelonDB TypeScript Decorator Configuration

## Problem

WatermelonDB models use TypeScript decorators for property definitions:

```typescript
import { field, readonly, date } from '@nozbe/watermelondb/decorators';

export default class Product extends Model {
  @field('sku') sku!: string;
  @readonly @date('created_at') createdAt!: Date;
}
```

Without proper TypeScript configuration, you will see errors:

```
Unable to resolve signature of property decorator when called as an expression.
Argument of type 'undefined' is not assignable to parameter of type 'Object'. [1240]
```

## Solution

**tsconfig.json** must include:

```json
{
  "compilerOptions": {
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "strict": true,
    "target": "ES2020",
    "module": "commonjs"
  }
}
```

## Expo v54+ Specific

Expo's default TypeScript template may not include decorator support.

**Check your config:**
```bash
cat tsconfig.json | grep -E "experimentalDecorators|emitDecoratorMetadata"
```

**If missing, add to `compilerOptions`:**
```json
"experimentalDecorators": true,
"emitDecoratorMetadata": true
```

**Then restart TypeScript:**
```bash
# In Expo project
npx expo start --clear

# Or restart TS server in your editor
```

## Verification

After configuring, models should compile without decorator errors:

```bash
# No errors = success
npx tsc --noEmit

# If errors persist, check:
# 1. tsconfig.json is at project root
# 2. No conflicting tsconfig in subdirectories
# 3. Editor TypeScript server restarted
```

## Common Pitfalls

### Pitfall 1: Multiple tsconfig files
Expo projects may have `tsconfig.json` and `app.json` with TypeScript config.
Ensure both are aligned or use the root `tsconfig.json`.

### Pitfall 2: Decorator order
Multiple decorators on same property must be in correct order:

```typescript
// ✓ Correct
@readonly @date('created_at') createdAt!: Date;

// ✗ May cause issues
@date('created_at') @readonly createdAt!: Date;
```

### Pitfall 3: Import path
Always import from `@nozbe/watermelondb/decorators`, not `@nozbe/watermelondb`:

```typescript
// ✓ Correct
import { field } from '@nozbe/watermelondb/decorators';

// ✗ Will not work
import { field } from '@nozbe/watermelondb';
```

## Session Example: Sani General Stores

Created WatermelonDB models with decorators:
- `Product.ts`: `@field`, `@readonly`, `@date`
- `Transaction.ts`: `@field`, `@readonly`, `@date`, `@associations`
- `SyncEvent.ts`: `@field`, `@readonly`, `@date`
- `RegisteredDevice.ts`: `@field`, `@readonly`, `@date`

Initial errors:
```
Unable to resolve signature of property decorator...
```

Fixed by adding to `tsconfig.json`:
```json
"experimentalDecorators": true,
"emitDecoratorMetadata": true
```

Models then compiled successfully.

## Related

- WatermelonDB docs: https://nozbe.github.io/WatermelonDB/
- TypeScript decorators: https://www.typescriptlang.org/docs/handbook/decorators.html
- Expo TypeScript: https://docs.expo.dev/guides/typescript/
