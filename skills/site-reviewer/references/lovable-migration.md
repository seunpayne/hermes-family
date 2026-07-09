# Lovable → Standard Stack Migration

## What Is Lovable?

Lovable (lovable.dev) is a no-code/low-code platform that generates React/TanStack Start projects with proprietary dependencies that lock the project to their platform.

**Proprietary packages to remove:**
- `@lovable.dev/vite-tanstack-config` — Vite configuration wrapper
- `@lovable.dev/cloud-auth-js` — OAuth authentication wrapper
- Lovable AI Gateway — Proxy for AI API calls

---

## Migration Pattern

### 1. Remove Lovable Packages

**In `package.json`:**
```json
// REMOVE from dependencies:
"@lovable.dev/cloud-auth-js": "^1.1.2",

// REMOVE from devDependencies:
"@lovable.dev/vite-tanstack-config": "^1.4.0",
```

**Delete files:**
```bash
rm src/integrations/lovable/index.ts
```

### 2. Rewrite Vite Configuration

**Before (`vite.config.ts`):**
```typescript
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
export default defineConfig();
```

**After (`vite.config.ts`):**
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import tailwindcss from '@tailwindcss/vite'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    TanStackRouterVite({ autoCodeSplitting: true }),
    react(),
    tailwindcss(),
    tsconfigPaths(),
  ],
  resolve: {
    alias: { '@': '/src' },
  },
  ssr: {
    external: [
      '#tanstack-router-entry',
      '#tanstack-start-entry',
      '#tanstack-start-plugin-adapters',
      'tanstack-start-manifest:v',
      'tanstack-start-injected-head-scripts:v',
    ],
  },
  optimizeDeps: {
    exclude: ['@tanstack/react-start', '@tanstack/react-start/server'],
  },
})
```

**Key additions:**
- `ssr.external` — Prevents TanStack Start SSR entry point errors
- `optimizeDeps.exclude` — Prevents Vite dependency optimizer from failing on TanStack Start packages

### 3. Create Entry Points (If Missing)

Lovable projects often lack standard entry points. Create them:

**`index.html`:**
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>[Project Name]</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

**`src/main.tsx`:**
```tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import { RouterProvider, createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'
import './styles.css'

const router = createRouter({ routeTree })

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>,
)
```

### 4. Replace OAuth Authentication

**Before (`src/routes/auth.tsx`):**
```typescript
import { lovable } from "@/integrations/lovable";

const handleGoogle = async () => {
  const result = await lovable.auth.signInWithOAuth("google", {
    redirect_uri: window.location.origin + "/dashboard",
  });
  if (result.error) { /* handle */ }
  if (result.redirected) return;
  navigate({ to: "/dashboard" });
};
```

**After (`src/routes/auth.tsx`):**
```typescript
import { supabase } from "@/integrations/supabase/client";

const handleGoogle = async () => {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: window.location.origin + '/dashboard',
    },
  });
  if (error) throw error;
  // OAuth redirects to Google, so we don't navigate here
};
```

**Prerequisites:**
- Google OAuth must be configured in **Supabase Dashboard** → Authentication → Providers → Google
- Client ID and Client Secret must be saved
- Authorized redirect URI in Google Cloud Console: `https://[project-ref].supabase.co/auth/v1/callback`

**Common Error:**
```json
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```

**Fix:** This means Google provider is NOT configured in Supabase Dashboard. The credentials must be added there, not just in Google Cloud Console.

### 5. Replace AI Chatbot Gateway

**Before (`supabase/functions/chat/index.ts`):**
```typescript
const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
  method: "POST",
  headers: { Authorization: `Bearer ${LOVABLE_API_KEY}` },
  body: JSON.stringify({ model: "google/gemini-3-flash-preview", stream: true, messages }),
});
```

**After (Groq example):**
```typescript
const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
  method: "POST",
  headers: { Authorization: `Bearer ${GROQ_API_KEY}` },
  body: JSON.stringify({ model: "llama-3.1-70b-versatile", stream: true, messages }),
});
```

**Alternative providers:**
- OpenAI: `https://api.openai.com/v1/chat/completions`
- Anthropic: `https://api.anthropic.com/v1/messages`

### 6. Install Dependencies

```bash
# If bun.lockb exists but bun is not installed:
npm install  # Works fine, ignores bun.lockb

# Or if you have bun:
bun install
```

### 7. Start Dev Server

```bash
npm run dev
# or
bun run dev
```

---

## Verification Checklist

- [ ] `package.json` has no `@lovable.dev/*` packages
- [ ] `src/integrations/lovable/` directory deleted
- [ ] `vite.config.ts` uses standard plugins
- [ ] `index.html` exists at project root
- [ ] `src/main.tsx` exists with RouterProvider
- [ ] OAuth uses `supabase.auth.signInWithOAuth()`
- [ ] AI chatbot calls provider API directly (not via lovable.dev)
- [ ] Dev server starts without errors
- [ ] Hot reload works
- [ ] Google OAuth redirects correctly (if configured)

---

## Common Pitfalls

### 1. TanStack Start SSR Errors

**Error:**
```
The file does not exist at ".../node_modules/.vite/deps_tanstack_start_app/@tanstack_react-start_server-entry.js"
```

**Fix:** Add to `vite.config.ts`:
```typescript
ssr: {
  external: [
    '#tanstack-router-entry',
    '#tanstack-start-entry',
    '#tanstack-start-plugin-adapters',
    'tanstack-start-manifest:v',
    'tanstack-start-injected-head-scripts:v',
  ],
},
optimizeDeps: {
  exclude: ['@tanstack/react-start', '@tanstack/react-start/server'],
},
```

### 2. Google OAuth "Missing OAuth Secret"

**Error:**
```json
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```

**Cause:** Google provider not enabled in Supabase Dashboard.

**Fix:**
1. Go to Supabase Dashboard → Authentication → Providers → Google
2. Toggle "Enable Sign in with Google" → ON
3. Enter Client ID and Client Secret
4. Click Save
5. Wait 2-3 minutes for propagation

**Note:** Configuring Google Cloud Console alone is NOT sufficient. The credentials must be saved in Supabase Dashboard.

### 3. Missing Entry Points

**Symptom:** Dev server starts but page is blank (404 or empty root)

**Cause:** Lovable projects may not include `index.html` or `main.tsx`.

**Fix:** Create both files as shown in Step 3 above.

### 4. Autoskills Timeout

**Symptom:**
```
[Command timed out after 60s]
```

**Cause:** Large codebases with many dependencies.

**Action:** Do NOT retry. The technology detection output is still printed before the timeout. Read the `✔` list and `skills-lock.json` to proceed.

---

## Session Example: Omayoza (May 19, 2026)

**Repo:** `github.com/seunpayne/Omayoza`

**Stack detected:**
- TanStack Start v1.167, React 19, TypeScript
- Tailwind CSS v4, shadcn/ui
- Supabase (auth + database)
- Cloudflare Workers (via Vite plugin)

**Migration steps completed:**
1. Removed `@lovable.dev/*` packages
2. Rewrote `vite.config.ts` with standard plugins + SSR externals
3. Created `index.html` and `src/main.tsx`
4. Replaced Lovable OAuth with Supabase native OAuth
5. Replaced Lovable AI Gateway with Groq API
6. Added Groq API key to `.env`
7. Ran `npm install` (548 packages)
8. Dev server running at http://localhost:5173

**Logo update:** Replaced CSS-styled logo with PNG assets (`omayoza-logo-transparent.png`, 80px height)

**Outstanding:** Google OAuth credentials need to be saved in Supabase Dashboard (user confirmed configuration in progress)

---

## Related Skills

- `site-reviewer` — Main skill for reviewing and modifying GitHub repos
- `web-builder` — For building new sites from super prompts
- `supabase-postgres-best-practices` — For Supabase integration patterns
