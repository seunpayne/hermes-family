# UNIVERSAL BUILD PRINCIPLES
# Version: 1.0
# Applies to every project regardless of stack.
# Michael reads this FIRST, before any stack-specific playbook.
# Derived from: sync engine prototype failure (May 2026) and
#               TMG Capital / Farocon / Foremost Capital builds.

---

## HOW TO USE THIS FILE

These principles are non-negotiable. They apply before any code
is written, before any scaffold command is run, before any task
is dispatched to Clemenza.

When Michael generates a PRD, every task in Section 12 must
be consistent with these principles. If a task violates any
principle below — rewrite the task before submitting.

---

## PRINCIPLE 1 — SEPARATE LOGIC FROM DELIVERY MECHANISM

**The lesson:** The sync engine prototype was scaffolded as an
Expo/React Native app to test TypeScript functions. Babel errors,
Metro bundler conflicts, and WatermelonDB native module issues
created a spiral that blocked all progress. The sync logic
itself — pure TypeScript functions — did not need a mobile
runtime to be tested.

**The rule:**
Test business logic in isolation first.
Integrate into the delivery mechanism only after logic is proven.

Business logic = functions, algorithms, data transformations,
API calls, conflict resolution, validation.

Delivery mechanism = Expo app, React UI, Fastify server,
Edge Function, WhatsApp webhook handler.

**Per stack — how to isolate:**

| Stack | Business logic | Test in | Delivery mechanism |
|-------|---------------|---------|-------------------|
| ERP/mobile | Sync engine, conflict resolution, migration workflows | Node.js + Vitest | Expo + WatermelonDB |
| Website | Form validation, Supabase queries, data transforms | Vitest (jsdom) | React/Vite in browser |
| API/backend | Route handlers, signature verification, business rules | Supertest + Vitest | Fastify on Railway |
| WhatsApp | Message parsing, phone normalisation, template logic | Vitest (Node.js) | Webhook on Railway |
| AI chatbot | Rate limiting, context management, conversation history | Vitest (Node.js) | Supabase Edge Function |

**How to apply in task generation:**
- Task T-001 through T-N for pure logic: Node.js TypeScript + Vitest
- No framework setup required
- No bundler required
- No mobile simulator required
- Integration task comes AFTER all logic tasks pass

---

## PRINCIPLE 2 — SUPABASE DDL RULE

**The rule:**
`CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`, `CREATE INDEX` —
never via Supabase REST API (`/rest/v1/` or JS client).

The REST API is for querying existing tables only.
DDL requires one of:

```bash
# Option A — CLI (preferred)
supabase db execute --sql "CREATE TABLE ..."

# Option B — Migration file (for permanent schema changes)
supabase migration new [migration-name]
# Write SQL in the generated file, then:
supabase db push

# Option C — Dashboard (manual fallback)
# https://supabase.com/dashboard/project/[project-ref]/editor
# Paste and run SQL directly
```

**Every task that creates or modifies schema must specify
which of these three options to use in its CODE section.**

Never write a schema task where CODE section calls
`supabase.from()` or uses the REST API to run DDL.
This will fail silently or return a 404.

---

## PRINCIPLE 3 — SPIRAL RECOGNITION

**What a spiral looks like:**
Fix dependency error A → error B appears →
fix B → error C appears → fix C → error A returns.
Three consecutive errors from the same root system
(Babel, Metro, webpack, native modules) = spiral.

**The rule:**
When a spiral is detected — stop immediately.
Do not fix the next error.
Ask: "Are we testing the right thing with the right tool?"

The answer is usually one of:
1. We are using the full production stack to test logic
   that does not need it → apply Principle 1
2. We have a version incompatibility between two packages
   → check package.json for conflicting versions, not
   a missing package
3. We are using a native module in a non-native environment
   → isolate the native dependency behind an interface

**What Clemenza must do when spiral is detected:**
Stop execution.
Send Telegram: "SPIRAL DETECTED — [stack] — [error pattern].
Three dependency errors from same system.
Requesting architecture check before continuing."
Wait for Seun decision. Do not fix and retry.

---

## PRINCIPLE 4 — .GITIGNORE BEFORE FIRST COMMIT

**.gitignore must exist and must include these entries
BEFORE running `git add .` or `git commit` for the first time:**

```
.env
.env.local
.env.*.local
node_modules
dist
.vercel
*.key
*.pem
```

**The check:**
```bash
cat .gitignore | grep -E "^\.env$"
# Must return: .env
# If not: add it before first commit
```

Fredo scans for staged .env files before every push.
But the .gitignore must exist from the first commit.
A secret committed even once is compromised — even after deletion,
it exists in git history and must be rotated.

---

## PRINCIPLE 5 — BUILD THE SMALLEST THING FIRST

**The rule:**
Never scaffold the full production stack to prove a concept.
Build the minimum viable implementation that tests the hypothesis.
Then expand.

**Applied per project phase:**

Phase: Does our sync conflict resolution produce the right result?
Smallest thing: A single Vitest test with mocked Supabase.
Not the smallest thing: Full Expo app with WatermelonDB and
Metro bundler running on a device.

Phase: Does our webhook receive and parse WhatsApp messages?
Smallest thing: A local Fastify server + ngrok + curl test.
Not the smallest thing: Full Railway deployment with CI/CD.

Phase: Does our chat widget render and stream responses?
Smallest thing: A standalone HTML file with inline JS calling
the Edge Function.
Not the smallest thing: Full Vite app with TanStack Router.

**Task ordering rule:**
Tasks that prove logic always come before tasks that integrate.
Never merge integration into a logic task.
Never skip logic validation to save time.

---

## PRINCIPLE 6 — CREDENTIALS NEVER IN CODE

**The rule:**
No credential, API key, token, password, or secret
ever appears in committed code. Not in comments.
Not in test files. Not as default values.
Not in TypeScript `const KEY = 'sk-...'`.

**Always:**
- Environment variables from `.env` file (local)
- Platform env vars (Vercel, Railway) for production
- Supabase Vault for Edge Function secrets
- `~/.hermes/.env` for the family's own credentials

**Fredo catches this** with trufflehog before every push.
But the discipline must exist before Fredo runs.

**When writing CODE sections for tasks:**
Never include actual credential values.
Always write: `process.env.VARIABLE_NAME` or
`Deno.env.get('VARIABLE_NAME')`.
Provide the `.env` file template separately.

---

## PRINCIPLE 7 — EVERY TASK IS INDEPENDENTLY VERIFIABLE

**The rule:**
Every task in Section 12 must have a VERIFY step that
confirms the task is complete without running the next task.

A task whose success can only be confirmed by running
the following task is not independently verifiable.
Rewrite it.

**Good VERIFY:** `curl http://localhost:3000/health`
Expected: `{"status":"ok"}`
Does not depend on any other task running.

**Bad VERIFY:** "Run T-003 and confirm it doesn't fail."
T-003 failing could mean T-002 failed or T-003 has its own bug.
This makes debugging impossible.

**Rule for tasks with Supabase schema:**
```bash
supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_name = '[table]'"
# Must return exactly 1 row
```
This confirms the table exists independently of any application code.

---

## PRINCIPLE 8 — FAIL EXPLICITLY, NEVER SILENTLY

**The rule:**
Every function that can fail must return an explicit error.
Never swallow errors. Never log and continue.
Every REPORT section must have both PASS and FAIL formats.

**In code:**
```typescript
// Bad — silent failure
const { data } = await supabase.from('table').select()
// If error is null, data may also be null — no signal

// Good — explicit failure
const { data, error } = await supabase.from('table').select()
if (error) {
  console.error('Query failed:', error.message)
  throw new Error(`Supabase query failed: ${error.message}`)
}
```

**In task REPORT sections:**
Every task must specify what failure looks like, not just success.
If Clemenza cannot define what failure looks like, the acceptance
criteria are not specific enough.

---

## PRINCIPLE 9 — NATIVE MODULES NEED NATIVE ENVIRONMENTS

**The rule:**
Some packages require native compilation and cannot run in
plain Node.js, browsers, or test environments.

**Known native dependencies per stack:**

| Package | Requires | Cannot run in |
|---------|---------|--------------|
| WatermelonDB (SQLite) | React Native / Expo | Node.js, browser |
| expo-sqlite | Expo | Node.js, browser |
| Detox | iOS/Android runtime | CI without emulator |
| react-native-vision-camera | Native camera | Simulator without setup |

**Rule for tasks involving native dependencies:**
Do not write Vitest tests that import native modules directly.
Abstract native dependencies behind an interface.
Test the interface contract with mocked implementations.
Test the native integration separately on device or simulator.

**Example — WatermelonDB abstraction:**
```typescript
// Interface (testable with Vitest)
interface LocalStore {
  getPendingItems(): Promise<SyncQueueItem[]>
  markCompleted(id: string): Promise<void>
  markFailed(id: string, error: string): Promise<void>
}

// Production implementation (WatermelonDB — needs Expo)
class WatermelonLocalStore implements LocalStore { ... }

// Test implementation (in-memory — works in Vitest)
class InMemoryLocalStore implements LocalStore { ... }

// SyncEngine takes LocalStore interface
class SyncEngine {
  constructor(private store: LocalStore) {}
}
```

---

## PRINCIPLE 10 — PROTOTYPE DATA IS PREFIXED

**The rule:**
When using the production Supabase project for prototype
or testing work, all tables are prefixed.

```
Prototype: proto_products, proto_transactions, proto_sync_events
Test:      test_products, test_transactions
Staging:   (use Supabase preview branches if available)
```

This protects production data from prototype operations.
Prefix tables are dropped cleanly after prototype is complete.
Never run prototype migration scripts against tables without prefix.

---

## PRINCIPLE 11 — NO DEPENDENCY UPGRADES MID-BUILD

**The rule:**
Never upgrade a dependency version while a build is in progress.
Dependency upgrades happen at the START of a project or between
defined milestones — never mid-task.

A dependency upgrade mid-build introduces a new variable into
an already-complex debugging surface. If something breaks,
you do not know if it is your code or the upgraded package.

**If a task requires a newer version of a package:**
Stop. Document the requirement. Raise it to Seun.
Complete the current milestone. Then upgrade as a separate,
tracked task with its own VERIFY step.

---

## APPLYING THESE PRINCIPLES TO TASK GENERATION

Michael checks every task against these principles before
including it in a PRD. Use this checklist:

```
Before adding any task to Section 12:

[ ] Does this task test logic that could be tested
    without the full stack? (Principle 1)
    If yes — rewrite to use Node.js + Vitest first.

[ ] Does this task include Supabase DDL?
    If yes — CODE section must use CLI or migration,
    not REST API. (Principle 2)

[ ] Does the VERIFY step confirm success independently?
    Not "run the next task and see". (Principle 7)

[ ] Does the REPORT section include a FAIL format?
    Not just PASS. (Principle 8)

[ ] Does the task import a native module in a Vitest test?
    If yes — abstract it behind an interface. (Principle 9)

[ ] Does the task create prototype tables?
    If yes — tables must use proto_ prefix. (Principle 10)

[ ] Does the task upgrade any dependency?
    If yes — separate task, separate milestone. (Principle 11)

[ ] Are any credentials in the CODE section as literal values?
    If yes — replace with process.env.VARIABLE_NAME. (Principle 6)
```
