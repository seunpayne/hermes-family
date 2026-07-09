---
name: coding-project
description: >-
  Full coding project delivery protocol.
  Handles four input types: super prompt, PRD, Figma
  file, and git pull. Manages the complete pipeline
  from intake through production deployment. Use when
  building any app, API, mobile app, or system beyond
  a simple website.
---

# SKILL: coding-project
# Version: 1.3
# Owner: The Don (orchestration)
# Protocol: covers intake through post-delivery
# PRD template: ~/.hermes/templates/prd-template.md

---

## ACTIVATION

Load this skill when:
- Input is a coding project (app, API, mobile, ERP)
- Input type is super prompt, PRD, Figma, or git pull
- Project complexity is medium or above
- Project requires testing, CI/CD, or schema migrations

Do NOT load this skill for:
- Simple website builds (use web-builder)
- Document generation (use doc-builder)
- Image generation only (use designer)

On activation:
- Identify input type
- Route to correct first agent
- Load PRD template path into context
- Say: "Coding project received. Input type: [type].
  Routing to [Michael / Apollonia / Clemenza] for intake."

---

## PIPELINE OVERVIEW

Eight phases. Sequential. No phase skips.

PHASE 0: INPUT RECEPTION
PHASE 1: PRD AND BRIEF SHAPING
PHASE 2: ARCHITECTURE REVIEW
PHASE 3: FOUNDATION BUILD
PHASE 4: FEATURE BUILD (iterative)
PHASE 5: INTEGRATION AND QA
PHASE 6: PRODUCTION DEPLOYMENT
PHASE 7: POST-DELIVERY

---

## PHASE 0 — INPUT RECEPTION

Route based on input type:

Super prompt or PRD:
  → Michael (strategist skill)
  Michael opens PRD template and begins filling

Figma URL or .fig file:
  → Apollonia first (designer skill)
  delegate_task(
    goal="Read Figma file and produce:
    1. Design token inventory (colours, typography,
       spacing, component list)
    2. Component inventory with interaction notes
    3. Recommended tech stack based on design complexity
    4. project_brand fields to populate",
    context="Figma URL: [url]. Project: [name].",
    toolsets=["file", "image_gen"],
    model="anthropic/claude-sonnet-4-6"
  )
  Apollonia's output → Michael for PRD completion

Git pull or GitHub URL:

  **PRE-FLIGHT — Repo access diagnostics:**
  When `git clone` fails, do NOT retry blindly. Run the diagnostic
  chain in `references/github-repo-access-diagnostics.md`:
  web_extract → browser_navigate → env/shell auth audit.
  GitHub returns 404 for private repos to avoid leaking existence
  — verify whether the repo is genuinely missing or just private.

  → Clemenza first (builder skill)
  delegate_task(
    goal="Read the existing codebase and produce:
    1. Tech stack inventory (exact versions)
    2. Architecture summary (how it is structured)
    3. Test coverage report (what is tested today)
    4. Known issues (TODOs, error patterns, tech debt)
    5. Safe-to-touch assessment (what can be modified
       without breaking existing functionality)
    6. What should NOT be touched and why",
    context="Repo: [url or path].
    Task: read only, do not modify anything.",
    toolsets=["terminal", "file"],
    model="deepseek-v4-pro"
  )
  Clemenza's output → Michael for PRD completion

  **PITFALL — Cherry-picking from existing branches:**
  When cherry-picking/merging from a prior branch
  (especially Lovable-originated), ALWAYS verify
  .env before committing: `git diff --cached .env`
  Pre-existing branches often have .env pointing at
  a DIFFERENT Supabase project. Restore the target's
  Supabase URL and only keep genuinely new keys
  (e.g. GROQ_API_KEY) from the cherry-pick.
  Never let a merge swap the database.

  **Project registration prerequisite:**
  Before Phase 1 PRD shaping, the project + client
  MUST exist in the Don's Supabase. Register via
  REST API (see references/project-registration.md).

  **Lovable projects:**
  If the project was originally built with Lovable,
  see references/lovable-decoupling.md for the
  4-dependency decoupling checklist.

  **Uploaded documents (DOCX, PDF, other binary):**
  When the user uploads a structured document file
  (e.g. a .docx PRD), use python-docx to extract
  both paragraphs AND tables:
  ```python
  from docx import Document
  doc = Document('path/to/file.docx')
  # Paragraphs first
  for p in doc.paragraphs:
      if p.text.strip():
          print(f'{p.style.name}|{p.text}')
  # Then tables — these often contain entity definitions,
  # task breakdowns, and requirement tables
  for table in doc.tables:
      for row in table.rows:
          cells = [cell.text.strip() for cell in row.cells]
          print(' | '.join(cells))
  ```
  When the file is .docx, this two-pass approach
  (paragraphs then tables) is the correct method.
  Do NOT use cat/head/pandoc as fallback for docx
  — python-docx gives the most reliable extraction
  including table structure.
  See references/docx-content-extraction.md.

  **PITFALL — Terminal heredoc string corruption with `***`:**  
  When passing strings containing `***` through bash heredocs
  to Python (`<<'PYEOF'`) or Node.js (`-e`), bash expands the
  `***` as glob patterns or env var substitutions, corrupting
  the string before it reaches the interpreter. This causes
  `SyntaxError: unterminated string literal` on lines that
  look syntactically correct.
  
  Fix: Write the script to a file first using `write_file`,
  then execute it with `terminal`. Never pass secrets or
  strings containing `***` through inline `-c` or heredocs.
  For maximum safety, base64-encode sensitive values and
  decode inside the script.

  **PITFALL — Hermes redacts UUID tokens in write_file/terminal:**  
  When writing Railway tokens (UUID format like `f7550ed0-...`) into scripts or
  commands, Hermes replaces them with `***`, breaking string literals and producing
  `SyntaxError: unterminated string literal`. This affects write_file, patch,
  heredocs, and inline Python -c commands.
  
  Workaround:
  - Write token to a separate file via terminal `echo` / `printf`:
    `printf "token-value" > /tmp/railway_token.txt`
  - Read from file at runtime: `with open("/tmp/railway_token.txt") as f: tok = f.read().strip()`
  - Build auth header: `h = "Authorization: Bearer " + tok`
  - Never inline the token in f-strings, concatenation, or shell commands
  
  For the auth header specifically, build it via two shell operations to
  avoid the redaction entirely:
  ```bash
  printf "Authorization: Bearer " > /tmp/auth_hdr.txt
  cat /tmp/railway_token.txt >> /tmp/auth_hdr.txt
  ```
  Then reference as `cat /tmp/auth_hdr.txt` in curl or read() in Python.

---

## PHASE 1 — PRD AND BRIEF SHAPING

Owner: Michael
Template: ~/.hermes/templates/prd-template.md
Output: completed PRD submitted to Seun

Michael fills the PRD template.
**Run the blindspot review** — see `references/prd-review-checklist.md` for the
10-category audit (member flow, communication channel, token lifecycle, admin
roles, storage cost, security, observability, platform limits, SEO, test
practicality). Structure findings as a severity table and present to Seun.
Michael's quality gate must pass before submission.
Seun approves before Phase 2 begins.

Gate 1 completion signal:
  Seun sends "PRD approved" or equivalent
  PRD status updated to APPROVED
  Supabase projects record updated with prd_path

---

## PHASE 2 — ARCHITECTURE REVIEW

Owner: The Don + Clemenza
Output: architecture document, tech stack confirmed

The Don delegates to Clemenza:
delegate_task(
  goal="Produce architecture document for [project].
  Include: system diagram, component breakdown,
  data flow for primary use cases, tech stack
  justification, database schema sketch,
  API design if applicable, risks.",
  context="PRD at [path]. Project: [name].
  Proposed stack: [from PRD Section 5].
  Supabase project: [url].",
  toolsets=["terminal", "file"],
  model="deepseek-v4-pro"
)

Clemenza produces:
  - ARCHITECTURE.md in project root
  - DATABASE.md with schema design
  - API.md if applicable
  - RISKS.md
The Don reviews architecture against PRD.

### Sub-agent JSX balance during UI migration
When sub-agents migrate pages from inline styles to reusable components (Button, Input, Card), they produce unbalanced JSX tags — `<Card>` opens but `</div>` closes instead of `</Card>`. After any page migration, verify: `grep -c '<Card' page.tsx` === `grep -c '</Card' page.tsx`. See `references/jsx-balance-after-migration.md`.
The Don flags any gaps to Seun.
Seun approves before Phase 3.

Gate 2 completion signal:
  Seun sends "Architecture approved"
  Supabase projects record updated
  Architecture docs committed to repo

---

## PHASE 3 — FOUNDATION BUILD

Owner: Clemenza + Fredo
Output: working scaffold with schema, env, CI

Clemenza builds:
delegate_task(
  goal="Build the project foundation:
  1. Scaffold project from approved stack
  2. Configure GitHub Actions CI pipeline
  3. Set up environment variables in Vercel
  4. Run database migrations (schema from ARCHITECTURE.md)
  5. Configure Supabase (tables, RLS, auth if needed)
  6. Set up test framework (Vitest + Playwright)
  7. Write first passing test (smoke test)
  8. Deploy to staging
  9. Confirm staging is accessible",
  context="Project: [name]. Path: [path].
  GitHub repo: [url]. Vercel project: [name].
  Supabase URL: $SUPABASE_URL.
  Stack: [from approved PRD].
  Architecture: [path to ARCHITECTURE.md].",
  toolsets=["terminal", "file"],
  model="deepseek-v4-pro"
)

  **PITFALL — Next.js + Supabase Edge Function colocation causes build failures:**
  When `supabase/functions/` exists in the same repo as a Next.js app, the
  Edge Function TypeScript files (which use Deno imports like
  `import ... from \"https://esm.sh/@supabase/supabase-js@2\"`) will be
  picked up by Next.js's compiler and fail with `Cannot find module` errors.
  The Deno URL-style imports are not resolvable by Next.js/Node.js.

  Fix: Add `\"supabase\"` to the `exclude` array in `tsconfig.json`:
  ```json
  \"exclude\": [\"node_modules\", \"supabase\"]
  ```
  This is safe because Edge Functions are deployed via the Supabase CLI
  (which runs them under Deno, not Node.js), not through Next.js.

  Detection: when `npm run build` produces errors about URL imports
  (`https://esm.sh/...`), check if `supabase/functions/` exists and
  whether `tsconfig.json` excludes it.

  **PITFALL — Large scaffold tasks will timeout at 600s:**
  When the scaffold involves 15+ entities, 10+ modules, or
  multiple deployment configs, the sub-agent will likely hit
  the 600-second timeout. This is expected. Do NOT treat
  timeout as failure.

  Recovery pattern (run these checks after ANY sub-agent returns,
  regardless of timeout or success):
    1. List built files: `find . -maxdepth 3 -not -path '*/node_modules/*' -not -path '*/dist/*' -type f | sort`
    2. Check `prisma/schema.prisma` — verify all PRD entities present
    3. Check package.json — dependencies present
    4. Run `npx prisma generate` — Prisma client must generate
    5. Run `npm run build` — must exit 0
    6. Run `npm test` — all passing
    7. Route prefix audit: sub-agents default to `/health` not `/v1/health`.
       Start app briefly and inspect registered routes to catch this.
    8. Fix broken imports — sub-agents commonly create a file at a new path
       (e.g. `roles.guard.ts`) but some controllers still import from the old path
       (e.g. from `jwt-auth.guard.ts`). Check ALL controller imports.
    9. **Asset verification** — if the user provided image files, icons, or
       other assets, verify EVERY one is referenced in the code:
       ```bash
       # List provided assets
       ls frontend/public/images/icons/
       # Check which are referenced in the page
       grep -oP "(?<=src=\")/images/[^\"]+" page.tsx | sort -u
       ```
       Cross-reference the two lists. Missing assets = sub-agent oversight.
       Also check that asset files are tracked: `git ls-files frontend/public/images/`.
    10. Add missing infrastructure files the sub-agent may have skipped:
        `Procfile`, `ARCHITECTURE_DECISIONS.md`, `README.md`
    11. Rebuild and retest after all fixes
    12. Supabase update: see tracking protocol below

  Split strategy: for very large scaffolds (20+ entities, 15+
  endpoints), delegate Prisma schema + core NestJS as one task,
  and deployment configs + CI pipeline as a follow-up.

**SUPABASE TASK TRACKING PROTOCOL (all phases):**
  CRITICAL — the Don MUST update Supabase for EVERY task,
  regardless of whether the sub-agent timed out or succeeded.

  Before dispatching a sub-agent:
    1. Create the task in Supabase `tasks` table:
       ```
       POST /rest/v1/tasks
       { "project_id": "...", "title": "T-NNN — Title",
         "agent": "Clemenza", "status": "in_progress",
         "assigned_to": "Clemenza" }
       ```
    2. Valid status values: `pending`, `in_progress`, `blocked`, `done`
       (NOT `ready`, `completed`, `cancelled`, `open`)

  After sub-agent returns (success or timeout):
    1. Mark task done: `PATCH /rest/v1/tasks?id=eq.{id}` → `{"status": "done"}`
    2. Log a decision: `POST /rest/v1/decisions` with outcome + rationale
    3. Create the NEXT task with `status: "in_progress"` BEFORE dispatching
       (so the chain is visible even if the next sub-agent times out)
    4. Update project timestamp: `PATCH /rest/v1/projects?id=eq.{id}` → `{"updated_at": "now()"}`

  The user will ask "are you updating the progress?" if this is skipped.
  Do NOT skip it — it's the primary audit trail for the delivery pipeline.

Fredo scans foundation before staging:
delegate_task(
  goal="Run pre-push security scan on foundation.
  Check: no secrets in code, .gitignore correct,
  no .env files staged, npm audit clean.",
  context="Project path: [path].",
  toolsets=["terminal", "file"],
  model="deepseek-v4-pro"
)

**PRE-PUSH BUILD VERIFICATION:**
Before pushing the foundation commit, run:
1. `npm run lint` — exit 0 required
2. `npm run build` — exit 0 required
3. `git status --short` — verify no stale files
See `references/pre-push-verification.md` for common build error fixes.

Seun reviews staging foundation (or local deliverable summary).
Seun approves before feature build begins.

**CRITICAL — Present for review after EVERY task, even during a "proceed" flow:**
After completing any task (T-xxx), do NOT automatically dispatch the next task.
Always present a summary of what was built, what changed, and test results.
Wait for Seun to reply "proceed" or give feedback before moving to the next task.
Pattern: build → present review summary → Seun says "proceed" → build next.
Do NOT chain tasks together without a review gate between them —
Seun will explicitly ask to review if he wants one, and dispatching
before he's reviewed the last deliverable wastes work.

Gate 3 completion signal:
  Seun sends "Foundation approved" or "proceed"
  Supabase deployments record created
  Feature build begins

---

**PREFERENCE — Show real content, not descriptions:**  
When presenting review material (migration SQL, PR diffs, API responses, file changes),  
show the actual file content or diff output — NOT a summary of what changed.  
Seun's explicit phrase: \"I want to see what I'm looking at.\"  
This applies to: migration SQL, code changes, PR reviews, error investigations.  
For error investigations, include the exact error output, not just the interpretation.

**PREFERENCE — Fast failure detection on user \"Done\":**  
When Seun returns from an external action (OAuth grant, credential paste, browser step)  
and says \"Done\", run verification within 2 seconds. If the old session timed out, start  
fresh — do not burn another 30 seconds on a dead connection. Report result immediately.

**PREFERENCE — Addendum-based intake:**  
Seun delivers structured requirements as numbered addenda with a consistent format:  
- Title + applies-to + context  
- Explicit CHANGE block with code  
- DO NOT CHANGE boundary markers  
- AFTER IMPLEMENTING verification steps  
When receiving an addendum, execute all steps in order, then report back with the  
verification results. The addendum IS the spec — no need to clarify scope.

**PREFERENCE — No local testing or dev servers:**  
Testing happens on Railway staging, not locally. Do NOT start `next dev`, `nest start`,  
or any local dev server. Do NOT run Playwright tests locally. Do NOT run `npm run test:e2e`  
locally. All verification uses Railway URLs directly (`curl`, `fetch`, browser console).  
The user was explicit: "I specifically said no tests should run locally." This container  
has no PostgreSQL, no root access for browser deps, and no .env credentials — local testing  
cannot work and wastes time. Use `curl` against Railway endpoints for backend checks,  
and the browser console for frontend checks.

**If a local dev server was started accidentally:** kill it immediately and confirm:
```bash
pkill -f "next dev" 2>/dev/null; pkill -f "nest start" 2>/dev/null; echo "killed"
```
Use `process(action='kill', session_id='...')` if started via `terminal(background=true)`,
or `dialog(action='send', data='/stop')` for persistent services.

**PREFERENCE — SQL migration format:**  
Do NOT provide `npx prisma migrate deploy` commands. The user runs all migrations  
manually in the Supabase SQL editor. Format migrations as:
```sql
ALTER TABLE "TableName" ADD COLUMN IF NOT EXISTS "columnName" TEXT;

INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'baseline', NOW(), 'migration_name', NULL, NULL, NOW(), 1);
```

**PREFERENCE — Review-first before execute:**  
When the user pastes an addendum (structured requirements document), review the approach first. Check for conflicts with existing code, better approaches, and structural issues. If no issues: say "Approach is sound. Proceed." and execute. If there's a better way: say "One improvement: [specific suggestion]. Otherwise proceed." Do NOT silently execute without reviewing — the user explicitly said "Review first, if there is a better approach, notify me, if not, execute."

Seun communicates his desired pace through single-word signals:

| Signal | Meaning | Response |
|--------|---------|----------|
| "Proceed" | Keep going, same pace | Dispatch next task, present brief result after completion |
| "Begin" / "Start" | Start the next step | Dispatch immediately |
| "Status" | Show me where we are | Present full project status from Supabase |
| "Finish" / "FInish" / "Wrap" / "Done" | Complete remaining without further iteration | Stop presenting options. Execute remaining tasks. Final summary only. |
| "Send it" / "Approved" / "Looks good" | Go ahead, dispatch to next agent | Send immediately, no further review |
| "Review first" / pasted addendum | Review approach, flag issues if any, then execute | Say "Approach is sound" or note one improvement, then proceed. Do NOT silently execute without reviewing. |
| "Review" | Show what was built before proceeding | Present review. Do NOT dispatch next until explicit "proceed" or "send it". |

**KEY RULE:** When Seun says "finish", do NOT ask "what's next?" or present
options. Execute remaining work, update Supabase once at the end, deliver
final summary. Option-presentation after "finish" frustrates.

**Rolling pace rule:** When Seun previously said "proceed" and the dispatch
cycle is clearly rolling, you may chain tasks without presenting for review
between each one. Present after completion. Exception: if the previous task
had build failures or partial timeouts, present for review first.

---

## PHASE 4 — FEATURE BUILD (iterative)

Owner: Clemenza per feature
Each feature = one Kanban task
Each task follows Symphony specification standard

For each P0 feature in PRD order:

  PRE-BUILD:
  - The Don creates Kanban task from PRD task breakdown
  - Task must have: Goal, Context, Acceptance,
    Scope, Output (all fields from PRD Section 12)
  - Michael reviews task for ambiguity before dispatch
  - Task must score >= 0.75 confidence before dispatch
  - Create task in Supabase with status=in_progress BEFORE
    dispatching the sub-agent. This ensures the chain is
    visible in the DB even if the sub-agent times out.
  - For tasks involving Kay (copy), dispatch Kay's copy
    task as a FAST delegate_task (toolsets=["file"]) in
    parallel with Clemenza's backend build. Kay's copy
    task completes quickly and produces an i18n file.
    This way copy and backend don't block each other.

    Kay's copy dispatch pattern:
    delegate_task(
      goal="Write all copy for [feature]: [description]",
      context="[tone guidance, audience, specific copy items needed]",
      toolsets=["file"]
    )
    → Output goes to src/common/i18n/[feature].en.ts
    See references/parallel-copy-backend-dispatch.md for the
    full parallel dispatch pattern and when to use it.

  **Design-dependent features (Apollonia before Clemenza):**
  When a task specifies "Apollonia designs first" (estate dashboard,
  guard UI, brand assets), dispatch Apollonia BEFORE Clemenza:

    1. Dispatch Apollonia with `designer` skill loaded:
       delegate_task(
         goal="Produce design assets for [feature]",
         context="PRD design section, colour tokens, type scale,
           surface list, component list. Ilu design philosophy.",
         toolsets=["file", "image_gen"]
       )

    2. Apollonia produces:
       - design-visual-spec.md (~1,500 lines, 12+ sections)
       - Brand mark + wordmark (via FAL AI)
       - Colour tokens, type scale, component specs
       - Screen layout specs for each surface
       - 10+ empty state illustrations

    3. Dispatch Clemenza with full context from design spec:
       Pass spec path and key design tokens directly.

  BUILD:
  delegate_task(
    goal="[from task breakdown — exact text]",
    context="[from task breakdown — exact text.
    Include: project path, relevant files,
    Supabase tables, staging URL, acceptance criteria]",
    toolsets=["terminal", "file"],
    model="deepseek-v4-pro"
  )

  **PITFALL — Sub-agent file corruption via embedded line numbers:**
  When a delegate_task sub-agent calls read_file then passes the result
  directly to write_file, the `N|` line-number prefix from read_file's
  output format gets embedded into the file content. For example:
  ```
  1|import { Injectable } from '@nestjs/common';  ← read_file output
  ```
  If the sub-agent treats this as the file content and writes it, the
  file becomes:
  ```
  1|1|import { Injectable } from '@nestjs/common';
  ```
  This corrupts the TypeScript with thousands of "Expression expected"
  errors and can take 30+ minutes to diagnose and fix across multiple
  files.

  Prevention (add to delegate_task context for ALL coding sub-agents):
  ```
  CRITICAL RULE — Never pass read_file output directly to write_file.
  read_file adds a line-number prefix (LINE_NUM|content) that will
  corrupt the file if passed to write_file. Always strip leading
  digits and pipes before writing.
  ```

  Detection: after sub-agent returns, quickly grep for corruption:
  ```bash
  python3 -c "
  import re, os
  for root, dirs, files in os.walk('src'):
      for f in files:
          if f.endswith('.ts'):
              with open(os.path.join(root,f)) as fh:
                  first = fh.readline()
              if re.match(r'^\d+\|', first):
                  print(f'CORRUPTED: {os.path.join(root,f)}')
  "
  ```
  Fix (run on any corrupted file):
  ```bash
  python3 -c "
  import re, os
  for root, dirs, files in os.walk('src'):
      for f in files:
          if f.endswith('.ts'):
              path = os.path.join(root,f)
              with open(path) as fh:
                  content = fh.read()
              if re.search(r'^(\d+[ |]*)+', content, re.MULTILINE):
                  content = re.sub(r'^(\d+[ |]*)+', '', content, flags=re.MULTILINE)
                  with open(path, 'w') as fh:
                      fh.write(content)
                  print(f'Fixed: {path}')
  "
  ```

  **PITFALL — Uncommitted package-lock.json breaks CI:**  
When `npm install` adds or updates dependencies (Playwright, svix, etc.), `package-lock.json` is modified. CI uses `npm ci` which requires the lock file to exactly match `package.json`. If the lock file isn't committed, the CI build fails. Before pushing, run `git status --short` and verify `package-lock.json` is staged. This applies to BOTH backend and frontend. The fix is simple: `git add package-lock.json && git commit -m "fix: commit lock file"`.

**PITFALL — Sub-agent embedded line-number corruption:**  
When a `delegate_task` sub-agent calls `read_file` then passes the result to `write_file`, the `N|` line-number prefix from read_file's output gets embedded in the file content as `1|1|import...`. Run this detection script after EVERY sub-agent that touched source files:
```bash
python3 -c "
import re, os
for root, dirs, files in os.walk('src'):
    for f in files:
        if f.endswith('.ts') or f.endswith('.tsx'):
            path = os.path.join(root,f)
            with open(path) as fh:
                first = fh.readline()
            if re.match(r'^\d+\|', first):
                print(f'CORRUPTED: {path}')
" | head -10
```
Fix: `content = re.sub(r'^(\d+[ |]*)+', '', content, flags=re.MULTILINE)`. This happened with community.controller.ts, community.service.ts, demo.controller.ts, and demo.service.ts across multiple sessions. The corruption can cascade (fixing one file reveals corruption in another). Check ALL source files after detection.

**PITFALL — Merge-and-verify loop for upstream changes:**  
When the user says "I made changes to main — bring yourself up to date":
1. `git fetch origin` — get latest
2. `git log --oneline addendum-007-clerk-jwks..origin/main` — see what's new
3. `git merge origin/main` — merge (prefer fast-forward)
4. `git diff HEAD~5..HEAD --stat` — audit what changed
5. Run both builds (`npm run build` for backend, `npm run build` for frontend)
6. Push
7. Present a summary of what was merged and what it fixes
  Same as Phase 3 — 600s timeout is common for tasks
  involving multiple files or cross-module wiring.
  Recovery pattern:
    1. List new/changed files to see what was created
    2. Check build compiles (`npm run build`)
    3. Run tests (`npm test`)
    4. Fix broken imports, missing files, incomplete
       wiring (especially import paths — sub-agents often
       create files but miss updating import paths in
       existing files)
    5. Verify the feature actually works (route registration,
       response shape, DB writes if applicable)
    6. Rebuild and retest
    7. Update Supabase: task status to `done` + log decision

  **CRITICAL — Update Supabase after EVERY feature task:**
  The Don MUST log each task completion in Supabase before
  declaring it done in conversation:
  - Patch task status: `{ "status": "done" }`
    (valid values: pending, in_progress, blocked, done)
  - Insert a decision record with outcome + rationale
  - Create the next task with status=in_progress before
    dispatching (so the chain is visible in DB even if
    the next sub-agent times out)
  - The user will ask "are you updating the progress?"
    if skipped. Do NOT skip this.

  POST-BUILD (The Don + Fredo):
  The Don fixes any post-timeout issues first, then
  delegates security scan:
  delegate_task(
    goal="Pre-push scan for [feature name].
    Check secrets, staged env files, npm audit,
    console.log with credentials.",
    context="Project path: [path].",
    toolsets=["terminal", "file"],
    model="deepseek-v4-pro"
  )
  Fredo must return CLEAR before push.

  **PRE-PUSH GATE — Run verification BEFORE every push:**
  Before pushing ANY branch (feature or main), run the full
  pre-push verification checklist at `references/pre-push-verification.md`:
  1. `git status --short` — audit staged files
  2. `npm run lint` — must exit 0
  3. `npm run build` — must exit 0
  4. `git push --dry-run` — confirm remote is reachable
  This catches CI failures locally and avoids Seun's
  "Didn't you check before you pushed?" correction.
  This applies to ALL pushes — feature branches, main, hotfixes.

  STAGING:
  - Clemenza pushes to a feature branch (NEVER directly to main)
  - **PITFALL — Branch diff must contain ONLY intended changes:**
    Before pushing a feature branch for review, verify `git diff main..HEAD --stat`
    shows ONLY the files the addendum changed. No collateral modifications
    (test files, editor artifacts, unrelated scripts, stray .env changes).
    Seun will inspect the diff and flag anything unexpected. If collateral
    changes exist, either reset them or explain why they're necessary before
    asking for review.
  - **PITFALL — Pre-merge build verification: run `npm run build`, not just `tsc --noEmit`:**
  When verifying a branch is ready for merge, run `npm run build` (which uses `nest build` / `next build`)
  NOT just `tsc --noEmit`. The two can disagree:
  - `tsc --noEmit` may report errors in `test/` files (e.g. supertest import mismatch) that don't affect
    the production build because `nest build` only compiles `src/`.
  - `npm run build` may catch errors that `tsc --noEmit` misses depending on the tsconfig used.
  - Before declaring a branch merge-ready, run BOTH `npm run build` (or `next build` for frontend) and
    `npx tsc --noEmit`, then inspect any differences.
  - **Classify every build error — pre-existing !== harmless:**
    When presenting build errors, investigate each one at the source:
    1. Read the exact file + line number from the error output
    2. Classify each error: (a) **runtime bug** — will crash in production (fix immediately),
       (b) **test-only** — in test/ dir, excluded from production build (safe to ignore),
       (c) **suppressed by // @ts-ignore** — can surface at runtime (flag to Seun)
    3. For type (a): apply the fix — "pre-existing" does not mean "harmless"
    4. Report as: error code → file + line → actual code → classification → action
  - **Build exit code matters:** `npm run build` exit code 1 will fail in CI even if tsc passes.
  - **PITFALL — Endpoint completeness audit when adding new API endpoints:**
    When an addendum adds a new frontend-facing API endpoint (e.g. GET /v1/residents/me),
    audit ALL admin or resident pages that consume related endpoints to verify the full
    set exists in the backend controllers:
    ```
    Admin page → API call → Backend controller → @Get() exists?
    admin/residents   → getResidents()  → residents.controller → @Get() checked
    admin/compounds   → getCompounds()  → compounds.controller → @Get() checked\n    admin/levy        → getLevyBills()  → levy-bill.controller → @Get() checked\n    ```\n    A partial implementation (e.g. adding GET /v1/residents/me but forgetting GET /v1/residents)\n    creates a 404 the frontend can't recover from. Run this audit table for every addendum\n    that touches API endpoints.\n\n    **PITFALL — @Public() on controller class makes ALL routes public:**

  A `@Public()` decorator at the controller CLASS level (above `@Controller()`)
  applies to EVERY method on that controller — overriding any method-level
  `@UseGuards(JwtAuthGuard, RolesGuard)`. JwtAuthGuard sees `isPublic = true`
  and returns immediately without setting `request.user`. RolesGuard then throws
  `"User not authenticated"` because `request.user` is `undefined`.

  This produces the diagnostic signature: `user=undefined, authInfo=false, headers=true`
  — meaning the JWT IS being sent but the guard never processes it.

  Fix: remove `@Public()` from the controller class and apply it only to the
  specific methods that need public access.

  Detection: `grep -n "@Public()" controller.ts | head -3` — if it appears near
  the `@Controller` decorator (not on a method), it's a class-level override.
  See `references/nestjs-public-class-override.md` for the full diagnostic pattern.

  **PITFALL — NestJS UnknownExportException: provider exported but not registered:**
  Adding a provider to the `exports` array without also adding it to the
  `providers` array causes a fatal `UnknownExportException` at startup:

  ```
  UnknownExportException: Nest cannot export a provider/module that is not
  a part of the currently processed module (NotificationModule).
  ```

  NestJS validates that every exported provider is actually owned by the module.
  If `EmailService` is in `exports: [EmailService]` but NOT in
  `providers: [..., EmailService]`, the app crashes at bootstrap.

  Fix: ensure every exported provider is also in the providers array:
  ```typescript
  providers: [ExistingService, EmailService],  // ← add here
  exports: [ExistingService, EmailService],     // ← matches this
  ```

  **PITFALL — NestJS UnknownDependenciesException: injecting a provider without importing its module:**
  When one controller injects a service from another module, the consuming
  module MUST import the providing module:

  ```
  UnknownDependenciesException: Nest can't resolve dependencies of the
  SOSController (SOSService, ?). Please make sure that the argument
  ResidentsService at index [1] is available in the SOSModule context.
  ```

  This happens when a feature module (`SOSModule`) injects a service
  (`ResidentsService`) from another module (`ResidentsModule`) but never
  imports that module. NestJS cannot resolve cross-module providers
  without an explicit import.

  Fix — add the missing import to the consuming module:
  ```typescript
  // BEFORE — SOSModule has no way to resolve ResidentsService
  @Module({ imports: [NotificationModule, PrismaModule], ... })
  
  // AFTER — ResidentsModule provides ResidentsService to SOSModule
  import { ResidentsModule } from '../resident/residents.module';
  @Module({ imports: [NotificationModule, ResidentsModule, PrismaModule], ... })
  ```

  Pre-flight check when adding cross-module service injection:
  1. `grep -n "import.*Service" controller.ts` — find injected services
  2. For each injected service NOT owned by this module:
     - Verify `grep "exports" <service-module>.module.ts` lists the service
     - Verify `grep "imports" <this>.module.ts` imports the service's module
  3. If the module is missing from imports, add BOTH the import statement
     AND the module to the `@Module({ imports: [...] })` array

  This pitfall is the mirror image of UnknownExportException (export without provide).
  For a full catalog of NestJS DI failures, see `references/nestjs-di-failure-catalog.md`.

  **PITFALL — Circular dependency via new module imports (forwardRef required):**
  When adding a new module to imports (e.g. NotificationModule to ResidentsModule
  for admin KYC notifications), check whether the import chain forms a loop:
  ```
  WhatsAppModule → ResidentsModule → NotificationModule → WhatsAppModule
  ```
  NestJS will throw `UndefinedModuleException: Nest cannot create the XModule instance`
  with `Scope [AppModule -> ResidentsModule -> NotificationModule]`. Fix by wrapping the
  import that CLOSES the cycle with `forwardRef(() => ModuleName)`. See
  `references/nestjs-circular-dependency-forwardref.md` for the full detection pattern.

  **PITFALL — Dynamic require() of TypeScript files always returns undefined:**
  `const copy = require('../../common/i18n/notification.en').default` fails for two
  independent reasons: the file has no `export default` (only named exports), and
  `tsc` never compiles files that are only loaded via `require()` (no static import).
  Every notification silently crashes with `Cannot read properties of undefined`.
  Replace with inline templates, static imports, or proper named exports.
  See `references/nestjs-dynamic-require-failure.md`.

  **PITFALL — Notification channel map sends to channels that can't deliver:**  
  When a notification type maps to channels that require identifiers not available
  in the dispatch call (e.g. IN_APP needs Clerk ID but dispatch sends phone number),
  all notifications silently fail with zero errors. Every SOS_DISPATCH alert
  dispatched for weeks with no responder receiving anything.  
  See `references/notification-channel-map-mismatch.md`.

  **PITFALL — Fallback responders fetched but never assigned to dispatch loop:**  
  When a fallback path fetches alternate recipients (adminStaff, secondary responders)
  but never reassigns `responders = alternateList`, the dispatch loop silently iterates
  over the empty primary list. The fallback code exists, logs, and returns success —
  but dispatches to zero people. The tell: `adminStaff` is fetched into a local variable
  but `responders` is never reassigned.  
  Detection: grep for the dispatch loop variable and verify every fallback path
  that assigns a dispatchedTo string ALSO reassigns the responders array.

  **PITFALL — Stale test constants shipped to production:**
  Hardcoded values like `transaction_charge: 50` (50 kobo) left over from
  development never get replaced with the actual calculated value. Every
  transaction silently charges the wrong platform fee. The sub-agent that
  built the Paystack integration hardcoded the constant and the caller never
  passed the real calculated fee through.

  Detection: grep for numbers that should be calculation results:
  ```bash
  grep -rn "transaction_charge\|platformFee\|Math.round" --include="*.ts"
  ```
  If `transaction_charge` is a literal number in a service method but
  `platformFee` is calculated elsewhere, the integration is broken.

  Fix pattern — pass the calculation through as a parameter:
  ```typescript
  // paystack.service.ts — accept the fee, don't hardcode it
  async initializeTransaction(..., platformFeeKobo?: number) {
    payload.transaction_charge = platformFeeKobo ?? Math.round(amount * 0.005);
  }
  // caller — pass the already-calculated fee
  await this.paystackService.initializeTransaction(
    ...,
    Math.round(platformFee * 100), // convert to kobo
  );
  ```

  **PITFALL — Missing migration SQL after schema.prisma changes (P2022 crash):**
  Sub-agents frequently add new fields to `schema.prisma` and regenerate
  the Prisma client but forget to create the corresponding migration SQL file
  in `prisma/migrations/<timestamp>_<name>/migration.sql`. The app builds
  and deploys correctly, then crashes on any query touching the new fields:

  ```
  PrismaClientKnownRequestError: P2022
  The column `Resident.kycReviewStatus` does not exist in the current database.
  ```

  This has happened at least 3 times (Invitation.residentId, Notification
  model, Resident.kycReviewStatus) because sub-agents generate Prisma client
  locally but the production DB was never migrated.

  **Post-sub-agent recovery — ALWAYS check for orphaned schema changes:**
  1. `grep -c "model" schema.prisma` — count models
  2. `ls -d prisma/migrations/*/ | wc -l` — count migration dirs
  3. For NEW fields added to EXISTING models:
     ```bash
     # Check if migration SQL exists for fields added recently
     for field in $(git diff HEAD~1 -- schema.prisma | grep '^+' | grep -v '^+++' | grep '@' | head -20); do
       echo "Check migration for: $field"
     done
     ```
  4. When a new field pair is found (field in schema but no migration):
     - Create the migration directory: `mkdir -p prisma/migrations/<timestamp>_<name>/`
     - Write the ALTER TABLE SQL
     - Commit BEFORE pushing — Railway auto-runs `prisma migrate deploy` on start

  **Detection (on Railway logs):** `P2022` + column name → check if migration
  SQL file exists for that column.

  See `references/prisma-orphaned-migration-detection.md`.

**PITFALL — Silent method signature redesign:**  
  When modifying an existing method, preserve the EXISTING signature,
  parameter order, field names, and ownership checks. Only change the
  internal behavior (what the `update()` call does). The test: a grep
  for the method name across the codebase should return the same number
  of call sites before and after your change, with zero new import errors.

  This happened with `upgradeToVerified(id, dto, userId)` — the initial
  draft changed the parameter order, renamed `governmentId` to `idDocUrl`
  (a field that doesn't exist), and silently dropped an ownership check.
  None of this was intentional — it was an accidental redesign during
  copy-paste.

  **Fix pattern:** keep everything above the mutation call exactly as-is.
  Only change the `data:` block inside `prisma.resident.update()`.
  If you genuinely want to change the signature, call it out as its own
  decision with the full blast radius — don't let it happen as a side effect.
  A DTO with properties but NO decorators (`@IsOptional()`, `@IsString()`, etc.) will
  silently strip every field from the request body. The controller receives an empty
  object with no error. This shipped to production on `TriggerSosDto` — the panic
  button never accepted a real request for weeks. Every DTO property must have at
  least `@IsOptional()`. See `references/nestjs-missing-validators.md`.

  **PITFALL — `req.user.id` vs `req.user.sub` JWT field name mismatch:**
  Clerk JWTs store the user identifier as `sub`, not `id`. Controllers that read
  `req.user.id` get `undefined` — no crash, just silent failure. Found 6 times
  across 4 files (SOS, levy, QR, profile). Also: `req.user?.communityId` vs
  `req.user?.community_id` (snake_case from JwtAuthGuard). See
  `references/nestjs-jwt-field-mismatches.md`.

  **PITFALL — Middleware blocking static asset requests:**
  When Clerk middleware's `isPublicRoute` matcher doesn't include `/images/` or
  other static asset paths, requests for those assets are treated as auth-protected
  routes and redirected to `/sign-in`. Images break silently — no JS error,
  just missing visuals.

  Fix: add static asset paths to the public route matcher:
  ```typescript
  const isPublicRoute = createRouteMatcher([
    '/images(.*)',
    // ... other public routes
  ]);
  ```
  Also add any marketing pages served from the marketing route group (e.g. `/landing`,
  `/contact`) if they're not already covered.

  **PITFALL — Route groups: root page bypasses marketing layout:**
  When the landing page lives at `(marketing)/landing/page.tsx` and the root
  `page.tsx` renders it directly via `<LandingPage />`, the marketing layout
  (`(marketing)/layout.tsx`) does NOT apply — because the root route is OUTSIDE
  the route group. Nav and footer disappear.

  Fix: redirect from root to the route-group path:
  ```tsx
  // root page.tsx — unauthenticated users
  redirect('/landing');
  ```
  This ensures the MarketingShell layout wraps the landing page and provides
  the shared nav/footer. Do NOT render the component directly in the root page.

**PITFALL — `useSearchParams()` in Next.js App Router requires Suspense:**  
When a page component uses `useSearchParams()` from `next/navigation`, Next.js
will fail the production build with:
```
useSearchParams() should be wrapped in a suspense boundary at page "/resident/pass"
```
This is a Next.js 16 requirement. Split the page into an inner content component
and a Suspense wrapper:
```tsx
import { Suspense } from 'react';
function PageContent() { const searchParams = useSearchParams(); ... }
export default function Page() {
  return <Suspense fallback={<div>Loading...</div>}><PageContent /></Suspense>;
}
```

**PITFALL — `req.user?.community_id` (snake_case) copy-paste bug:**  
`JwtAuthGuard` attaches `community_id` in snake_case. Every `req.user?.communityId`
or `req.communityId` read returns `undefined`. This typo broke levy-bill (100% of
estates), maintenance (8x), and guard-shift (3x). Fix the decorator once:
```typescript
return ctx.switchToHttp().getRequest().user?.community_id;
```

**PITFALL — Auth context endpoint called without Bearer token:**  \nEven after ADD-025 decouples roles from Clerk JWT metadata, the `fetchAuthContext()`\nfunction in AuthProvider sends a GET to `/v1/auth/context`. If the `Authorization:\nBearer ${token}` header is missing from the fetch call, the backend returns 401\n\"No token provided\" — NOT the friendly role/community response. This produces exactly\nthe same 401 symptoms as the Clerk metadata race and wastes hours of debugging.\n\nFix: ensure `fetchAuthContext(token: string)` receives the token AND passes it as\n`headers: { 'Authorization': 'Bearer ${token}' }`. This was found and fixed in\ncc-build commit `6085b92`.\n\n**PITFALL — JwtAuthGuard vs AuthContextService resolution drift:**  \nADD-025 creates TWO resolution paths: `auth-context.service.ts.resolve()` for the\n`GET /v1/auth/context` endpoint, and `jwt-auth.guard.ts.resolveAuthContext()` for\n`request.user.roles` on every API request. Both must have the same priority order\n(UserRole first, then Community.ownerClerkId fallback). If you fix one but not the\nother, the guard's hardcoded `roles: ['estate_admin']` from the Community owner lookup\noverrides the UserRole table — making manual Supabase role updates invisible.\n\nRule: when changing the resolution priority, always update BOTH files simultaneously.\nSee references/auth-guard-service-dual-resolution.md for the detection pattern.\n    Every community-scoped list endpoint must guard against null community_id.\n    When community_id is null (JWT user has no community assigned), the endpoint\n    MUST return an empty array — NOT query Prisma with `communityId: null` on a\n    required String field (which throws 500) and NOT query without tenant scoping\n    (which leaks cross-tenant data).\n\n    Add this guard to EVERY findAll method:\n    ```typescript\n    if (!communityId) {\n      return { data: [], total: 0, page: 1, limit: 20 };\n    }\n    ```\n\n    Audit checklist when adding new endpoints:\n    - [ ] compound.controller.ts — findAll has guard\n    - [ ] residents.service.ts — findByCommunity has guard\n    - [ ] levy.controller.ts — findAll has guard\n    - [ ] visitor-passes.controller.ts — findAll has guard\n    - [ ] support-staff.controller.ts — findAll has guard\n\n    Applies to: ALL controllers that scope queries by community_id from JWT.\n   passes. Treat build failures as blocking until both pass or the discrepancy is documented.
 - **Three-file diff rule:** When Seun asks "what are the pre-existing errors?", read the actual files
   at the error line numbers, not just the error code. A `TS2588: Cannot assign to 'const'` could be
   a genuine runtime bug that silently blocks a fallback path.

 The Don tells Seun the branch is ready for review
 - Seun reviews and merges, or asks for changes
  - GitHub Actions CI runs: tests + Lighthouse + Fredo
  - All gates pass -> staging deployment auto-triggers
  - Consigliere notifies Seun via Telegram:
    "Feature ready for review: [feature name]
    Staging: [url]. Tests: [N] passing.
    Lighthouse: [score]. Awaiting approval."

  APPROVAL:
  - Seun reviews on staging
  - Seun approves -> Clemenza merges to main
  - Seun requests changes -> RETRY with new context
  - Escalation timer: 4hr reminder, 24hr daily

  Repeat for each P0 feature.
  P1 features begin only after all P0 are DONE.

---

## PHASE 5 — INTEGRATION AND QA

Owner: Clemenza + Fredo
Runs after all P0 features are DONE

### Compliance Review (Phase 5.5 — Michael)

After all features are built and before production deployment, run a
PRD compliance review against the final codebase. This is distinct
from QA — it checks every PRD requirement against what was actually
built, not just that the software works.

Pattern (for The Don, delegating to Michael):

  1. Read the compliance review instrument document
     (references/compliance-review-instrument.md) — this is
     Michael's checklist template.

  2. For each section (Data Model, FRs, API, Security, NFRs, UI/UX):
     - Check the codebase against the PRD spec
     - Mark each item as PASS / FAIL / DIVERGENCE
     - For FAIL items: document exact file, function, and fix steps
     - For DIVERGENCE items: document the difference and rationale

  3. Produce a delta report when comparing TWO implementations:
     - Clone secondary branch: `git clone --branch <branch> --depth 1 <repo> <dir>`
     - Compare entity count and fields (Prisma schema `model` count)
     - Compare FRs side-by-side in a table
     - Compare architectural approach (monorepo vs flat, RLS vs app-layer)
     - Recommended primary + cherry-pick candidates from secondary

  4. Produce Clemenza addenda for each FAIL/DIVERGENCE:
     Each addendum follows Michael's format:
     ```
     [CLIENT] — ADDENDUM [NUMBER]
     [TITLE]
     Priority: [P0/P1]
     Applies to: [file path / component]

     CONTEXT: [why — one sentence]
     CHANGE: [exactly what — specific]
     DO NOT CHANGE: [everything adjacent]
     AFTER IMPLEMENTING: [verification steps]
     ```

  5. Present addenda package to Seun for approval.
     Classification rules:
     - P0: Blocks production deployment (NDPR breach, missing security)
     - P1 staging / P0 prod: Must fix before real data enters system
       (e.g. DPA endpoint, PII encryption)
     - P1: Dev quality, should fix before steady state

  6. On approval, dispatch to Clemenza in priority order.
     Execution order matters when addenda touch the same modules.

**PITFALL — Priority creep:** Michael may flag items as P1 that
are actually compliance risks. When reviewing addenda, Seun or
The Don should promote P1 items that carry NDPR/legal exposure
to "P1 staging / P0 prod". The test: "can an estate advance to
a phase requiring real resident data without this fix?" If yes,
it's a production gate.

**PITFALL — CI will fail after first git push if the repo has
existing CI from another branch:** After pushing the initial
commit to a new/existing repo, ALWAYS check GitHub Actions.
Common failure: the cc-build or secondary branch brought in a
monorepo CI file (turborepo) that references paths that don't
exist in your structure (e.g. root package.json, turbo.json,
apps/, packages/, lighthouserc.json). Fix by:
  1. Removing conflicting monorepo artifacts (`package.json`,
     `turbo.json`, `apps/`, `packages/`, `lighthouserc.json`)
  2. Replacing `.github/workflows/ci.yml` with your own workflow
     targeting `backend/` and `frontend/` separately
  3. Remove stale `.github/workflows/` nested inside subdirectories
     (GitHub only reads from repo root `.github/workflows/`)
  4. Push fix and confirm CI goes green

Clemenza runs:
  - Full integration test suite
  - Full E2E test suite (Playwright)
  - Performance baseline (Lighthouse all pages)
  - Cross-device testing (desktop + mobile viewports)
  - Load testing if applicable

Fredo runs full pre-production audit:
  - trufflehog full repo scan
  - npm audit (no critical or high findings)
  - observatory-cli on staging URL
  - All security headers present
  - HTTPS enforced
  - NDPR consent check if ERP project

All issues logged to ERRORS.md in .learnings/
All findings resolved before Phase 6.
Seun receives QA report via Telegram.

---

## PHASE 6 — PRODUCTION DEPLOYMENT

Owner: Clemenza + Fredo
Requires explicit Seun approval — no exceptions

**When Seun presents a deployment plan for review:**
See references/deployment-plan-review.md for the structured review checklist.
Cross-reference every webhook URL, staging URL, and env variable from the
plan against the actual codebase. Produce corrections as a markdown doc
in docs/DEPLOYMENT_CORRECTIONS.md if mismatches exist.
Fredo final scan on production build:
  CLEAR required before deployment proceeds.
  Any CRITICAL finding blocks deployment.
  Only Seun can override a CRITICAL block.

Clemenza deploys:
  ✅ Frontend (Vercel): `vercel --prod`
  ✅ Backend (Railway): `railway up`
  
    **No-CLI fallback:** If Vercel CLI is unavailable (Docker, Hermes WebUI, headless),
    use the Vercel REST API. See `references/vercel-api-deployment.md` for the full
    workflow: create project → set env vars → trigger deployment with GitHub repoId.
  
    **PITFALL — Railway auth from headless environment:**
    Railway CLI requires OAuth login. From a Docker container or
    headless server without a browser, use the device-code flow:
    ```bash
    railway login --browserless
    ```
    This prints a URL + verification code. The user opens the URL
    on their phone or any device with a browser. The CLI blocks
    until authentication completes.
    See `references/railway-deployment.md` → Authentication.

    **PITFALL — `.env` secret corruption by Hermes redaction:**
    When the `.env` file is read or written through the Hermes agent
    system, credential values (database passwords, API keys) are
    silently replaced with literal `***` characters. This means when
    you set Railway environment variables FROM a `.env` file that was
    created or read during the session, the deployed app gets `***`
    as the real password and authentication fails. Recovery requires
    getting fresh credentials from the source system and waiting for
    the Supabase pooler circuit breaker to reset.
    See `references/railway-deployment.md` → `.env Secret Management`.

    **PITFALL — GitHub auto-deploy requires Railway GitHub app:**
    After deploying manually via `railway up` (local archive upload), the user
    may request automatic deployments on `git push`. This requires connecting
    the Railway service to the GitHub repo via `serviceConnect` mutation.
    This fails with `"User does not have access to the repo"` unless Railway's
    GitHub integration has been authorized at `https://railway.com/account/github`.

    **CRITICAL SPEED — Verify immediately when user returns from an action:**
    When the user returns from performing an action (OAuth flow, visiting a URL,
    running a command) and says "Done", run the verification command immediately
    (2 seconds max). Do NOT re-run a time-burning command hoping the old session
    revived. Apply this to: Railway OAuth, database migrations, DNS propagation,
    credential generation, and any other user-initiated action.
    See `references/railway-deployment.md` → Critical Speed Rule.

    **PITFALL — Platform-injected env vars persist across terminal() calls:**
    When the user pastes an env var like `RAILWAY_TOKEN=<value>` in their
    message, the Hermes WebUI may inject it at a layer above the shell.
    The only reliable bypass is `env -i` (complete environment isolation).
    See `references/railway-deployment.md` → Platform-level env var re-injection.

    **TOKEN CONFUSION — `RAILWAY_TOKEN` vs `RAILWAY_API_TOKEN`:**
    Railway has two token types with DIFFERENT env vars:
    - `RAILWAY_TOKEN` → project-scoped token
    - `RAILWAY_API_TOKEN` → account-scoped token
    Both use UUID format. See `references/railway-deployment.md` for the full table.

    **CLI AUTH FALLBACK — When CLI rejects valid token:**
    Railway CLI v5.8.0 may reject an account token via `RAILWAY_API_TOKEN`
    even though the same token works with the GraphQL API. Use the direct
    GraphQL API approach instead.
    See `references/railway-deployment.md` for the full GraphQL cheat sheet.

    **PITFALL — Railway free plan allows only 1 project:**
    Railway's free tier caps at 1 project per account. Rename and reuse the
    existing project or delete it.
    See `references/railway-deployment.md` → Free Plan Limits.
  
Clemenza runs production smoke tests:
  - All P0 user stories: happy path passes
  - Auth flow (if applicable)
  - Database writes confirmed
  - Third-party integrations confirmed

Consigliere notifies Seun:
  "Production deployment complete.
  [project] is live at [url].
  Smoke tests: [N/N passing].
  Awaiting final sign-off."

Seun signs off -> Gate 7 complete.

---

## PHASE 7 — POST-DELIVERY

Owner: Consigliere + Hagen + Clemenza

Documentation (Clemenza):
  README.md — setup, environment, deployment
  API.md — all endpoints if applicable
  RUNBOOK.md — how to operate and maintain

Invoice (Hagen):
  Generate from billing_events table
  Deliver via Resend to client email
  Log to Supabase invoices table

Learnings (Clemenza + The Don):
  Log to ~/.hermes/workspace/.learnings/
  LEARNINGS.md: what went well, what to repeat
  ERRORS.md: what broke and how it was fixed
  FEATURE_REQUESTS.md: what was asked for but deferred

Session sync (Consigliere):
  Full project state written to Supabase
  project_brand finalised
  All decisions confirmed in decisions table
  Hot memory updated

Project status -> COMPLETE in Supabase projects table.

---

## FAMILY RESPONSIBILITIES IN THIS PROTOCOL

| Agent | Phase | Responsibility |
|-------|-------|---------------|
| Michael | 0-1 | Input intake, PRD completion, no ambiguity |
| Apollonia | 0 | Figma intake, token extraction |
| Clemenza | 0,3,4,5,6,7 | Codebase read, build, test, deploy |
| The Don | All | Orchestration, task creation, gate tracking |
| Luca | All | Pre-flight before every delegation |
| Fredo | 3,4,5,6 | Security scan at every gate |
| Kay | 4 | Copy and content for any UI text |
| Hagen | 7 | Invoice, documentation formatting |
| Consigliere | All | Monitoring, escalation timer, session sync |

---

## HARD RULES

1. No code before PRD approved
2. No build before architecture approved
3. No feature build before foundation approved
4. No staging merge without Fredo CLEAR
5. No production without Fredo CLEAR
6. No production without Seun explicit approval
7. No rewrite of existing codebase — fork or branch only
8. No stack outside approved library without justification
9. No task dispatched with confidence < 0.75
10. No phase completed without Supabase updated

---

## REFERENCES

- `references/file-operations-pitfalls.md` — File I/O: line number corruption, globals.css merging, delegate task cache staleness
- references/lovable-decoupling.md — 4-dependency checklist for Lovable projects
- references/project-registration.md — Don's Supabase schema for clients/projects
- references/supabase-migrations.md
- `references/supabase-db-connection.md`
- `references/ssl-cert-debugging.md`
- references/supabase-cli-auth-failures.md
- `references/nestjs-di-failure-catalog.md` — full catalog of NestJS DI failures (UnknownExportException, UnknownDependenciesException, circular deps)
- `references/nestjs-circular-dependency-forwardref.md` — detection and fix for module import chain loops (WhatsAppModule→ResidentsModule→NotificationModule→WhatsAppModule)
- `references/nestjs-dynamic-require-failure.md` — require() of TypeScript files always returns undefined: no default export + not compiled to dist/
- `references/prisma-migration-already-exists.md` — P3018/P3009: column/table already exists in production (manual SQL Editor run), idempotent migration fix
- `references/feature-flow-audit-methodology.md` — 6-step audit pattern: trace state machine, check guards, notification paths, dead code, frontend match, severity table
- `references/notification-channel-map-mismatch.md` — IN_APP/EMAIL/SMS channel requirements vs available recipient data: silent delivery failures
- references/supabase-migration-workaround.md
- references/nigerian-sme-design-patterns.md
- references/four-lane-boundary-design.md
- references/project-resumption-verification.md
- references/watermelondb-decorators.md
- `references/pre-push-verification.md` — pre-push build + lint verification checklist, common Next.js/TypeScript build error fixes
- `references/docx-content-extraction.md` — two-pass extraction (paragraphs + tables) for uploaded .docx files
- `references/prd-review-checklist.md` — structured 10-category blindspot audit run by Michael during Phase 1 PRD review
- `references/api-response-security.md` — five rules + audit pattern: never expose raw credentials in API responses consumed by a browser
- `references/clerk-metadata-race-condition.md` — Clerk session metadata propagation race, failed workarounds, and ADD-025 decoupling solution
- `references/auth-context-decoupling.md` — ADD-025 full implementation pattern: UserRole table, AuthContext endpoint, JwtAuthGuard DB resolution, frontend migration from sessionClaims
- `references/auth-guard-service-dual-resolution.md` — JwtAuthGuard vs AuthContextService resolution drift: always update both files when changing priority order, or the guard's request.user.roles overrides the service
- `references/browser-console-api-testing.md` — browser console fetch + getToken() pattern for testing backend endpoints without terminal access
- references/addenda-dispatch-pattern.md — Seun's addenda-based development workflow and SQL migration command format
- `references/nestjs-public-class-override.md` — NestJS @Public() at class level overrides ALL method-level @UseGuards(JwtAuthGuard); diagnostic pattern: user=undefined + headers=true
- references/sms-provider-migration.md
- `references/ui-component-library-migration.md` — UI component library incremental adoption pattern: merge CSS, install with V2 naming, migrate by surface, JSX balance check after migration
- `references/asset-verification-checklist.md` — verify every user-provided image asset is referenced in code, tracked in git, and accessible via middleware public routes
- `references/nullish-coalescing-empty-string-trap.md` — `||` vs `??` for database field fallbacks: empty strings bypass `??`, causing `undefined.toUpperCase()` crashes
- `references/raw-fetch-auth-gap.md` — raw `fetch()` without Authorization header; always use centralized `request()` from api.ts for authenticated calls
- `references/compliance-review-instrument.md` — structured PRD-to-codebase compliance checklist used by Michael for deployment-gate reviews
- references/frontend-mock-data-audit.md — systematic audit of frontend pages for hardcoded mock data vs real API calls; patterns for mock fallback replacement
- references/mono-repo-pattern.md — backend/ + frontend/ in same repo, independent builds, combined .gitignore
- references/nestjs-webhook-rawbody.md — rawBody: true required for HMAC webhook signature verification (Paystack, Meta, Stripe)
- references/typescript-strict-array-init.md — `never[]` inference fix with explicit type annotations in strict TypeScript
- references/nestjs-11-typescript-build.md — TypeScript build fixes for NestJS 11
- references/nestjs-multi-tenant-patterns.md — backend community_id discriminator column approach for multi-tenant SaaS
- references/frontend-multi-tenant-patterns.md — frontend community_id flow through Clerk auth + API client for multi-tenant SaaS (companion to backend reference)
- references/prisma-migration-without-db.md — generate Prisma migration SQL without a running database
- references/timeout-recovery-checklist.md — 11-step recovery when delegate_task sub-agent hits 600s timeout
- references/github-push-existing-remote.md — handling existing remote branches, merge vs leave decisions, credential use for push
- references/railway-deployment.md — Railway deployment for NestJS/Prisma backends (headless auth, Supabase SSL workaround, env var setup)
- references/clerk-nextjs-app-router.md — Clerk auth for Next.js App Router: server vs client component rules, token sync pattern, middleware setup
- `references/nestjs-clerk-webhook.md` — Clerk webhook handler pattern with Svix, auto-provisioning flow, module registration\n- references/nestjs-auth-patterns.md — Clerk JWKS JWT verification, RBAC constants, AuthProvider token refresh, community scoping, design decisions
- references/nestjs-rbac-constants.md — centralised role constants pattern for `@Roles()` decorators across controllers; migration guide from inline roles
- `references/clerk-metadata-race-condition.md` — Clerk session metadata propagation race, failed workarounds, and ADD-025 decoupling solution
- `references/addenda-dispatch-pattern.md` — Seun's addenda-based development workflow and SQL migration command format
- `references/nestjs-jwt-field-mismatches.md` — `req.user.id`→`req.user.sub` and `req.communityId`→`req.user?.community_id` bug classes
- `references/nestjs-missing-validators.md` — DTOs with zero class-validator decorators silently reject all input
- `references/notification-identity-traps.md` — wrong field used for recipientClerkId (phone/email instead of linkedClerkUserId)
- `references/paystack-integration-pitfalls.md` — CORS_ORIGIN callback URL bug, hardcoded transaction_charge, fee-inclusive pricing formula