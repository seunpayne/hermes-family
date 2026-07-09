# Sub-agent Timeout Recovery Checklist

When a `delegate_task` sub-agent returns with `status: "timeout"` (600s),
do NOT treat it as a failure. Run this checklist in order.

## Step 1 — Inventory what was built

```bash
# List all files created/modified (exclude node_modules and dist)
find . -maxdepth 4 -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/.git/*' -type f -newer <STALEST-KNOWN-FILE> | sort

# Or list specific modules
find src/modules -name '*.ts' | sort
```

### PITFALL — Sub-agents can corrupt file content with embedded line numbers

After ANY sub-agent returns (success or timeout), spot-check a sample of modified files for content corruption. The most common corruption is **embedded line numbers** — the file starts with `1|import...` instead of `import...` because the sub-agent included the `read_file` line-number prefix in its `write_file` call.

Check a few files quickly:
```bash
head -3 path/to/file.ts
# If you see "1|import" or "1 1|import", the file is corrupted
```

Fix by rewriting the entire file from the original source (addendum spec, PRD, or known-good version), NOT by trying to strip the line numbers with sed — the corruption can extend through the entire file and removals may leave partial damage.

Always verify `npm run build` passes before committing sub-agent output. A corrupted file produces hundreds of parse errors (`TS1109: Expression expected`) and is immediately identifiable.

## Step 2 — Check Prisma schema completeness

If the task created/modified schema, verify all expected entities exist:

```bash
grep '^model ' prisma/schema.prisma | wc -l
grep '^model ' prisma/schema.prisma
```

Cross-check against the PRD's entity list. Missing entities = task not complete.

## Step 3 — Check package.json

```bash
# Verify key dependencies are installed
node -e "require('jsonwebtoken'); console.log('jwt OK')" 2>/dev/null || echo 'missing jwt'
node -e "require('qrcode'); console.log('qrcode OK')" 2>/dev/null || echo 'missing qrcode'
```

Install any missing deps.

## Step 4 — Generate Prisma client

```bash
npx prisma generate
```

## Step 5 — Build

```bash
npm run build 2>&1 | tail -20
```

Fix any TypeScript errors. Common issues:
- **TS2688 (Cannot find type definition)**: Install missing `@types/*` packages.
  Common missing: `@types/node`, `@types/babel__generator`, `@types/qs`,
  `@types/body-parser`, `@types/http-errors`, `@types/send`, `@types/range-parser`
- **TS4053 (Cannot name return type)**: Export the interface/type: `export type { Foo }`
- **TS1205 (Re-exporting in isolatedModules)**: Use `export type` not `export`
- **TS1240/TS1241/TS1270 (Decorator compatibility)**: These are pre-existing
  with class-validator + NestJS 11. Check with `npm run build` (which uses `nest build`,
  not raw tsc). If `nest build` passes, these are non-blocking lint warnings.

## Step 6 — Run tests

```bash
npm test 2>&1 | tail -10
```

Fix failures. Common issues:
- Tests with wrong expected values (the sub-agent wrote the test expecting old stub behavior)
- Missing mock setup
- Import path mismatch (sub-agent created a new file but existing controllers
  still import from the old path)

## Step 7 — Route prefix audit

Sub-agents default to `@Controller('health')` not `@Controller('v1/health')`.
Start the app and inspect registered routes:

```bash
node -e "
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/app.module');
async function test() {
  const app = await NestFactory.create(AppModule);
  await app.init();
  const router = app.getHttpAdapter().getInstance()._router;
  router.stack.forEach(layer => {
    if (layer.route) console.log(Object.keys(layer.route.methods).join(',').toUpperCase(), layer.route.path);
  });
  await app.close();
}
test().catch(() => process.exit(0));
" 2>&1 | grep -v NestFactory | grep -v InstanceLoader | grep -v RouterExplorer | grep -v RoutesResolver
```

Fix any routes missing the `/v1/` prefix.

## Step 8 — Fix broken imports

Sub-agents commonly:
- Create a new file at `src/common/guards/roles.guard.ts` but some controllers
  still `import { RolesGuard } from '../../common/guards/jwt-auth.guard'`
- Create a new module but forget to register it in `app.module.ts`

Check ALL controller imports:

```bash
grep -rn "import.*from.*guards" src/modules/
```

## Step 9 — Add missing infrastructure files

Sub-agents often skip:
- `Procfile` (Railway: `web: node dist/main.js`)
- `.gitignore` (node_modules, dist, .env, coverage)
- `ARCHITECTURE_DECISIONS.md` (log key decisions from this task)
- `README.md` (setup instructions)

## Step 10 — Check for orphaned schema fields

If the task touched `schema.prisma`, verify no new fields were left without a migration:

```bash
# Count migration directories
ls -d prisma/migrations/*/ | wc -l
# Check recent schema changes
git diff HEAD~1 -- prisma/schema.prisma | grep '^+' | grep -v '^+++'
```

If new fields are in schema but no migration SQL exists, create one before pushing.
A deployed schema change without a migration crashes with `P2022` on Railway.
See `references/prisma-orphaned-migration-detection.md`.

## Step 11 — Rebuild and retest

```bash
npm run build && npm test
```

## Step 12 — Re-delegate Remaining Work (Resume Brief Pattern)

When the sub-agent completed partial work (built some tasks but timed out before finishing), do NOT fix everything yourself if the remaining work is large (>3 tasks, >20 files). Instead:

1. **Assess depth of completion for each remaining task**
   Check key directories and files for each task on the list. Example:
   ```bash
   # Has the scaffold been created?
   ls package.json src/app/page.tsx src/middleware.ts 2>/dev/null
   # Has the migration been written?
   ls supabase/migrations/ 2>/dev/null
   # Are specific routes created?
   ls src/app/announcements/src/app/leaderboard/ 2>/dev/null
   ```

2. **Check git state**
   ```bash
   git log --oneline -5          # What was committed
   git remote -v                 # Is there a remote?
   git status --short            # Any uncommitted work
   ```

3. **Check key files for implementation depth**
   Don't just check if a file exists — check if it's substantial:
   ```bash
   wc -l src/app/page.tsx                       # Landing page line count
   head -10 src/app/admin/news/page.tsx 2>/dev/null  # Pattern used
   ```

4. **Write a Resume Brief** — a markdown file with exact sections:
   - `## ✅ COMPLETED — Do NOT touch these` — list each task with key files created
   - `## ❌ REMAINING — Build these in order` — list each undone task with specific file paths
   - `## IMPORTANT CONSTRAINTS` — non-negotiables the sub-agent must follow
   
   Example format:
   ```markdown
   ### T-00X: Feature Name
   - src/app/.../ — description of page/route needed
   - src/app/api/.../route.ts — description of endpoint
   - Key constraint: use user_roles table, NOT user_metadata
   ```

5. **Re-delegate with the resume brief as context**
   ```python
   delegate_task(
       goal="[concise: remaining N tasks]",
       context="Resume brief at [path]. Read this first for exact state."
   )
   ```

6. **Verify the re-delegation result**
   After the resumed sub-agent returns, check the same files from step 1
   to confirm the remaining tasks were actually built.

This pattern is for when the remaining work is substantial enough that fixing
everything manually would take longer than re-delegating. If only 1-2 small tasks
remain, fix them directly using Steps 1-10.

## Step 13 — Update Supabase

After all fixes:
1. Mark task as `done` in Supabase
2. Log a decision with what was built + any fixes applied
3. Update project `updated_at` timestamp
4. Create the next task before dispatching
