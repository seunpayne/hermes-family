---
name: site-reviewer
description: Clone, analyze, and modify GitHub repositories with safe staging workflow, autoskills detection, and comprehensive audits. Use when reviewing existing codebases or making changes to deployed sites.
---

# Site Reviewer Skill

## Activation Checklist

When this skill is loaded/activated:

1. **Check Git** - Run `git --version`. If missing, install via `xcode-select --install`
2. **Confirm workspace** - Ensure `~/Projects/reviews` exists. Create if not: `mkdir -p ~/Projects/reviews`
3. **Install Deploy Kit** - Run `clawhub install hugosbl/deploy-kit`. If already installed, skip.
4. **Say**: "site-reviewer loaded. Send me a GitHub URL."

## When Receiving a GitHub URL

### Step 1: Clone the Repository

```bash
cd ~/Projects/reviews
git clone [GitHub URL]
cd [repo-name]
```

### Step 2: Run Autoskills Immediately

```bash
npx autoskills
```

This detects the stack and installs the most relevant skills for that specific codebase automatically.

**⚠️ AUTOSKILLS TIMEOUT HANDLING:**

Autoskills can timeout (60s default) on large codebases with many dependencies. If you see:

```
[Command timed out after 60s]
```

**This is OK. Do NOT retry.** The technology detection runs before the timeout completes.

**What was still captured:**
- Technology list printed in the output (e.g., "✔ React", "✔ TypeScript", "✔ Supabase")
- `skills-lock.json` written to project root with detected skills
- Combo detections (e.g., "⚡ React + shadcn/ui")

**What to do:**
1. Read the printed technology list from the timeout output
2. Check `skills-lock.json` for the full detection results
3. Proceed with manual analysis using the detected stack
4. Do NOT run autoskills again — it will timeout again

**Example from Omayoza session:**
```
✔ React             ✔ Tailwind CSS      ✔ shadcn/ui
✔ TypeScript        ✔ React Hook Form   ✔ Zod
✔ Supabase          ✔ TanStack Start    ✔ Vite
✔ Cloudflare        ✔ Bun               ✔ Node.js
```

Use this list to guide your analysis in Step 3.

**⚠️ PACKAGE MANAGER FALLBACK:**

If the project has a lockfile for a package manager that isn't installed (e.g., `bun.lockb` but Bun isn't available), fall back to the system's available package manager:

```bash
# If bun.lockb exists but bun is not installed:
npm install  # Works fine, ignores bun.lockb
```

This is safe — npm will install the same dependencies from `package.json`. The lockfile mismatch may result in slightly different versions, but the project will work. You can regenerate the appropriate lockfile later if needed.

**⚠️ AUTOSKILLS TIMEOUT HANDLING:**

Autoskills can timeout (60s default) on large codebases with many dependencies. If you see:

```
[Command timed out after 60s]
```

**This is OK. Do NOT retry.** The technology detection runs before the timeout completes.

**What was still captured:**
- Technology list printed in the output (e.g., "✔ React", "✔ TypeScript", "✔ Supabase")
- `skills-lock.json` written to project root with detected skills
- Combo detections (e.g., "⚡ React + shadcn/ui")

**What to do:**
1. Read the printed technology list from the timeout output
2. Check `skills-lock.json` for the full detection results
3. Proceed with manual analysis using the detected stack
4. Do NOT run autoskills again — it will timeout again

**Example from Omayoza session:**
```
✔ React             ✔ Tailwind CSS      ✔ shadcn/ui
✔ TypeScript        ✔ React Hook Form   ✔ Zod
✔ Supabase          ✔ TanStack Start    ✔ Vite
✔ Cloudflare        ✔ Bun               ✔ Node.js
```

Use this list to guide your analysis in Step 3.

### Step 2b: ENV VAR INJECTION PHASE (Review Existing Repo)

**Say:** "Detecting required environment variables for this stack..."

**Check existing Vercel env vars before injecting:**
```bash
vercel env ls
```

**Read the `stack` field from Supabase `projects` table** and identify required environment variables using the same `envVarMap` as web-builder.

**For each required variable:**
- **If already exists in Vercel:** skip it and log that it was already present
- **If missing:** inject it following the web-builder sequence

**Match against available credentials:** Check `~/.env.openclaw` for each missing variable.

**If any variables are missing:** Display the names and say: "The following environment variables are required but not configured: [list]. Add them to auth-manager or provide values now. Type SKIP to deploy without them — the project will fail to connect to those services until they are added."

**If SKIP:** log missing variables as risks in handoff artifact.

**Inject into Vercel:** For each ready variable that's missing:
```bash
vercel env add [VARIABLE_NAME] production <<< "[value]"
vercel env add [VARIABLE_NAME] preview <<< "[value]"
vercel env add [VARIABLE_NAME] development <<< "[value]"
```

**Never display variable values in chat or logs.**

**Verify injection:** Run `vercel env ls` and compare against required list. Retry once if any missing, then escalate to Seun.

**Create local .env file:** Write `.env.local` at project root with all injected variables.

**Add to .gitignore:**
```bash
echo ".env.local" >> .gitignore
echo ".env*.local" >> .gitignore
```

**Log to Supabase:**
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

**Say:** "Environment variables checked. [X] new variables configured across development, preview, and production. .env.local created for local development."

### Step 3: Analyze the Codebase

Identify and document:

- **Framework** - Next.js, React, Vue, Svelte, Astro, vanilla, etc.
- **Tech stack** - TypeScript/JavaScript, CSS framework, state management, etc.
- **Folder structure** - Key directories and their purposes
- **Third-party dependencies** - Read `package.json`, `requirements.txt`, etc.
- **Deployment configuration** - `vercel.json`, `netlify.toml`, Dockerfile, CI/CD configs

### Step 4: Apply Specialized Skills

Based on what autoskills detected:

- **If Supabase detected:** Pull and apply `supabase-performance` skill
- **Always:** Pull and apply `seo-audit` skill and run a full audit on the existing codebase
- **Always:** Pull and apply `security-review` skill and flag any vulnerabilities

### Step 5: Map Files and Directories

For each major file/directory, note:

- Entry points (`index.html`, `src/main.tsx`, `pages/`, `app/`)
- Component libraries
- API routes or backend code
- Configuration files
- Static assets

### Step 6: Generate Summary

Present a plain English summary covering:

```markdown
## Site Summary: [Repo Name]

### What It Does
[Description of the site's purpose and functionality]

### How It's Built
- **Framework:** [Name + version]
- **Stack:** [Key technologies]
- **Deployment:** [Vercel, Netlify, etc.]

### What Can Be Easily Modified
- [List of simple changes: copy, colors, images, etc.]

### What Requires Deeper Work
- [List of complex changes: architecture, backend, database, etc.]

### SEO Status
[Summary from seo-audit skill]

### Security Issues
[Summary from security-review skill]

### Noted Issues
[Any other problems found: outdated deps, errors, inconsistencies]
```

### Step 7: Say

"Site understood. Send me your modification instructions."

## When Modification Instructions Are Received

### Step 1 — Assign Addendum Number

**Check if this is the first modification for this project:**
- If yes: assign it **ADDENDUM 001**
- If no: query Supabase `agent_runs` table to find the last addendum number for this project and increment by 1

### Step 2 — Format the Addendum

Format the modification as a structured addendum before making any changes:

```markdown
# [CLIENT NAME] — ADDENDUM [NUMBER]
## [BRIEF TITLE OF WHAT THIS CHANGES]
## Applies to: [SECTION / COMPONENT / PAGE NAME]

CONTEXT:
[Why this change is needed — 1–2 sentences]

CHANGE:
[Precise description of what to build, change, or fix]
[Exact copy, hex values, class names, SQL, or file paths where relevant]

DO NOT CHANGE:
[Everything adjacent that must not be touched]

AFTER IMPLEMENTING:
[What to test or verify to confirm the change worked correctly]
```

### Step 3 — Display and Wait

**Display the formatted addendum to Seun.**

**Say:** "Addendum [NUMBER] ready. Review below. Type APPROVE to implement or request changes to the addendum first."

**Wait for APPROVE before touching any files.**

### Step 4 — On APPROVE

1. **Create the staging branch:** `git checkout -b staging-[date]-addendum-[number]`
2. **Implement exactly what the CHANGE section specifies**
3. **Touch nothing listed in DO NOT CHANGE**
4. **Run the verification steps in AFTER IMPLEMENTING**
5. **Save the addendum to:** `~/Projects/clients/[client-name]/addenda/addendum-[number].md`
6. **Log the addendum as a decision in Supabase**
7. **Deploy to Vercel staging for review**

---

## Standing Addendum Rules

- **Never implement a modification via conversation** — always format as an addendum first
- **Never edit a previous addendum** — write a new one
- **If the same area has been modified before:** read the previous addendum for that area and include relevant DO NOT CHANGE items automatically
- **Number addenda sequentially per client project** — never reset
- **All addenda saved to disk and logged to Supabase**

---

## When Staging Is Approved

### Step 1: Merge to Main

```bash
git checkout main
git merge staging-[date]-addendum-[number]
```

### Step 2: Deploy to Production with Deploy Kit

- Deploy Kit executes production deployment
- Capture the production URL

### Step 3: Push to GitHub

```bash
git push origin main
```

### Step 4: Update Registry

Update `~/Projects/registry.json` with:

- Repo name
- Changes made (summary)
- Staging URL
- Production URL
- Date of deployment
- Addendum number

## Safety Rules

- **NEVER** push to production without explicit approval after staging review
- **ALWAYS** work on a staging branch first
- **ALWAYS** confirm changes before modifying files
- **ALWAYS** run autoskills immediately after cloning
- **ALWAYS** run seo-audit and security-review on every codebase
- If something breaks on staging, fix it before merging

## Notes

- Handle merge conflicts carefully - ask user if unsure
- Keep commit messages descriptive
- If the repo isn't connected to Vercel, run `vercel link` first
- Deploy Kit handles deployment configuration automatically

## Lovable Dependency Removal

If you encounter a project generated by Lovable (lovable.dev), it will contain proprietary dependencies that lock the project to their platform. 

**See:** `references/lovable-migration.md` for the complete migration pattern covering:
- Removing `@lovable.dev/vite-tanstack-config` → standard Vite config
- Removing `@lovable.dev/cloud-auth-js` → Supabase native OAuth
- Removing Lovable AI Gateway → direct API (Groq, OpenAI, Anthropic)
- Verification checklist and common pitfalls
