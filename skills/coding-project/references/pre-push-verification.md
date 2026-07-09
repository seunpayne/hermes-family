# Pre-Push Verification Checklist

Run this checklist BEFORE every `git push` to any branch.
Catching a build failure locally costs seconds; catching it in CI costs minutes and frustrates.

## Mandatory Checks (every push, in order)

### 1. Staged file audit
```bash
git status --short
```
- Confirm ONLY intended files are staged. No `.env`, `.env.local`, `*.log`, `node_modules/`, `.next/`, `dist/`.
- Confirm `package-lock.json` is staged if dependencies were added — CI uses `npm ci` which requires exact lock-file match.

### 2. Lint
```bash
npm run lint
```
- **Exit 0 required.** Warnings are OK (Next.js—no-img-element, react-hooks/exhaustive-deps).
- If errors: fix them. Common patterns below.
- Exit code > 0 = CI will reject the push.

### 3. Build
```bash
npm run build
```
- **Exit 0 required.** This is the definitive production build check.
- `next build` (Next.js) treats lint errors as build failures by default.
- `nest build` (NestJS) and `tsc` can disagree — see Common Pitfalls below.

### 4. Quick CI preview
```bash
git push --dry-run origin <branch>
```
- Confirm the push won't fail on remote HEAD mismatch or authentication.

## Common Next.js Build Errors & Fixes

### Unused variable / import (TypeScript strict mode)
**Error:** `'X' is defined but never used.  @typescript-eslint/no-unused-vars`
**Fix:** Remove the variable or prefix with `_`. For React state where only the setter is used:
```typescript
// BAD: 'inviteEmail' assigned but never read
const [inviteEmail, setInviteEmail] = useState('')
// GOOD: destructure only the setter
const setInviteEmail = useState('')[1]
```

### Server Action FormData type mismatch
**Error:** `Type 'FormData' is not assignable to type 'string'.`
**Fix:** Server actions used with `<form action={fn}>` receive `FormData`, not a custom parameter:
```typescript
// WRONG
export async function deleteItem(id: string) { ... }
// RIGHT
export async function deleteItem(formData: FormData) {
  const id = formData.get('id') as string
}
```

### null-safe encodeURIComponent
**Error:** `Type 'null' is not assignable to type 'string | number | boolean'.`
**Fix:** The value comes from `searchParams.get('key')` which is `string | null`. If already guarded by an early return, use non-null assertion:
```typescript
const token = searchParams.get('token')
if (!token) return // early guard
// TypeScript still sees string | null, so:
encodeURIComponent(token!) // non-null assertion
```

### Deno imports in supabase/functions break Next.js build
**Error:** `Cannot find module 'https://esm.sh/@supabase/supabase-js@2'`
**Root cause:** Next.js tsconfig has `"include": ["**/*.ts"]` which pulls in `supabase/functions/*.ts` containing Deno-style URL imports that Node.js/Next.js can't resolve.
**Fix:** Exclude `supabase/` from tsconfig:
```json
"exclude": ["node_modules", "supabase"]
```
The Supabase CLI uses Deno's own TypeScript compiler — excluding from Next's tsconfig doesn't affect Edge Function deployment.

### Disconnected catch clause
**Error:** `'err' is defined but never used.`
**Fix:** TypeScript 4.0+ supports catch without binding:
```typescript
// BAD
} catch (err) { ... }
// GOOD
} catch { ... }
```

### Implicit `any` in array methods
**Error:** `Parameter 'n' implicitly has an 'any' type.`
**Fix:** Add explicit type annotation to the callback parameter:
```typescript
.split(' ').map((n: string) => n[0])  // instead of (n) => n[0]
```

## NestJS-Specific Checks

When the project uses NestJS (e.g. Streetwise backend):

### Monitor for both build commands
```bash
npm run build   # uses nest build — ONLY compiles src/
npx tsc --noEmit  # checks src/ AND test/ for type errors
```
These can disagree. Run BOTH before pushing.
- If `npm run build` fails: fix immediately — production won't build.
- If `tsc --noEmit` fails in `test/` only: safe to push (test-only errors don't block CI production build).

## When CI Still Fails After Push

1. Check the GitHub Actions run URL from the push output
2. Read the failing job logs — they are the source of truth
3. Compare against the checklist above — the CI runs the same commands
4. Common CI-only failures:
   - **Missing dependencies:** `npm ci` failed → commit `package-lock.json`
   - **TruffleHog setup failed:** action reference may be stale (`trufflesecurity/trufflehog@v3` → `@main`)
   - **Secrets not in repo context:** CI may need `GITHUB_TOKEN` or `VERCEL_TOKEN` in repo secrets

### Systematic CI Fix Workflow

When CI fails, fix ALL errors in one pass, then re-push once:

1. **Run `npm run lint` locally** — see ALL lint errors at once
   - Fix all unused variables, type errors, null-safety issues
   - Re-run lint to confirm zero errors
   
2. **Run `npm run build` locally** — this may reveal DIFFERENT errors
   - Next.js build treats lint errors as failures
   - TypeScript strict mode may catch things lint didn't
   - Fix ALL build errors
   
3. **Address CI-specific failures:**
   - TruffleHog action version → pin to `@main` or specific version
   - Missing `package-lock.json` → `git add` it
   - Env vars not set in CI → check repo secrets
   
4. **Commit and push ONCE** with all fixes batched
   
5. **Check GitHub Actions** — confirm the new run goes green
   - If it fails again, read the logs and repeat from step 1
   - Do NOT push a third time without verifying locally first

## Supabase Migration Ordering Pitfall

When the migration SQL references a table inside a function definition,
the table must be created BEFORE the function:

```sql
-- WRONG: is_admin() references user_roles before it exists
CREATE FUNCTION is_admin() ... SELECT 1 FROM user_roles ...;
CREATE TABLE user_roles (...);

-- RIGHT: table first, then function
CREATE TABLE user_roles (...);
CREATE FUNCTION is_admin() ... SELECT 1 FROM user_roles ...;
```

**Error:** `ERROR: 42P01: relation "public.user_roles" does not exist`
**Fix:** Reorder the migration so all tables are created before any function
that queries them. General rule: `CREATE TABLE → CREATE FUNCTION → CREATE TRIGGER`.

**Why it happens:** SQL migrations execute top-to-bottom in a single
transaction. A function definition is compiled (not just parsed) at
`CREATE FUNCTION` time — every table it references must already exist.
This applies to ALL functions with table references, not just `is_admin()`.
