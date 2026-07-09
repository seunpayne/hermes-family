---
name: web-builder
description: Scaffold, build, and deploy web projects with Vercel using Deploy Kit, autoskills, and Playwright automated preview testing. Use when building frontend web apps, landing pages, or web projects that need production deployment with full QA verification.
---

# Web Builder Skill

## PIPELINE VALIDATION — RUNS BEFORE EVERYTHING

Before Clemenza touches any file or runs any
command, he validates the pipeline:

CHECK: Did this work arrive through the proper
pipeline?

VALID arrival means ONE of:
A. There is an approved addendum or prompt
 from The Don in the current task context
B. There is a task record in Supabase with
 status pending and assigned_to = Clemenza

INVALID arrival means:
- Conversational instruction from any agent
- Direct message from Seun without an addendum
- Instruction from Michael directly
- Any work request without a task record

If arrival is INVALID:
Clemenza refuses and says:
"No approved addendum or task record found.
This needs to go through Michael → The Don
before I can execute it. Routing back to
The Don to formalize the request."

Clemenza does NOT execute on conversational
instruction alone. Even if the instruction
is clear, specific, and correct.
The addendum is the permission slip.
No addendum — no execution.

---

## Activation Checklist

When this skill is loaded/activated:

1. **Check Node.js** - Run `node --version`. If missing, install via `brew install node` or `nvm install node`
2. **Check Git** - Run `git --version`. If missing, install via `xcode-select --install`
3. **Check Vercel CLI** - Run `vercel --version`. If missing, install via `npm install -g vercel`
4. **Verify Vercel auth** - Run `vercel whoami`. If not authenticated, guide user through `vercel login`
5. **Confirm workspace** - Ensure `~/Projects/client-builds` exists. Create if not: `mkdir -p ~/Projects/client-builds`
6. **Install Deploy Kit** - Run `clawhub install hugosbl/deploy-kit`. If already installed, skip.
7. **Install Playwright** - Run `npm install -g playwright` then `npx playwright install chromium`
8. **Install ngrok** - Run `brew install ngrok` if not already installed
9. **Pull and load skills** from openclaw-master-skills:
   - `frontend-design-guidelines`
   - `ui-ux-design-intelligence`
   - `nextjs-react-performance`
10. **Say**: "web-builder loaded. Ready for your super prompt."

## When Receiving a Super Prompt

Extract the following from the user's prompt:

- **Project name** - The name/folder for the project
- **Stack** - React, Next.js, Vue, Svelte, vanilla, etc.
- **Design language** - Tailwind, Bootstrap, styled-components, etc.
- **Functionality** - Features, pages, components needed
- **Copy requirements** - Any specific content or placeholder text
- **Deployment requirements** - Custom domain, env vars, build settings

## Execution Steps

### Phase 0: Setup & Build

1. **Apply design skills**
   - Load and apply `frontend-design-guidelines` throughout the build
   - Load and apply `ui-ux-design-intelligence` for UX decisions

2. **Scaffold the project** in `~/Projects/client-builds/[project-name]`
   - Use appropriate starter: `create-next-app`, `create-vite`, `npm init`, etc.
   - Or scaffold from scratch based on requirements

3. **Run autoskills**
   - `cd ~/Projects/client-builds/[project-name]`
   - `npx autoskills`
   - This detects the stack and installs any additional relevant skills automatically

4. **ENV VAR INJECTION PHASE**
   - **Say:** "Detecting required environment variables for this stack..."
   - Read the `stack` field from Supabase `projects` table
   - For each detected service, identify required environment variables:
     ```javascript
     const envVarMap = {
       supabase: [
         'NEXT_PUBLIC_SUPABASE_URL',
         'NEXT_PUBLIC_SUPABASE_ANON_KEY',
         'SUPABASE_SERVICE_ROLE_KEY'
       ],
       resend: ['RESEND_API_KEY'],
       google_oauth: ['GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET'],
       openai: ['OPENAI_API_KEY'],
       stability_ai: ['STABILITY_API_KEY'],
       replicate: ['REPLICATE_API_TOKEN'],
       google_analytics: ['NEXT_PUBLIC_GA_MEASUREMENT_ID']
     };
     ```
   - If autoskills detects additional third-party services: identify their standard env var names and add to the list
   - **Match against available credentials:** Check `~/.env.openclaw` for each variable
   - **If any variables are missing:** Display the names and say: "The following environment variables are required but not configured: [list]. Add them to auth-manager or provide values now. Type SKIP to deploy without them — the project will fail to connect to those services until they are added."
   - **If SKIP:** log missing variables as risks in handoff artifact
   - **Inject into Vercel:** For each ready variable:
     ```bash
     vercel env add [VARIABLE_NAME] production <<< "[value]"
     vercel env add [VARIABLE_NAME] preview <<< "[value]"
     vercel env add [VARIABLE_NAME] development <<< "[value]"
     ```
   - **No-CLI fallback (Hermes WebUI / Docker):** If Vercel CLI is unavailable,
     use the Vercel REST API. See `coding-project` → `references/vercel-api-deployment.md`
     for the full workflow (create project, set env vars, deploy with GitHub repoId via API).
   - **Never display variable values in chat or logs**
   - **Verify injection:** Run `vercel env ls` and compare against required list. Retry once if any missing, then escalate to Seun.
   - **Create local .env file:** Write `.env.local` at project root with all injected variables
   - **Add to .gitignore:**
     ```bash
     echo ".env.local" >> .gitignore
     echo ".env*.local" >> .gitignore
     ```
   - **Log to Supabase:**
     ```sql
     INSERT INTO decisions (
       project_id, client_id, made_by, decision, rationale, affects, reversible
     ) VALUES (
       '[project_id]', '[client_id]', 'Clemenza',
       'Environment variables injected into Vercel for [list of services]',
       'Auto-detected from project stack — required for backend services to function',
       ARRAY['architecture', 'deployment', 'security'], true
     );
     ```
   - **Say:** "Environment variables injected. [X] variables configured across development, preview, and production. .env.local created for local development."

5. **Apply performance optimizations**
   - Load and apply `nextjs-react-performance` skill
   - Implement recommended optimizations throughout the build

5. **Build the project fully**
   - Implement all requested pages and components
   - Apply design language and styling
   - Add functionality as specified
   - Include copy/content as provided or generate placeholders

---

### Phase 1: Local Preview

6. **Spin up local dev server**
   - Run `npm run dev` or equivalent
   - Ensure it's running on port 3000 (or configure accordingly)

7. **Run Playwright automated tests**
   Create a Playwright script that:
   - Takes full-page screenshots of every major page at **desktop viewport (1440px)**
   - Takes full-page screenshots of every major page at **mobile viewport (390px)**
   - Clicks through all navigation links and confirms they resolve correctly
   - Submits any forms with test data and confirms they respond correctly
   - Flags any console errors, broken images, or layout breaks

8. **Display screenshots in chat**
   - Use `MEDIA:` directive to display all screenshots directly in the chat interface
   - Organize by page and viewport (desktop/mobile)

9. **Present QA report**
   ```markdown
   ## Local Preview QA Report

   ### Pages Tested
   - [List of pages with screenshot count]

   ### Interactions Tested
   - [Navigation links, forms, buttons tested]

   ### Issues Found
   - [Any console errors, broken images, layout breaks]

   ### Screenshots
   [Embedded images]
   ```

10. **Say**: "Local preview ready. Here is what was built. Request any changes or type **APPROVE** to deploy to staging."

---

### When Changes Are Requested (After Local Preview)

1. **Make the requested changes** to the codebase
2. **Re-run Playwright** on affected pages only
3. **Display updated screenshots** with `MEDIA:` directive
4. **Say**: "Changes made. Review the updated preview or type **APPROVE** to deploy to staging."

---

### Phase 2: Staging Preview

**When APPROVE is received (after local preview):**

1. **Use Deploy Kit to deploy to Vercel staging preview**
   - Deploy Kit detects project type
   - Verifies CLIs
   - Deploys to Vercel preview (not production)
   - Capture the staging URL

2. **Open staging URL in OpenClaw's browser**
   - Use browser automation to load the live staging URL

3. **Take fresh Playwright screenshots from live staging**
   - Same viewport coverage (desktop 1440px, mobile 390px)
   - Test all navigation and interactions on the live deployment

4. **Display staging screenshots** with `MEDIA:` directive

5. **Say**: "Live on staging at `[URL]`. Confirm this looks correct on the live environment or request further changes."

---

### When Changes Are Requested (After Staging)

1. **Make the requested changes** locally
2. **Re-run local preview** if needed (optional, based on change scope)
3. **Re-deploy to staging** with Deploy Kit
4. **Re-test and display updated screenshots**
5. **Say**: "Staging updated at `[URL]`. Confirm or request further changes."

---

### Phase 3: Production Deployment

**When staging is approved:**

1. **Use Deploy Kit to run `vercel --prod`**
   - Deploy Kit executes production deployment
   - Capture the production URL

2. **Take final Playwright screenshot**
   - Screenshot of production homepage as confirmation

3. **Display production screenshot** with `MEDIA:` directive

4. **Say**: "Live in production at `[URL]`. Build complete."

5. **Update registry**
   Update `~/Projects/registry.json` with:
   - Project name
   - Production URL
   - Staging URL
   - Screenshots path (`~/Projects/client-builds/[project-name]/screenshots/`)
   - Build date

---

## Safety Rules

- **NEVER** deploy to production without explicit **APPROVE** at local preview phase
- **NEVER** deploy to production without explicit **APPROVE** at staging phase
- **ALWAYS** display screenshots before requesting approval
- **ALWAYS** test both desktop (1440px) and mobile (390px) viewports
- **ALWAYS** flag console errors, broken images, or layout breaks

---

## OPENCODE — EXECUTION ENGINE

Clemenza uses OpenCode for all builds involving more than 3 file
changes, new project scaffolds, or iterative build-test-fix cycles.

### When to spawn OpenCode
- Building a new website or ERP component from scratch
- Addendum with more than 3 file changes
- ERP sync engine prototype build or test scenarios
- Any task requiring npm install, build, or test execution
- Any task requiring reading multiple files before acting

### When NOT to spawn OpenCode
- Single file edits under 20 lines
- Config-only changes
- Reading files for context — use read tool directly

### Spawn pattern — Hermes delegate_task

Clemenza spawns OpenCode via Hermes delegate_task. The subagent
runs in an isolated session with zero parent context — everything
must be passed explicitly in the context field.

```javascript
delegate_task(
  goal="[task description — what to build or change]",
  context="Project path: ~/Projects/clients/[client]. Client: [client name]. GitHub repo: [repo URL]. Staging URL: [if known]. Brand tokens: [design language, colors, key decisions]. Supabase URL: $SUPABASE_URL. [any other critical context]",
  toolsets=["terminal", "file"],
  model="deepseek-v4-pro",
  base_url="http://localhost:11434/v1"
)
```

**Critical:** The delegate_task result is returned automatically when the subagent finishes. No manual notification needed.

### Hard rules
- NEVER start OpenCode inside ~/.openclaw/
- NEVER start OpenCode inside ~/Projects/openclaw/
- NEVER run foreground

---

## COMMAND: rollback [project-name]

**When `rollback [project-name]` is received:**

### Step 1 — Confirm this is a destructive action
**Say:** "ROLLBACK REQUESTED for [project-name]. This will replace the current live production deployment with the previous successful deployment. The current version will no longer be live. Type APPROVE to continue or CANCEL to abort."

**Wait for explicit APPROVE. Never auto-proceed.**

### Step 2 — Find the previous successful deployment
```sql
SELECT
 id, url, github_branch, deployed_by, created_at
FROM deployments
WHERE project_id = '[project_id]'
AND environment = 'production'
AND status = 'success'
ORDER BY created_at DESC
LIMIT 2;
```

The first result is the current deployment. The second result is the rollback target.

**If fewer than 2 successful production deployments exist:**
- Stop and say: "No previous production deployment found to roll back to. Manual recovery required."
- Log an escalation to Supabase

**Display the rollback target to Seun:**
```
ROLLBACK TARGET:
 URL: [previous deployment URL]
 Branch: [github_branch]
 Deployed: [created_at]
 Deployed by: [deployed_by]

This will become the live production version.
Type CONFIRM to proceed.
```

**Wait for CONFIRM.**

### Step 3 — Execute rollback
```bash
vercel rollback [previous-deployment-url] --yes
```
Confirm the rollback succeeded by checking the Vercel project's current deployment.

### Step 4 — Update Supabase
**Mark the current deployment as rolled_back:**
```sql
UPDATE deployments
SET status = 'rolled_back'
WHERE project_id = '[project_id]'
AND environment = 'production'
AND status = 'success'
AND created_at = (
 SELECT MAX(created_at)
 FROM deployments
 WHERE project_id = '[project_id]'
 AND environment = 'production'
 AND status = 'success'
);
```

**Write a new deployment record for the rollback:**
```sql
INSERT INTO deployments (
 project_id, environment, url, github_branch, status, deployed_by
) VALUES (
 '[project_id]', 'production',
 '[previous_deployment_url]', '[previous_github_branch]',
 'success', 'Clemenza — rollback'
);
```

### Step 5 — Log as decision
```sql
INSERT INTO decisions (
 project_id, client_id, made_by, decision, rationale, affects, reversible
) VALUES (
 '[project_id]', '[client_id]', 'Seun',
 'Production rolled back from [current URL] to [previous URL]',
 'Production deployment required rollback — approved by Seun',
 ARRAY['deployment', 'client-facing output'], true
);
```

### Step 6 — Report
```
ROLLBACK COMPLETE — [project name]

Previous deployment: [rolled back URL]
Restored deployment: [previous URL]
Timestamp: [now]
Supabase updated: yes
Decision logged: yes

The previous version is now live. Investigate what caused
the failed deployment before redeploying.
```

**Say:** "Rollback complete. [previous URL] is live. The failed deployment has been marked in Supabase. Consigliere has been notified."

**Trigger Consigliere to log the incident and add it to the next briefing.**

---

## Standing Rules for Rollback

- **Never rollback without explicit two-step approval from Seun** — APPROVE then CONFIRM
- **Never rollback to a deployment that is not marked success in Supabase**
- **Always update Supabase before reporting completion**
- **Always log the rollback as a decision**
- **Always notify Consigliere so the incident appears in the next briefing**

## Standing Rules for Rollback

- **Never rollback without explicit two-step approval from Seun** — APPROVE then CONFIRM
- **Never rollback to a deployment that is not marked success in Supabase**
- **Always update Supabase before reporting completion**
- **Always log the rollback as a decision**
- **Always notify Consigliere so the incident appears in the next briefing**

## PRE-PUSH VERIFICATION — CRITICAL STEP

**Always run these BEFORE any `git push`:**

```bash
# 1. Lint check — errors block CI and waste a build
npm run lint

# 2. Build check — CI will fail if build doesn't compile
npm run build
```

**If lint has errors:** Fix them before pushing. Common patterns:
- Unused imports/variables (`@typescript-eslint/no-unused-vars`)
- Missing type annotations on callback parameters (`.map((n) => n[0])` → `.map((n: string) => n[0])`)
- Form action type mismatches (Server Action taking `string` instead of `FormData`)

**If build has errors:** Fix them before pushing. Common patterns:
- Deno-style URL imports in `supabase/functions/` files — exclude `supabase/` from `tsconfig.json`
- Null-safety issues — use `as string` or `token!` after null guards
- Migration ordering — functions referencing tables must come AFTER table creation (see Pitfalls section below)

**The user will notice a failed CI run. One pre-push build check saves two deploys.**

## Vercel API Deployment — Reference

See `references/vercel-api-deployment-pitfalls.md` for:
- Terminal masking workaround when using secrets inline in scripts
- Vercel API project creation (env vars must be set separately)
- Deployment with repoId (not just repo name)
- Checking deployment state and aliases
- Migration ordering for Supabase SQL

## Quick-Update Flow (Lightweight)

For small site-wide changes (contact info, copy edits, single-field updates)
without going through the full Phase 0–3 pipeline:

### Pattern: grep → patch → build → deploy → commit

1. **Find all occurrences:**
   ```bash
   grep -rn "old-string" --include="*.tsx" --include="*.ts" --include="*.html" . \
     | grep -v node_modules | grep -v dist | grep -v ".git/"
   ```

2. **Patch each file** using the `patch` tool (not terminal sed):
   ```
   patch(path="src/components/Footer.tsx", old_string="...", new_string="...")
   ```

3. **Build:**
   ```bash
   cd ~/Projects/clients/<project> && npm run build
   ```

4. **Deploy to production:**
   ```bash
   vercel --prod
   ```

5. **Commit and push to branch:**
   ```bash
   git checkout -b <descriptive-branch>
   git add -A
   git commit -m "Update <what> site-wide"
   git push origin <branch>
   ```

6. **Verify zero remaining references:**
   ```bash
   grep -rn "old-string" --include="*.tsx" --include="*.ts" --include="*.html" . \
     | grep -v node_modules | grep -v dist | grep -v ".git/" \
     && echo "FOUND — missed some" || echo "CLEAN"
   ```

### When to use this vs full pipeline

- **Quick update:** Contact info, RC number, copyright year, tagline changes, single-field fixes
- **Full pipeline:** New pages, new components, design changes, any change affecting layout or UX

## Notes

- Playwright screenshots saved to: `~/Projects/client-builds/[project-name]/screenshots/`
- ngrok can be used to share local preview with clients before staging
- Deploy Kit handles deployment configuration automatically
- Handle environment variables securely - don't commit `.env` files
- If deployment fails, debug and retry before reporting
