# Cherry-Picking Features Between Branches

When a secondary branch (e.g. cc-build from Claude Code) has specific files or features worth extracting into the primary branch.

## When to cherry-pick vs merge

| Situation | Action |
|-----------|--------|
| Secondary branch has a completely different architecture (monorepo vs flat) | **Cherry-pick individual files.** Do NOT merge the whole branch — you'll bring in conflicting configs. |
| Specific component is demonstrably better (e.g. Service Worker, RLS migration) | **Cherry-pick that file/directory.** Verify it works in your structure after copying. |
| Secondary has same architecture, same entity structure | **Merge the branch** and resolve conflicts normally. |

## Cherry-pick workflow

### 1. Clone the secondary branch
```bash
cd /tmp
git clone --branch <branch-name> --depth 1 <repo-url> <dir-name>
```
`--depth 1` avoids downloading the full history — only the latest commit.

### 2. Compare entity models (for Prisma-based projects)
```bash
grep -c "^model " primary/prisma/schema.prisma
grep -c "^model " secondary/prisma/schema.prisma
grep "^model " secondary/prisma/schema.prisma  # list entity names
```
This reveals structural differences quickly. Extra entities mean different architecture decisions.

### 3. Compare architectural patterns
Check for key structural differences:

| Check | Command |
|-------|---------|
| Root package manager | `ls primary/package.json secondary/package.json 2>/dev/null` |
| Monorepo tool | `ls primary/turbo.json secondary/turbo.json 2>/dev/null` |
| CI location | `ls primary/.github/workflows/ secondary/.github/workflows/` |
| Auth approach | `grep -r "Passport\|JwtAuthGuard\|clerk" primary/src/ secondary/src/` |
| RLS vs app-layer | `grep -r "ENABLE ROW LEVEL SECURITY\|community-scope" primary/ secondary/` |
| Offline strategy | `ls primary/public/sw.js secondary/public/sw.js 2>/dev/null` |
| Notification approach | `grep -r "BullMQ\|BullModule\|@nestjs/bull" primary/ secondary/` |

### 4. Extract specific files
```bash
# Copy a directory
cp -r /tmp/secondary/apps/api/src/modules/consigliere/ primary/src/modules/consigliere/

# Copy a single file  
cp /tmp/secondary/apps/web/public/sw.js primary/public/sw.js

# Copy a migration (rename to next sequence number)
cp /tmp/secondary/packages/database/prisma/migrations/0001_rls_setup/migration.sql \
   primary/prisma/migrations/0002_rls_setup/migration.sql
```

### 5. Adapt the copied code to your structure
After copying, the files likely need path adjustments:

- **Import paths:** Secondary may use monorepo paths (`@streetwise/database`, `@streetwise/shared`). Replace with relative imports.
- **Module registration:** Add the new module to `app.module.ts` imports array.
- **Package dependencies:** Install any packages the secondary used that primary doesn't have.

### 6. Clean up secondary artifacts
After cherry-picking, ALWAYS check for files the secondary branch might have left in the working tree via merge or shared repo:

```bash
# Check for monorepo artifacts
ls package.json turbo.json lighthouserc.json apps/ packages/ 2>/dev/null

# If found and not needed:
rm -rf package.json turbo.json lighthouserc.json apps/ packages/

# Check for stale CI in wrong location
ls backend/.github/workflows/ 2>/dev/null  # GitHub only reads from root .github/workflows/
```

### 7. Verify
```bash
npm run build
npm test
# For migrations:
npx prisma validate
```

## Pitfalls

- **CI will fail after first push** if the secondary branch's CI file was in the root `.github/workflows/` and references non-existent paths (monorepo paths like `packages/database/prisma/`). Replace it with your own CI.
- **Root package.json** from a monorepo will break `npm ci` — it references workspaces that don't exist in your structure. Remove it.
- **Turborepo config** (`turbo.json`) will cause confusion if both the primary and secondary have root-level scripts. Remove it from the primary.
- **Never merge a monorepo branch into a flat-structure branch.** The merge will bring in conflicting file trees at the root.
