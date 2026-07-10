# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

# STACK PLAYBOOK: Website — React/Vite + TanStack Router + Tailwind v4 + Supabase + Vercel
# Version: 1.0
# Derived from: TMG Capital and Foremost Capital builds (May 2026)
# Michael reads this before generating task CODE sections
# for any website or web app project.

---

## STACK IDENTITY

```
Framework:    React (Vite)
Router:       TanStack Router
Styling:      Tailwind CSS v4
Database:     Supabase (Postgres + Auth + Realtime)
Email:        Resend
Deployment:   Vercel (SSR or static)
CI/CD:        GitHub Actions
Testing:      Playwright (E2E) + Vitest (unit)
Performance:  Lighthouse CI
Security:     Fredo (trufflehog + observatory-cli + npm audit)
```

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **Tailwind v4 uses CSS-first config.**
   No tailwind.config.js. Configuration is in CSS via `@theme`.
   Import: `@import "tailwindcss"` in main CSS file.
   Do not generate a tailwind.config.js — it is not used in v4.

2. **All secrets in Vercel env vars — never in .env committed to repo.**
   `.env.local` for local development only.
   `.gitignore` must include: `.env`, `.env.local`, `.env.*.local`
   Supabase service role key goes in Vercel environment variables only.
   Never VITE_SUPABASE_SERVICE_ROLE — that would expose it in the bundle.

3. **VITE_ prefix required for client-side env vars.**
   Variables available in React code must be prefixed VITE_.
   Example: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
   Read in code as: `import.meta.env.VITE_SUPABASE_URL`

4. **Fredo must scan before every git push.**
   Pre-push scan: trufflehog, .gitignore check, npm audit.
   No push proceeds without Fredo CLEAR.

5. **GitHub push mandatory on every project.**
   Every project has a private GitHub repo.
   Every addendum is committed with a descriptive message.
   Vercel connected to GitHub — redeploys on push to main.

6. **Addendum discipline — no verbal modifications.**
   Every post-build change is a numbered addendum.
   Addendum format: [CLIENT] — ADDENDUM [N]
   Sections: CONTEXT / CHANGE / DO NOT CHANGE / AFTER IMPLEMENTING

7. **project_brand is written before any visual work.**
   The Don writes to project_brand table after parsing the brief.
   Apollonia reads from project_brand first — not from the super prompt.
   Kay reads from project_brand for tone and voice.
   Clemenza reads from project_brand for design tokens.

8. **Mobile viewport must be tested.**
   Every build is tested at desktop (1440px) and mobile (390px).
   Playwright takes full-page screenshots at both viewports.
   Mobile layout must pass before staging approval.

9. **TanStack Router uses file-based routing.**
   Routes defined in `src/routes/` as `.tsx` files.
   Root route: `src/routes/__root.tsx`
   Index route: `src/routes/index.tsx`
   Named routes: `src/routes/about.tsx`, `src/routes/contact.tsx`

10. **Contact forms use Supabase, not third-party forms.**
    Form submissions insert to Supabase table.
    Resend sends confirmation email via Supabase Edge Function or
    server action. Never expose service role key in client code.

---

## SCAFFOLD

```bash
# Create Vite + React + TypeScript project
npm create vite@latest [project-name] -- --template react-ts
cd [project-name]

# Install TanStack Router
npm install @tanstack/react-router

# Install TanStack Router Vite plugin (file-based routing)
npm install --save-dev @tanstack/router-plugin

# Install Tailwind CSS v4
npm install tailwindcss @tailwindcss/vite

# Install Supabase client
npm install @supabase/supabase-js

# Install Resend (if email needed)
npm install resend

# Install Framer Motion (for animations)
npm install framer-motion

# Install React Hook Form + Zod (for forms)
npm install react-hook-form zod @hookform/resolvers

# Install intl-tel-input (for phone fields)
npm install intl-tel-input

# Install testing
npm install --save-dev vitest @vitest/coverage-v8 playwright @playwright/test
npm install --save-dev @playwright/test lighthouse

# Initialise Playwright
npx playwright install chromium
```

---

## REQUIRED CONFIG FILES

**vite.config.ts**
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    TanStackRouterVite(),
    react(),
    tailwindcss(),
  ],
})
```

**src/styles/main.css**
```css
@import "tailwindcss";

@theme {
  --color-bg-base: [from project_brand.bg_base];
  --color-bg-surface: [from project_brand.bg_surface];
  --color-accent: [from project_brand.accent_primary];
  --color-text-primary: [from project_brand.text_primary];
  --color-text-secondary: [from project_brand.text_secondary];
  --font-primary: '[from project_brand.font_primary]', sans-serif;
}
```

**src/routes/__root.tsx**
```tsx
import { createRootRoute, Outlet } from '@tanstack/react-router'
import { Nav } from '../components/Nav'
import { Footer } from '../components/Footer'

export const Route = createRootRoute({
  component: () => (
    <>
      <Nav />
      <Outlet />
      <Footer />
    </>
  ),
})
```

**src/routes/index.tsx**
```tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: HomePage,
})

function HomePage() {
  return <main>Home page content</main>
}
```

**.env.local** (never commit)
```
VITE_SUPABASE_URL=https://[project-ref].supabase.co
VITE_SUPABASE_ANON_KEY=[anon key]
```

**.gitignore** (must include)
```
.env
.env.local
.env.*.local
node_modules
dist
.vercel
```

**vitest.config.ts**
```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    coverage: {
      provider: 'v8',
      threshold: { lines: 70 }
    }
  }
})
```

---

## SUPABASE PATTERNS

### Client initialisation
```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

### Contact form submission
```typescript
// Submit form to Supabase
const { error } = await supabase
  .from('contact_submissions')
  .insert({
    name: data.name,
    email: data.email,
    message: data.message,
    created_at: new Date().toISOString()
  })

if (error) {
  console.error('Submission failed:', error)
  setSubmitError('Something went wrong. Please try again.')
  return
}
setSubmitSuccess(true)
```

### Supabase table for contact forms
```sql
CREATE TABLE contact_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  message text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can insert" ON contact_submissions
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role reads" ON contact_submissions
  FOR SELECT USING (auth.role() = 'service_role');
```

---

## VERCEL DEPLOYMENT PATTERNS

### Initial deployment
```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy to staging (preview)
vercel

# Deploy to production
vercel --prod
```

### Environment variables in Vercel
```bash
# Add via CLI
vercel env add VITE_SUPABASE_URL production
vercel env add VITE_SUPABASE_ANON_KEY production
vercel env add SUPABASE_SERVICE_ROLE_KEY production  # server-side only

# Or add via Vercel dashboard:
# Project → Settings → Environment Variables
```

### vercel.json (for SPA routing)
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### Custom domain
```bash
vercel domains add [domain.com]
vercel domains verify [domain.com]
```

---

## GITHUB ACTIONS CI TEMPLATE

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npx vitest run --coverage

  e2e:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test
        env:
          VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}

  lighthouse:
    runs-on: ubuntu-latest
    needs: e2e
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci && npm run build
      - run: npx lighthouse-ci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

**lighthouserc.json**
```json
{
  "ci": {
    "collect": {
      "staticDistDir": "./dist"
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", {"minScore": 0.8}],
        "categories:accessibility": ["error", {"minScore": 0.9}]
      }
    }
  }
}
```

---

## PLAYWRIGHT TEST PATTERNS

**playwright.config.ts**
```typescript
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:5173',
  },
  projects: [
    {
      name: 'Desktop',
      use: { viewport: { width: 1440, height: 900 } }
    },
    {
      name: 'Mobile',
      use: { viewport: { width: 390, height: 844 } }
    }
  ]
})
```

**Standard page test**
```typescript
// tests/e2e/homepage.spec.ts
import { test, expect } from '@playwright/test'

test('homepage loads and nav is visible', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('nav')).toBeVisible()
  await expect(page).toHaveTitle(/[project name]/)
})

test('contact form submits successfully', async ({ page }) => {
  await page.goto('/contact')
  await page.fill('[name="name"]', 'Test User')
  await page.fill('[name="email"]', 'test@example.com')
  await page.fill('[name="message"]', 'Test message')
  await page.click('[type="submit"]')
  await expect(page.locator('[data-testid="success"]')).toBeVisible()
})

test('screenshots at desktop and mobile', async ({ page }) => {
  await page.goto('/')
  await page.screenshot({ path: 'screenshots/home-desktop.png', fullPage: true })
  await page.setViewportSize({ width: 390, height: 844 })
  await page.screenshot({ path: 'screenshots/home-mobile.png', fullPage: true })
})
```

---

## DESIGN TOKEN EXTRACTION FROM PROJECT_BRAND

```typescript
// When reading project_brand from Supabase for CSS generation:
const { data: brand } = await supabase
  .from('project_brand')
  .select('*')
  .eq('project_id', projectId)
  .single()

// Map to CSS custom properties
const cssTokens = `
@theme {
  --color-bg-base: ${brand.bg_base};
  --color-bg-surface: ${brand.bg_surface};
  --color-accent: ${brand.accent_primary};
  --color-text-primary: ${brand.text_primary};
  --color-text-secondary: ${brand.text_secondary};
  --font-primary: '${brand.font_primary}', sans-serif;
  --font-secondary: '${brand.font_secondary}', sans-serif;
}
`
```

---

## FREDO PRE-PUSH COMMANDS

```bash
# Secret scan
trufflehog filesystem . --only-verified --fail

# Check .env not staged
git status --short | grep "^A.*\.env"

# npm audit
npm audit --audit-level=high

# If all clear: proceed with git push
# If any finding: stop, fix, then push
```

---

## SECURITY HEADERS (required post-staging)

```bash
# Check headers on staging URL
observatory [staging-url] --format json

# Required headers:
# Content-Security-Policy
# Strict-Transport-Security
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY or SAMEORIGIN
# Referrer-Policy
```

---

## STANDARD DIRECTORY STRUCTURE

```
[project-name]/
  src/
    routes/
      __root.tsx          — root layout (Nav + Footer)
      index.tsx           — homepage
      about.tsx
      contact.tsx
      [page].tsx
    components/
      Nav.tsx
      Footer.tsx
      [Component].tsx
    lib/
      supabase.ts
    styles/
      main.css
  tests/
    e2e/                  — Playwright tests
      homepage.spec.ts
      contact.spec.ts
    unit/                 — Vitest tests
  supabase/
    migrations/           — SQL migrations
  screenshots/            — Playwright screenshots
  public/
    logo.png
    favicon.ico
  .env.local              — never committed
  .gitignore
  vite.config.ts
  tsconfig.json
  vitest.config.ts
  playwright.config.ts
  lighthouserc.json
  vercel.json
```

---

## ADDENDUM DISCIPLINE

Every post-build change follows this format exactly:

```markdown
[CLIENT NAME] — ADDENDUM [N]
[Short description]

CONTEXT
[Why this change is needed]

CHANGE
[Exactly what to change. File paths. Component names.
 Specific copy if applicable.]

DO NOT CHANGE
[Explicit list of what must not be touched]

AFTER IMPLEMENTING
[Verification steps — what to check to confirm done]
```

Clemenza executes the addendum.
Fredo scans before pushing.
Clemenza pushes to GitHub.
Vercel redeploys automatically.
Seun reviews on staging.

---

## TASK CODE GENERATION GUIDE
*(Michael reads this section when generating CODE for PRD tasks)*

**Scaffold task:**
Use scaffold commands above.
RUN: `npm run dev`
VERIFY: `curl http://localhost:5173` returns 200.

**New page task:**
Create `src/routes/[page].tsx` using createFileRoute pattern.
Add to Nav component.
RUN: `npm run dev` and navigate to the route.
VERIFY: page renders at correct URL, nav link works.

**Contact form task:**
Use React Hook Form + Zod + Supabase insert pattern.
Create Supabase table using migration SQL.
RUN: `npm run dev`, fill form, submit.
VERIFY: row appears in Supabase dashboard.

**Styling/design task:**
Read project_brand from Supabase for exact tokens.
Never invent colors — only use tokens from project_brand.
RUN: `npm run dev`, visual check at 1440px and 390px.
VERIFY: Playwright screenshots match expected design.

**Deploy to staging task:**
`vercel` (without --prod)
RUN: `vercel`
VERIFY: staging URL loads, all pages return 200.

**Deploy to production task:**
Fredo must be CLEAR first.
RUN: `vercel --prod`
VERIFY: production URL loads, Lighthouse score ≥ 80.

**Fredo scan task:**
RUN: `trufflehog filesystem . --only-verified --fail && npm audit --audit-level=high`
VERIFY: exit code 0, no findings.
REPORT: "CLEAR — no secrets, no critical vulnerabilities" or list findings.
