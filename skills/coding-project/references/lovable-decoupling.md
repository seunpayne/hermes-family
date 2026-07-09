# Lovable Decoupling Checklist

When an existing project was built with Lovable and needs
to be migrated to standalone Vercel deployment, replace
these four dependencies. Order is P0 → P2.

## Dependency Map

| # | Lovable Dependency | Type | Where | Replacement | Priority |
|---|---|---|---|---|---|
| 1 | `@lovable.dev/vite-tanstack-config` | devDep | `vite.config.ts` | Native Vite plugins | **P0** |
| 2 | `@lovable.dev/cloud-auth-js` | dep | `src/integrations/lovable/` | Direct Supabase OAuth | **P0** |
| 3 | Lovable AI Gateway | infra | `supabase/functions/chat/index.ts` | Groq/OpenRouter API | **P0** |
| 4 | "Lovable Cloud" error messages | cosmetic | 3 supabase client files | "Vercel" string | **P2** |

## Step-by-Step

### 1. Decouple Vite Config (P0)

Replace the Lovable wrapper import:
```ts
// BEFORE (Lovable)
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
import { nitro } from "nitro/vite";

// AFTER (native)
import { defineConfig } from 'vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import tsConfigPaths from 'vite-tsconfig-paths'
import { nitro } from 'nitro/vite'
```

If the project uses Nitro for SSR (TanStack Start):
- Keep `nitro({ preset: "vercel" })` in the plugins array
- Use `isVercelBuild` detection: `!!process.env.VERCEL`

Remove `@lovable.dev/vite-tanstack-config` from `package.json` devDependencies.

### 2. Remove Lovable OAuth (P0)

Check if `src/integrations/lovable/index.ts` is ACTUALLY used:
```bash
grep -r "lovable" src/routes/ src/components/ --include="*.tsx"
```

In most cases, the auth route already uses `supabase.auth.signInWithOAuth()`
directly — the Lovable wrapper is unused. Delete the file and the
`@lovable.dev/cloud-auth-js` dependency.

### 3. Replace AI Gateway (P0)

In the Supabase Edge Function (`supabase/functions/chat/index.ts`):
```ts
// BEFORE (Lovable)
const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
fetch("https://ai.gateway.lovable.dev/v1/chat/completions", ...)
model: "google/gemini-3-flash-preview"

// AFTER (Groq — recommended for free tier)
const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
fetch("https://api.groq.com/openai/v1/chat/completions", ...)
model: "llama-3.1-70b-versatile"
```

Deploy: `supabase functions deploy chat`
Set `GROQ_API_KEY` in Supabase dashboard (Edge Function secrets).

### 4. Fix Error Messages (P2)

Search: `grep -rn "Lovable Cloud" src/`
Replace "Connect Supabase in Lovable Cloud" with
"Check your Vercel environment variables" in all 3 files:
- `src/integrations/supabase/client.ts`
- `src/integrations/supabase/client.server.ts`
- `src/integrations/supabase/auth-middleware.ts`

## ⚠️ CRITICAL PITFALL — .env Supabase Swap

When cherry-picking or merging from a pre-existing Lovable
branch, the source branch's `.env` may point at an entirely
different Supabase project. **ALWAYS** run before committing:

```bash
git diff --cached .env
```

If `SUPABASE_URL` / `VITE_SUPABASE_URL` / `VITE_SUPABASE_PROJECT_ID`
changed from the target branch's values: **revert those lines**.
Only keep genuinely new environment variables from the
cherry-pick (e.g. `GROQ_API_KEY`).

## Post-Decoupling Verification

```bash
# No Lovable references remain in source
grep -ri "lovable" src/ --include="*.ts" --include="*.tsx"

# No Lovable packages in deps
grep "lovable" package.json

# No Lovable error reporting files
ls src/lib/lovable-error-reporting.ts src/lib/error-capture.ts src/lib/error-page.ts 2>&1 | grep "No such file"

# No .lovable/ directory
test -d .lovable && echo "STILL EXISTS" || echo "CLEAN"

# No Bun lockfile (if migrating to npm)
test -f bun.lock && echo "BUN LOCK PRESENT" || echo "CLEAN"

# npm install succeeds with no Lovable packages
rm -rf node_modules && npm install

# Build succeeds
npm run build
```

## Additional Lovable Artifacts (Beyond the 4 Dependencies)

These are present in most Lovable TanStack Start projects and must
also be cleaned up:

### 5. Lovable Error Reporting (P0)

Three files form Lovable's error boundary system. All must be removed
or replaced with vanilla alternatives:

```bash
rm src/lib/lovable-error-reporting.ts
rm src/lib/error-capture.ts       # imports lovable-error-reporting
rm src/lib/error-page.ts          # imports lovable-error-reporting
```

Check all imports before deleting:
```bash
grep -r "lovable-error-reporting\|error-capture\|error-page" src/ --include="*.ts" --include="*.tsx"
```

Update any routes/components that import these to use a simple
`ErrorBoundary` or console.error fallback.

### 6. `.lovable/` Directory (P2)

```bash
rm -rf .lovable/
```

Contains Lovable project metadata (`project.json`). Not needed for
standalone deployment.

### 7. AGENTS.md Lovable Section (P2)

Strip the `<!-- LOVABLE:BEGIN -->` ... `<!-- LOVABLE:END -->` block
from `AGENTS.md`. The rest of the file can stay.

### 8. Bun Lockfile (P0 for Vercel)

```bash
rm bun.lock bunfig.toml
```

Lovable defaults to Bun. Vercel needs `package-lock.json` (generated
by `npm install`). Delete Bun artifacts before running `npm install`.

## Tailwind Version Decision

**Lovable builds with Tailwind v4** (`@tailwindcss/vite`, CSS-based `@theme`
config, no `tailwind.config.js`). But many super prompts specify **Tailwind
v3.4** (`tailwind.config.js`, `theme.extend.colors`).

This must be flagged during inspection — it's a non-trivial migration:

| Keep v4 | Downgrade to v3.4 |
|---------|-------------------|
| Faster decoupling | Matches super prompt exactly |
| CSS-based config (no JS) | JS config with `theme.extend` |
| `@theme` directive for tokens | CSS custom properties (`:root { --color-* }`) |
| Different utility class names | Familiar v3 class names |
| `@tailwindcss/vite` plugin | `tailwindcss` + `autoprefixer` PostCSS |

**Present this as a decision point to the user before touching any files.**
Do not assume — the super prompt is the contract.

## Package Manager Decision

Lovable projects often use **Bun**. For Vercel compatibility:
- Switch to **npm** in `vercel.json`: `"installCommand": "npm install"`, `"buildCommand": "npm run build"`
- Delete `bun.lockb`, regenerate `package-lock.json` with `npm install`
- Vercel's Node.js runtime handles npm natively; Bun on Vercel is fragile
