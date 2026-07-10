# LOVABLE REMOVAL PLAYBOOK
Date: 2026-05-21
Project: Omayoza (and future Lovable-built projects)

---

## WHAT THIS DOES

Removes Lovable.dev platform lock-in from TanStack Start/React projects and replaces with:
- Native Supabase authentication
- Direct Groq API (or other AI provider)
- Standard Vite + TanStack Start configuration
- Vercel deployment (not Cloudflare)

---

## WHAT LOVABLE BAKES IN

Lovable projects come with:

- **Custom Vite plugins** — `@lovable.dev/vite-tanstack-config` breaks standard builds
- **Auth wrapper** — `@lovable.dev/cloud-auth-js` wraps Supabase auth (must be removed)
- **AI Gateway** — Proxy layer between app and AI provider (adds latency, vendor lock-in)
- **Lovable Supabase project** — Separate from your production Supabase (data lock-in)
- **Cloudflare-first deployment** — Vercel/Netlify configs may be missing or broken

Decoupling removes all four layers and connects directly to:
- Your Supabase project
- Your AI provider (Groq, Anthropic, OpenAI)
- Your deployment platform (Vercel)

---

### PHASE 0a — LOCAL TESTING ENVIRONMENT

**Run this once at the start of every decoupling project.**

**Goal:** The app runs locally and connects to all real services — Supabase, Google OAuth, AI Chat — before any decoupling changes are made. This becomes the baseline.

**Everything is tested locally first.** Only when local tests pass does anything go to staging or production.

---

#### STEP 1 — Install tools (once per machine)

**Check each is present:**

```bash
node --version        # must be 22+
supabase --version    # must be installed
vercel --version      # must be installed
ngrok --version       # for OAuth testing if needed
```

**Install any missing:**

```bash
brew install supabase/tap/supabase
npm install -g vercel
brew install ngrok
```

---

#### STEP 2 — Create .env.local

**Create at project root. Never commit. Must be in `.gitignore`.**

```bash
# Confirm .gitignore includes .env.local
grep ".env.local" .gitignore || echo ".env.local" >> .gitignore
```

**Create the file:**

```bash
cat > .env.local << 'EOF'
# Supabase — use REAL project (not local Supabase)
VITE_SUPABASE_URL=https://[project-ref].supabase.co
VITE_SUPABASE_ANON_KEY=[anon key from Supabase dashboard]

# AI Chat Edge Function
# Option A: remote (simpler — use deployed function)
VITE_SUPABASE_FUNCTIONS_URL=https://[project-ref].supabase.co/functions/v1
# Option B: local (if running supabase functions serve)
# VITE_SUPABASE_FUNCTIONS_URL=http://localhost:54321/functions/v1

# OAuth callback — must match what is registered
VITE_SITE_URL=http://localhost:5173
EOF
```

**Replace placeholders with real values from:**
Supabase Dashboard → Project Settings → API

---

#### STEP 3 — Register localhost with OAuth providers

**OAuth will fail locally if localhost URLs are not registered.**

This does not affect production — these are additions, not replacements.

**Supabase Dashboard:**
Authentication → URL Configuration
- Site URL: `http://localhost:5173`
- Add to Redirect URLs:
  - `http://localhost:5173/auth/callback`
  - `http://localhost:5173/**`

**Google Cloud Console** (if Google OAuth is used):
console.cloud.google.com → APIs & Services → Credentials → OAuth 2.0 Client ID
- Authorized JavaScript origins: add `http://localhost:5173`
- Authorized redirect URIs: add
  - `https://[project-ref].supabase.co/auth/v1/callback`
  - (if not already there from Pitfall 13 fix)

**GitHub OAuth App** (if GitHub OAuth is used):
github.com/settings/developers → OAuth Apps → [app]
- Homepage URL: `http://localhost:5173`
- Authorization callback URL: `https://[project-ref].supabase.co/auth/v1/callback`

**Note:** The Supabase callback URL (`/auth/v1/callback`) is always the deployed Supabase URL — this never changes for local dev. What changes is where Supabase redirects the user AFTER auth — that uses `VITE_SITE_URL`.

---

#### STEP 4 — Start AI Chat Edge Function (if project has AI chat)

**Option A — Use deployed Edge Function (recommended for local testing):**

No setup needed. The function is already deployed.
`VITE_SUPABASE_FUNCTIONS_URL` points to the remote URL.

**Option B — Run locally** (for development of the function itself):

```bash
# In a separate terminal:
supabase functions serve chat \
  --env-file .env.local \
  --no-verify-jwt

# Change VITE_SUPABASE_FUNCTIONS_URL in .env.local to:
# http://localhost:54321/functions/v1
```

**Option A is simpler.** Use Option B only if actively developing the Edge Function itself.

---

#### STEP 5 — Start the dev server

```bash
npm install
npm run dev
```

**Expected output:**

```
VITE v[x.x.x] ready in [N] ms
➜  Local:   http://localhost:5173/
➜  Network: http://[ip]:5173/
```

Open `http://localhost:5173` in browser.

---

#### STEP 6 — Local testing checklist

**Run these checks before starting any decoupling phase.**

This is the baseline. If any fail — fix them before decoupling begins. **Do not decouple a broken app.**

- [ ] **App loads** at `http://localhost:5173` — no console errors
- [ ] **Supabase connected** — open browser dev tools → Network
  - Look for requests to `supabase.co` returning 200
  - Or: trigger any data load in the app and confirm data appears
- [ ] **Supabase auth** — click Sign In
  - Auth redirect goes to OAuth provider
  - After auth: redirect returns to `http://localhost:5173`
  - User session visible in Supabase dashboard → Authentication
- [ ] **AI Chat** — open chat widget
  - Send a test message
  - Response streams back (not instant — should see words appearing)
  - Check Network tab: request goes to `functions/v1/chat`
  - Check Supabase: row appears in `conversations` table
- [ ] **Build completes cleanly**
  ```bash
  npm run build
  ```
  - No errors, no warnings about missing env vars
  - `dist/` directory created

**If all 5 pass: baseline confirmed.**

Send Telegram:

```
Local baseline confirmed. [project name] — all services connected locally.
Supabase ✓ OAuth ✓ AI Chat ✓ Build ✓
Beginning Phase 0 read.
```

**If any fail: fix before proceeding.**

Do not start decoupling work on a broken baseline.

---

#### AFTER EACH DECOUPLING PHASE — local re-test

After completing each phase (1a, 1, 2, 3, 4):

**Re-run the checklist.** Confirm all 5 still pass.

This catches regressions immediately — not after 6 phases of changes.

**The pattern:**

```
Phase 0a: baseline ✓
→ Phase 1a: still works ✓
→ Phase 1: still works ✓
→ ...
```

**Never move to the next phase if the current one broke something.**

---

## STEP-BY-STEP PROCESS

### 1. Clone the Lovable Project

```bash
cd ~/Projects/reviews
git clone <lovable-github-url> <project-name>
cd <project-name>
```

### PHASE 1a — VITE CONFIG REPLACEMENT

**CRITICAL: Run this BEFORE any other phase.**

Lovable installs custom Vite plugins that break standard builds after removal. Fix the Vite config first.

**Read the existing config:**

```bash
cat vite.config.ts
```

**Replace with:**

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') }
  },
  build: {
    rollupOptions: {
      output: { manualChunks: undefined }
    }
  }
})
```

**Use `@vitejs/plugin-react-swc`** unless the original used `@vitejs/plugin-react` — match what was there.

**RUN:**

```bash
rm -rf node_modules/.vite && npm run build
```

**VERIFY:** Build completes without TSRSplitComponent error.

### 2. Remove Lovable Packages

Edit `package.json`:

**REMOVE:**
```json
"@lovable.dev/cloud-auth-js": "^1.1.2",
"@lovable.dev/vite-tanstack-config": "^1.4.0",
```

**Run:**
```bash
npm uninstall @lovable.dev/compat \
  @lovable-tagger/react lovable-tagger 2>/dev/null || true
```

**Install dependencies:**
```bash
npm install
```

### 3. Replace Vite Config

**Delete:** `vite.config.ts`

**Create new `vite.config.ts`:**

```ts
import { defineConfig } from 'vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'
import react from '@vitejs/plugin-react'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import tailwindcss from '@tailwindcss/vite'
import tsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [
    tanstackRouter({
      target: 'react',
      autoCodeSplitting: false  // CRITICAL: prevents TSRSplitComponent error in dev
    }),
    react(),
    tanstackStart({ vitePluginApi: { include: ['src/api'] } }),
    tailwindcss(),
    tsConfigPaths()
  ],
  server: {
    port: 5173
  },
  build: {
    target: 'esnext'
  },
  ssr: {
    noExternal: ['@tanstack/react-start']
  }
})
```

**⚠️ Plugin Order is CRITICAL:**
1. `tanstackRouter` MUST be first
2. `react` MUST be second
3. Other plugins follow

Vite 7 has a bug that misdetects plugin order even when correct. If dev server fails, try:
- Clear caches: `rm -rf .tanstack node_modules/.vite dist`
- Use production build for testing: `npm run build && npm run preview`

### 4. Remove Lovable Integration Folder

**Audit `src/integrations/supabase/` carefully.**

**If it contains ONLY `client.ts` and `types.ts`:**
- Keep `client.ts` — it only reads env vars
- Regenerate `types.ts` from new Supabase project:
  ```bash
  supabase gen types typescript --linked > \
    src/integrations/supabase/types.ts
  ```

**If it contains hooks, wrappers, or API files:**
- Delete the folder entirely
- Recreate clean `client.ts` using web stack playbook pattern

```bash
rm -rf src/integrations/lovable
```

### 5. Fix Auth Routes

**Find all files importing from `@/integrations/lovable`:**

```bash
grep -r "lovable" src/routes/ --include="*.tsx"
```

**Replace Lovable auth with native Supabase:**

**BEFORE:**
```ts
import { lovable } from "@/integrations/lovable";

const handleGoogle = async () => {
  const result = await lovable.auth.signInWithOAuth("google", {
    redirect_uri: window.location.origin + "/dashboard"
  });
};
```

**AFTER:**
```ts
import { supabase } from "@/integrations/supabase/client";

const handleGoogle = async () => {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: window.location.origin + "/dashboard"
    }
  });
};
```

### 6. Replace Lovable AI Gateway (if present)

**Find Lovable AI usage:**

```bash
grep -r "lovable.ai" supabase/functions/ --include="*.ts"
```

**Replace with direct provider API (example: Groq):**

**BEFORE:**
```ts
const response = await fetch("https://api.lovable.dev/v1/chat", {
  method: "POST",
  headers: { "Authorization": `Bearer ${LOVABLE_API_KEY}` },
  body: JSON.stringify({ model: "gemini", messages })
});
```

**AFTER:**
```ts
const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
  method: "POST",
  headers: { "Authorization": `Bearer ${GROQ_API_KEY}` },
  body: JSON.stringify({
    model: "llama-3.1-70b-versatile",
    messages
  })
});
```

### 7. Update Environment Variables

**Edit `.env`:**

**REMOVE:**
```env
SUPABASE_URL="https://<lovable-project>.supabase.co"
LOVABLE_API_KEY="..."
```

**ADD:**
```env
VITE_SUPABASE_URL="https://<your-project>.supabase.co"
VITE_SUPABASE_ANON_KEY="sb_publishable_..."
GROQ_API_KEY="gsk_..."
```

### 8. Update Vercel Config (if deploying to Vercel)

**Edit `vercel.json`:**

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "npm run build",
  "outputDirectory": ".vercel/output",
  "framework": "vite",
  "installCommand": "npm install"
}
```

**Note:** Use `npm` not `bun` unless you specifically need Bun.

### 9. Update Supabase OAuth Redirect URLs

**Go to:** https://app.supabase.com/project/<your-project>/authentication/providers

**Click "Google" → Add Redirect URLs:**

```
http://localhost:5173/auth/callback
https://www.yourdomain.com
https://www.yourdomain.com/auth/callback
https://<your-vercel-preview>.vercel.app
```

**Save and wait 3-5 minutes for propagation.**

### 10. Verify Google Cloud Console

**Go to:** https://console.cloud.google.com/apis/credentials

**Check OAuth 2.0 Client → Authorized redirect URIs:**

Must include:
```
https://<your-supabase-project>.supabase.co/auth/v1/callback
```

### 11. Build and Deploy

```bash
# Test production build
npm run build

# Deploy to Vercel
npx vercel --prod --yes
```

### 12. Add Environment Variables to Vercel

**Go to:** Vercel Dashboard → Project Settings → Environment Variables

**Add:**
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `GROQ_API_KEY` (or other AI provider)

**Redeploy.**

---

## KNOWN PITFALLS

### PITFALL 1 — TSRSplitComponent error after removing Lovable plugins

**Symptom:** Dev server starts but pages show `ReferenceError: TSRSplitComponent is not defined`

**Cause:** TanStack Router code-splitting bug in dev mode

**Fix:** Set `autoCodeSplitting: false` in router plugin config:

```ts
tanstackRouter({
  target: 'react',
  autoCodeSplitting: false
})
```

### PITFALL 2 — Plugin order detection bug during dev server

**Symptom:** `Error: Plugin order error: '@vitejs/plugin-react' is placed before '@tanstack/router-plugin'`

**Cause:** Vite 7 + TanStack Router compatibility bug — plugin order detection fails even when config is correct

**Fix:** Clear Vite cache:

```bash
rm -rf node_modules/.vite && npm run dev
```

If persists, use production build for testing:

```bash
npm run build && npx serve dist
```

### PITFALL 3 — OAuth redirects to localhost after migration

**Symptom:** After signing in with Google, redirects to `http://localhost:3000` or `http://localhost:5173` instead of production domain

**Cause:** Supabase Dashboard doesn't have production URLs in redirect whitelist

**Fix:** Supabase Dashboard → Authentication → URL Configuration → Redirect URLs

Add:
```
https://[client-domain]/auth/callback
https://[staging].vercel.app/auth/callback
```

Localhost only is never correct in production.

### PITFALL 4 — "Unable to exchange external code" on OAuth

**Symptom:** OAuth flow completes but returns to auth page with error `Unable to exchange external code: 4/0A`

**Cause:** Google Cloud Console OAuth config mismatch — Authorized redirect URI doesn't match Supabase callback

**Fix:** Google Cloud Console → OAuth 2.0 Client → Authorized redirect URIs

Add:
```
https://[supabase-project-ref].supabase.co/auth/v1/callback
```

Must match exactly. No trailing slash.

---

## PITFALLS & SOLUTIONS

### Dev Server Won't Start: "TSRSplitComponent is not defined"

**Cause:** TanStack Router code-splitting bug in dev mode

**Fix:** Set `autoCodeSplitting: false` in vite.config.ts

```ts
tanstackRouter({
  target: 'react',
  autoCodeSplitting: false
})
```

### Dev Server Won't Start: "Plugin order error"

**Cause:** Vite 7 + TanStack Router compatibility bug

**Workarounds:**
1. Clear caches: `rm -rf .tanstack node_modules/.vite dist`
2. Use production build for testing: `npm run build && npm run preview`
3. Downgrade to Vite 6 (if feasible)

### OAuth Redirects to localhost on Production

**Cause:** Supabase doesn't have production URL in redirect whitelist

**Fix:** Add production URLs in Supabase Dashboard → Authentication → Providers → Google → Redirect URLs

### "Unable to exchange external code" Error

**Cause:** Google Cloud Console OAuth config mismatch

**Fix:**
1. Verify `https://<your-supabase-project>.supabase.co/auth/v1/callback` is in Google Cloud Console → Authorized redirect URIs
2. Check OAuth Consent Screen is "Published" (not "Testing")
3. Regenerate credentials if needed

---

## FILES TO AUDIT

After removal, verify no Lovable references remain:

```bash
grep -r "lovable" src/ --include="*.ts" --include="*.tsx"
grep -r "lovable" package.json
grep -r "@lovable.dev" .
```

Expected: Only matches in `package-lock.json` (will regenerate on next install)

---

## TIME ESTIMATE

- First time: ~45-60 minutes
- Subsequent projects: ~20-30 minutes

---

## PROJECTS COMPLETED

| Project | Date | Branch/Repo |
|---------|------|-------------|
| Omayoza | 2026-05-21 | `cleaned-no-lovable` |

---

## TASK CODE GENERATION GUIDE

When generating tasks for a decoupling project PRD, include this as the first task:

### TASK 0a — Local Environment Setup

**Purpose:** Establish baseline — app runs locally with all services connected before decoupling begins.

**CODE:**

```bash
# Step 1: Check tools
node --version        # must be 22+
supabase --version    # must be installed
vercel --version      # must be installed

# Step 2: Create .env.local
cat > .env.local << 'EOF'
VITE_SUPABASE_URL=https://[project-ref].supabase.co
VITE_SUPABASE_ANON_KEY=[anon key from Supabase dashboard]
VITE_SUPABASE_FUNCTIONS_URL=https://[project-ref].supabase.co/functions/v1
VITE_SITE_URL=http://localhost:5173
EOF

# Step 3: Add to .gitignore
grep ".env.local" .gitignore || echo ".env.local" >> .gitignore

# Step 4: Install and run
npm install
npm run dev
```

**RUN:**

```bash
npm install && npm run dev
```

**VERIFY:** Run all 6 local checklist items:

- [ ] App loads at `http://localhost:5173` — no console errors
- [ ] Supabase connected — Network tab shows 200 responses from `supabase.co`
- [ ] Supabase auth — Sign In redirects to OAuth and returns successfully
- [ ] AI Chat — Test message streams response, Network shows `functions/v1/chat` request
- [ ] Build completes — `npm run build` succeeds, `dist/` created
- [ ] No console errors in browser dev tools

**REPORT:**

**PASS:**

```
Local environment ready. All services connected. Baseline confirmed.
Supabase ✓ OAuth ✓ AI Chat ✓ Build ✓
```

**FAIL:**

```
Local environment failed at: [which check]
Error: [message from console or terminal]
Fix required before decoupling begins.
```

---

## REUSABLE COMMANDS

```bash
# Quick Lovable check
grep -r "@lovable.dev" package.json && echo "LOVABLE FOUND" || echo "CLEAN"

# Clear TanStack caches
rm -rf .tanstack node_modules/.vite dist

# Test production build
npm run build && npm run preview
```
