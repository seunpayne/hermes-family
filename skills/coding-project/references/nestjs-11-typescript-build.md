# NestJS 11 TypeScript Build Fixes

NestJS 11 defaults to `moduleResolution: "nodenext"` which often fails with error TS2688 — "Cannot find type definition file for 'babel__generator'" (and similar transitive @types packages).

## Symptoms

```
error TS2688: Cannot find type definition file for 'babel__generator'
error TS2688: Cannot find type definition file for 'babel__template'
error TS2688: Cannot find type definition file for 'body-parser'
error TS2688: Cannot find type definition file for 'http-errors'
error TS2688: Cannot find type definition file for 'qs'
error TS2688: Cannot find type definition file for 'range-parser'
error TS2688: Cannot find type definition file for 'send'
...
```

These are transitive type dependencies of `@types/express` and `@types/jest` etc.

## Fix: Module Resolution

Change `tsconfig.json` from:

```json
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "resolvePackageJsonExports": true,
    ...
  }
}
```

To:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "moduleResolution": "node",
    ...
  }
}
```

This works because NestJS 11 outputs CommonJS by default, so `module: "commonjs"` with `moduleResolution: "node"` preserves identical runtime behaviour while avoiding the strict type resolution that triggers the TS2688 errors.

## Fix: Install Missing @types

If changing module resolution doesn't work (or you need to keep `nodenext` for ESM reasons), install the missing type packages explicitly:

```
npm install --save-dev @types/babel__generator @types/babel__template @types/babel__traverse @types/body-parser @types/http-errors @types/istanbul-lib-report @types/json-schema @types/qs @types/range-parser @types/send @types/yargs-parser
```

## Class-Validator Decorator Errors (TS1240, TS1241, TS1270)

When DTOs use class-validator decorators (`@IsNotEmpty()`, `@IsString()`, etc.),
TypeScript strict mode may produce:

```
error TS1240: Unable to resolve signature of property decorator when called as an expression.
error TS1241: Unable to resolve signature of method decorator when called as an expression.
error TS1270: Decorator function return type 'void | TypedPropertyDescriptor<unknown>'
  is not assignable to type 'void | ((dto: unknown) => ...)'
error TS1206: Decorators are not valid here.
```

**These are non-blocking.** They only appear when running `tsc` directly (or via
`eslint` with type-aware lint rules). The actual NestJS build (`nest build`) uses
`tsc` with `emitDecoratorMetadata: true` and `experimentalDecorators: true`, which
are compatible with class-validator's legacy decorator format.

**How to check:** Use `npm run build` (which calls `nest build`), not `npx tsc`.
If `nest build` exits 0, the errors from `tsc --noEmit` or `eslint` are not actual
build failures — they're strict-type-check false positives.

**If you must silence them:** Add `"strict": false` to tsconfig or remove
class-validator and validate manually in service methods (not recommended for
new DTOs).

## Verification

After either fix:
```bash
rm -rf dist     # Clean stale build artifacts
npm run build   # Should exit 0 — this is the authoritative check
npm test        # All passing
```
