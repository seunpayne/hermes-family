---
name: family-installer
description: Modular white-label onboarding for Hermes. Pick your agents, name them, configure your stack. Stamps out a personalized SOUL.md with only the opted-in family members and their skills. No bloat — cherry-pick what you need.
version: 2.0
---

# Family Installer v2.0 — Modular Opt-In

## What This Is

This skill turns a brand new Hermes installation into a personalized
delivery operating system. The difference from v1.0: **you don't get
all 13 agents.** You opt in to the ones you need, name them, and
get only their skills. No bloat.

## Distribution

The installer ships as part of the `hermes-family` repo.
New users install it via:

```bash
curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
```

The bootstrap script clones the repo (private — invite-only) and places
the installer skill at `~/.hermes/skills/family/family-installer/`.

The repo also contains: all 41 Family Skills in `skills/`, marketing copy in
`marketing/copy.md`, and Nigerian pricing in `marketing/pricing.md`.

---

## THE 13 AGENTS — AS MODULES

Each agent is a self-contained module: role + permissions + bundled skills.
The user picks which ones to activate.

### CORE — Non-Negotiable (Always Installed)

These two are the kernel. The system cannot function without them.

| # | Agent | Role | Bundled Skills |
|---|-------|------|----------------|
| 1 | **Orchestrator** | Routing, delegation, all top-level decisions. Never executes. | None — orchestrator only routes to other agents |
| 2 | **Gatekeeper** | Pre-flight checks before any agent runs. Blocks if credentials missing or policy violated. Credential health monitoring. | `gatekeeper`, `gatekeeper-agent`, `auth-manager` |

> These are always stamped into SOUL.md. No opt-out.

---

### DELIVERY — The Build Pipeline

The agents that actually build things. Pick the ones that match your work.

| # | Agent | Role | Bundled Skills | Recommended For |
|---|-------|------|----------------|-----------------|
| 3 | **Strategist** | Intake, PRD generation, brief shaping. Read-only. Never executes code. | `strategist`, `client-onboarding`, `sales-proposal-generator` | Anyone taking client briefs or planning projects |
| 4 | **Builder** | All code — writes, commits, pushes, deploys. Only agent that touches git and deploy CLI. | `builder`, `coding-project`, `web-builder`, `site-reviewer`, `supabase-cli-operations` | Anyone building apps, websites, APIs |
| 5 | **Monitor** | Scheduled briefings, cron jobs, task tracking, pipeline oversight. | `account-manager`, `task-management`, `project-manager`, `db-backup`, `skill-manager` | Anyone wanting proactive monitoring and daily briefings |

---

### CREATIVE — Design, Copy, Documents

Visual and written output. Opt in if you produce client-facing assets.

| # | Agent | Role | Bundled Skills | Recommended For |
|---|-------|------|----------------|-----------------|
| 6 | **Designer** | All visual design — logos, images, diagrams, design reviews. | `designer`, `architecture-diagram` | Anyone needing logos, hero images, design systems |
| 7 | **Writer** | All copy and content. Voice authority for client-facing text. | `writer`, `content-pipeline`, `marketing-pipeline` | Anyone producing blogs, social, web copy, launch content |
| 8 | **Doc Builder** | PDFs, DOCX, invoices, proposals, formal docs. | `doc-builder`, `doc-builder-agent`, `nano-pdf`, `pdf-form-filler` | Anyone sending client proposals, invoices, reports |

---

### SECURITY — Code Safety

| # | Agent | Role | Bundled Skills | Recommended For |
|---|-------|------|----------------|-----------------|
| 9 | **Security Scanner** | Pre-push, post-staging, post-production security scans. | `security-reviewer` | Anyone deploying to production. Recommended but optional. |

---

### ERP — Nigerian SME Systems

| # | Agent | Role | Bundled Skills | Recommended For |
|---|-------|------|----------------|-----------------|
| 10 | **ERP Specialist** | ERP builds and client data migration for Nigerian SMEs. | `erp-client-onboarding`, `erp-migration`, `erp-super-prompt-builder`, `nodejs-backend-patterns`, `nodejs-best-practices`, `supabase-postgres-best-practices` | Anyone building ERP/inventory/POS systems for African SMEs |

---

### CAREER — Personal Job Pipeline

Isolated from client data. For the owner's personal career moves only.

| # | Agent | Role | Bundled Skills | Recommended For |
|---|-------|------|----------------|-----------------|
| 11 | **Career Preparer** | Job applications, CV tailoring, cover letters. | `career-preparer` | Anyone actively job hunting |
| 12 | **Career Reviewer** | Reviews applications and claim quality. | `career-reviewer` | Pairs with Career Preparer |
| 13 | **Career Archivist** | Archives completed applications. | `career-archivist` | Pairs with the other career agents |

> Career agents are a package deal — if you opt into one, you get all three. They share isolated tables and skills.

---

### OPERATIONS — System Maintenance (Auto-Included with Monitor)

| Skill | Bundled With | Purpose |
|-------|-------------|---------|
| `system-backup` | Monitor | Weekly full-system backup |
| `system-restore` | Monitor | Full system rebuild on fresh machine |
| `hermes-migration` | Monitor | Migrate installation to new machine |
| `hermes-permissions-repair` | Monitor | Fix Docker container file permissions |
| `domain-manager` | Builder | Vercel domain configuration |
| `codebase-bloat-cleanup` | Builder | Dead code removal |
| `emergency-hotfix` | Builder | Production emergency revert protocol |
| `super-prompt-builder` | Strategist | Structured super prompts for web/ERP builds |

---

## ACTIVATION

When loaded on a fresh Hermes install:

> "Welcome. I'm going to set up your delivery operating system —
> but only the parts you need.
>
> I'll ask who you are, then show you the 13 available agents
> organized by what they do. You pick the ones that match your work.
> Skip the rest. No bloat.
>
> Ready? Let's start with who you are."

---

## SECTION 1 — OWNER IDENTITY

Ask one field at a time. Wait for each answer.

**Q1.1:** "What should the family call you?"
→ `owner_name` — how agents address you

**Q1.2:** "What's your handle?"
→ `owner_handle` — used in SOUL.md, memory tags

**Q1.3:** "What timezone are you in?"
→ `timezone` — all schedules use this
→ Examples: Africa/Lagos, America/New_York, Europe/London

**Q1.4:** "Where are you based? City, country."
→ `location` — cultural context for design

**Q1.5:** "What do you build? One sentence."
→ `business_description`
→ Example: "Freelance web developer building sites for restaurants"
→ Example: "Solo founder building a SaaS for property managers"

**Q1.6:** "Email for client-facing work?"
→ `business_email`

---

## SECTION 2 — PICK YOUR AGENTS

Present the modules as opt-in checkboxes. Group by category.

> "Now the agents. I'll show you what's available, grouped by
> what they do. The Core two are always included — everything
> else is optional.
>
> For each group, tell me which ones you want. You can say
> 'all', 'none', or pick specific agents by number."

### 2.1 — CORE (Always Included)

```
✓ Orchestrator — Routing, delegation, top-level decisions
✓ Gatekeeper — Pre-flight checks, credential monitoring
```

> "These two are your kernel. They come with every installation."

### 2.2 — DELIVERY

```
3. [ ] Strategist — Client intake, PRDs, briefs, proposals
4. [ ] Builder — All code, git, deployments
5. [ ] Monitor — Daily briefings, cron jobs, task tracking
```

> "These are your build pipeline. If you're building anything,
> you want the Builder. If you have clients, you want the
> Strategist. If you want the system to check in on you
> proactively, you want the Monitor."

Ask: "Which delivery agents do you want? (3/4/5/all/none)"

### 2.3 — CREATIVE

```
6. [ ] Designer — Logos, images, diagrams, design reviews
7. [ ] Writer — Copy, blog posts, social, launch content
8. [ ] Doc Builder — PDFs, DOCX, invoices, proposals
```

> "These produce the visual and written output. Pick the ones
> that match what you ship to clients."

Ask: "Which creative agents do you want? (6/7/8/all/none)"

### 2.4 — SECURITY

```
9. [ ] Security Scanner — Pre-push, post-staging, post-production scans
```

> "Scans your code before every push and deploy. Lightweight.
> Recommended if you're deploying anything public."

Ask: "Security Scanner? (9/skip)"

### 2.5 — ERP

```
10. [ ] ERP Specialist — Inventory/POS builds, data migration for African SMEs
```

> "Only relevant if you build ERP or inventory systems. If you
> don't know what ERP is, skip this."

Ask: "ERP Specialist? (10/skip)"

### 2.6 — CAREER

```
11-13. [ ] Career Pipeline — Job applications, CV tailoring, cover letters
```

> "Personal career support. Isolated from all client data.
> All three as a package: Preparer, Reviewer, Archivist."

Ask: "Career pipeline? (11/skip)"

### 2.7 — Show Summary

After all groups, display what was selected:

```
YOUR SELECTED AGENTS

Core:
  ✓ Orchestrator
  ✓ Gatekeeper

Delivery:
  [✓/✗] Strategist
  [✓/✗] Builder
  [✓/✗] Monitor

Creative:
  [✓/✗] Designer
  [✓/✗] Writer
  [✓/✗] Doc Builder

Security:
  [✓/✗] Security Scanner

ERP:
  [✓/✗] ERP Specialist

Career:
  [✓/✗] Career Pipeline (3 agents)

Total: [N] agents | [M] bundled skills

Look right? You can add or remove any before we proceed.
```

---

## SECTION 3 — NAME YOUR FAMILY

Only for the agents that were opted in.

> "Now let's name them. Each agent has a default name from
> The Godfather. You can keep it, rename individually, or
> use your own theme — Nigerian names, industry terms,
> Star Wars characters, whatever fits.
>
> I'll go through only the agents you selected."

For each opted-in agent, present:

```
Role: [role description]
Default name: [Godfather name]
→ "What do you want to call your [role]?"
```

After all selected agents are named, show the table:

```
YOUR FAMILY

Orchestrator:  [name]
Gatekeeper:    [name]
[+ all other opted-in agents with their names]

Does this look right?
```

---

## SECTION 4 — INFRASTRUCTURE

### Q4.1: "Which AI provider?"

```
Orchestration + Execution (day-to-day):
  a) DeepSeek — cheapest, good quality
  b) OpenRouter — multi-model, flexible
  c) OpenAI — most expensive, best quality

Planning / Heavy Lifting (strategist, if opted in):
  a) Same as orchestration
  b) DeepSeek v4 Pro
  c) Claude via OpenRouter
  d) GPT-4o via OpenAI

[IF DESIGNER OPTED IN] Image Generation:
  a) FAL (fal.ai — Flux models)
  b) DALL-E via OpenAI
  c) None — skip image generation

[IF STRATEGIST OPTED IN] Vision (screenshots, PDFs):
  a) Gemini via OpenRouter
  b) GPT-4o via OpenAI
  c) None — skip vision
```

### Q4.2: "Do you use Supabase?"
→ If yes: collect URL + service role key
→ If no: "File-based tracking only. Supabase recommended for project tracking."

### Q4.3: "Deployment platform?"

```
  a) Vercel
  b) Railway
  c) Render
  d) Manual / none yet
```

→ If opted in: collect deploy token

### Q4.4: "GitHub?"

```
  a) Yes — I'll authenticate with gh
  b) Yes — I'll provide a token
  c) No — local git only
```

### Q4.5: "Document platform?"

```
  a) Outline (self-hosted or cloud)
  b) Notion
  c) Obsidian
  d) Google Docs
  e) Just files on disk
```

### Q4.6: "Email service?"

```
  a) Resend
  b) SendGrid
  c) None
```

---

## SECTION 5 — DELIVERY PLATFORMS

### Q5.1: "Where should the family reach you?"

```
  a) Hermes WebUI only
  b) Telegram
  c) Slack
  d) Discord
  e) Multiple
```

→ WebUI is always the fallback.

### Q5.2: "Proactive or on-demand?"

```
  a) Proactive — briefings and alerts on schedule
  b) Response only — I'll ask when I need something
  c) Mixed — proactive for critical alerts only
```

---

## SECTION 6 — COMMUNICATION STYLE

### Q6.1: "How do you talk to your AI?"

```
  a) Terse — 'proceed', 'send it', one-word signals
  b) Conversational — full sentences, back and forth
  c) Professional — formal, structured, detailed
  d) Mixed — terse for approvals, conversational for planning
```

### Q6.2: "Response detail?"

```
  a) Minimal — just what I need
  b) Standard — context included, concise
  c) Detailed — full breakdowns
```

### Q6.3: "Pet peeves?"

→ Free text. Examples: "Don't repeat my instructions," "Never say 'certainly!'"

### Q6.4: "Approval style?"

```
  a) Explicit — approve staging before production, every time
  b) Trust but verify — stage freely, ask before production
  c) Full autonomy — deploy when ready, report after
```

---

## SECTION 7 — STAMP OUT

### 7.1 — Confirm

Show a complete summary of all answers. Ask:

> "Ready to stamp out your system? This creates SOUL.md, memory,
> and installs only the skills for your [N] selected agents.
> Say 'stamp it' to proceed."

### 7.2 — Generate SOUL.md

Create `~/.hermes/soul-custom.md` with ONLY the opted-in agents.

The template is dynamic — sections only appear if the corresponding
agent was opted in. Structure:

```markdown
# SOUL.md — v1.0 ([OWNER_NAME]'s Delivery OS)
# Generated: [TIMESTAMP] via family-installer v2.0
# Active agents: [N] of 13

---

## IDENTITY

[Always included — orchestrator identity, owner info, timezone, interface]

---

## THE FAMILY — [N] AGENTS

[Only opted-in agents listed here]

---

## SESSION STARTUP — [GATEKEEPER_NAME] RUNS FIRST

At the start of every chat session, [GATEKEEPER_NAME]:

1. **License validation** — Verifies installation authorization silently.
   If blocked, all agents are disabled with a clear message.

2. **Credential manifest** — Surfaces all credentials from `~/.hermes/.env`.
   Every key is categorized (AI, git, deploy, database, email, image, docs,
   messaging) and quick-tested for validity. Missing or expired keys are flagged.

No agent should ever ask for a credential that already exists.
[GATEKEEPER_NAME] owns this. Every session begins with license check,
then credential manifest.

---

## MODEL ROUTING

[Only the lanes relevant to opted-in agents]

---

## FOUR-LANE BOUNDARY

[Strategist/Monitor/Gatekeeper only if opted in]
[Orchestrator always included]

---

## EXECUTION GUARDS

[Only agents that exist are listed with their permissions]
[If no Builder opted in: note that no agent can execute code]

---

## ISOLATION RULE

[Only if career agents were opted in]

---

## BEFORE ANY BUILD

[Standard checks — always included]

---

## HARD RULES

[Generated from owner preferences]

---

## APPROVAL GATES

[Generated from Q6.4]

---

## SECURITY TRIGGERS

[Only if Security Scanner was opted in]

---

## WHAT I NEVER DO

[Standard guardrails — always included]

---

## SKILL ROUTING

[Only skills for opted-in agents]
```

### 7.3 — Generate Memory Files

**USER.md** — owner profile based on all answers.

**MEMORY.md** — system state, opted-in agents, infrastructure summary.

### 7.4 — Generate Credential Template

Only include credentials relevant to opted-in choices.
If they skipped FAL/Designer → no FAL_KEY in the template.

### 7.5 — Install Skills

Copy only the skills for opted-in agents from the family repo.

**Primary source:** `~/hermes-family/skills/` (created by bootstrap.sh)

```bash
# For each opted-in agent, copy their bundled skills
# Source: ~/hermes-family/skills/[skill-name]
# Target: ~/.hermes/skills/[skill-name]
cp -r ~/hermes-family/skills/[skill-name] ~/.hermes/skills/
```

**Fallback source:** `~/.hermes/skills/Family Skills/` (if running on the original development machine)

If neither source is available:
→ "The Family Skills aren't available locally. Clone the repo first:"
→ `git clone https://github.com/seunpayne/hermes-family.git ~/hermes-family`
→ Then re-run stamp-out.

Skills that no opted-in agent needs are NOT copied. No bloat.

### 7.5b — Install Reference Artifacts

Skills reference external data that doesn't live inside skill directories.
Install these now.

**Playbooks** — Stack-specific build guides referenced by SOUL.md skill routing:

```bash
# Copy playbooks from the family repo
mkdir -p ~/.hermes/playbooks
cp ~/hermes-family/artifacts/playbooks/* ~/.hermes/playbooks/
```

Playbooks included:
- `universal-principles.md` — Stack selection decision tree
- `web-react-vite-supabase-vercel.md` — Website build playbook
- `erp-react-native-watermelondb-supabase.md` — ERP build playbook
- `dapp-evm-hardhat-wagmi.md` — DApp build playbook
- `api-nodejs-fastify-supabase-railway.md` — API build playbook
- `ai-chatbot-anthropic-supabase-react.md` — AI chatbot playbook
- `lovable-decoupling.md` — Lovable migration playbook
- `whatsapp-business-api-supabase.md` — WhatsApp integration playbook

**Design Systems** — 153 brand-grade DESIGN.md files from Open Design:

```bash
# Clone design systems from open-design repo (sparse checkout — only design-systems/)
mkdir -p ~/.hermes/design-systems
cd /tmp && rm -rf open-design
git clone --depth 1 --filter=blob:none --sparse https://github.com/nexu-io/open-design.git
cd open-design && git sparse-checkout set design-systems
cp -r design-systems/* ~/.hermes/design-systems/
rm -rf /tmp/open-design
```

This gives the Designer agent access to 153 design systems including:
stripe, linear-app, vercel, supabase, notion, apple, airbnb, spotify,
figma, sentry, coinbase, nvidia, and 140+ more.

Each is a `DESIGN.md` file with: colour palette, typography rules, spacing,
component styles, motion, voice, brand, and anti-pattern documentation.

Only installed if the Designer agent was opted in.

### 7.6 — Flag Owner-Specific Skills

If any opted-in skills have owner-specific content (farocon-quoting,
erp-client-onboarding pricing, sales-proposal-generator location, etc.),
flag them explicitly:

> "[N] skills contain references to the previous owner's business.
> Review these before using: [list]"

Skills that weren't opted in don't need flagging — they weren't copied.

### 7.7 — Final Message

> "Your delivery operating system is ready — [N] agents, [M] skills.
>
> **What was created:**
> - `~/.hermes/soul-custom.md` — personalized SOUL.md for your [N]-agent family
> - `~/.hermes/memories/USER.md` + `MEMORY.md`
> - `~/.hermes/credentials-needed.txt` — only the keys you actually need
> - `~/.hermes/skills/` — [M] skills installed for your agents
>
> **[IF FLAGGED]:**
> "[N] skills need review for owner-specific content."
>
> **Next steps:**
> 1. Load soul-custom.md as your system prompt
> 2. Add API keys to `~/.env.hermes`
> 3. Review flagged skills if any
> 4. Say 'system check' to verify
>
> You can always add more agents later. Just say 'add the Designer'
> or 'add career pipeline' and I'll install what's needed.
>
> Welcome to the family, [OWNER_NAME]."

### 7.8 — Offer Cron Jobs

Only if Monitor was opted in:

> "Want me to schedule your first daily briefing?"

If yes: create starter cron jobs in owner's timezone.

---

## ADDING AGENTS LATER

The system is designed for expansion. When the owner says:

- "add the Designer" → install designer skill, add to SOUL.md, name the agent
- "add career pipeline" → install all 3 career skills, add to SOUL.md, name them
- "add Security Scanner" → install security-reviewer skill, add Fredo triggers

The installer skill handles incremental additions — no need to re-run
the full wizard.

---

## HARD RULES

1. **One question at a time.** Never dump all options at once.
2. **Skip what's not opted in.** No orphan references in SOUL.md.
3. **Only copy skills for opted-in agents.** Don't install what won't be used.
4. **Never overwrite existing SOUL.md or memory** without confirmation.
5. **All opted-in agents must be named** before stamping.
6. **'keep defaults' is valid for any section** — accept and move on.
7. **Language-match the owner.** Pidgin, Yoruba, Spanish, whatever they use.
8. **Career is a package deal.** All three or none.
9. **Core is non-negotiable.** Orchestrator + Gatekeeper always included.

---

## PITFALLS

### No GitHub token in container
The installer skill cannot create repos or push from inside a Docker container
without `gh` CLI or `GITHUB_TOKEN`. Repo creation must be done from the owner's
machine. The bootstrap.sh script handles the curl-and-install flow — no GitHub
auth needed for installation, only for the initial repo push.

### Skills not found at stamp-out time
Section 7.5 tries `~/hermes-family/skills/` first (created by bootstrap.sh),
then falls back to `~/.hermes/skills/Family Skills/` (original source machine).
If neither exists, instruct the user to clone the repo manually before retrying.
Never proceed with stamp-out if skills are missing — an empty skill directory
produces non-functional agents.

### Owner-specific content in bundled skills
Five skills contain references to the original owner's business: `farocon-quoting`
(FAROCON LIMITED), `erp-client-onboarding` (₦ pricing tiers), `sales-proposal-generator`
(Abuja SME focus), `client-discovery` (Abuja market targeting), and
`super-prompt-builder` (original owner's design taste). Always flag these after
stamp-out if any were among the opted-in skills. Do NOT silently install them.

---

## REFERENCES

- `references/repo-structure.md` — Directory layout of the hermes-family GitHub repo and install flow
- `references/marketing-copy.md` — Six ad formats (one-liner through LinkedIn post) for promoting the installer
- `references/pricing.md` — Nigerian pricing tiers, installment plans, beta discounts, add-ons, and pitch lines
