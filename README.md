# Hermes Family — Delivery Operating System

**Build your own AI delivery team. Pick your agents. Name them. Deploy.**

---

## What This Is

A white-label installer that turns a fresh [Hermes Agent](https://github.com/NousResearch/hermes-agent) installation into a personalized delivery OS with up to 13 specialized AI agents.

You don't get all 13. You pick the ones that match your work. A solo developer building SaaS doesn't need ERP agents. A freelancer doesn't need a career pipeline. No bloat — cherry-pick what you need.

---

## The Agents (Modular — Opt In)

| Tier | Agents | What they do |
|------|--------|-------------|
| **Core** (always included) | Orchestrator, Gatekeeper | Routing, delegation, credential health, security pre-flights |
| **Delivery** | Strategist, Builder, Monitor | Client intake, PRDs, coding, deployments, daily briefings |
| **Creative** | Designer, Writer, Doc Builder | Logos, copy, blog posts, PDFs, invoices, proposals |
| **Security** | Security Scanner | Pre-push, post-staging, post-production code scans |
| **ERP** | ERP Specialist | Inventory/POS builds for African SMEs, data migration |
| **Career** | Career Pipeline (3 agents) | Job applications, CV tailoring, cover letters (isolated from client data) |

---

## Quick Start

### Prerequisites

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) installed
- [Git](https://git-scm.com/downloads) installed and in your PATH
- That's it. The installer handles the rest.

### One Command

**macOS / Linux / WSL:**
```bash
curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.ps1 | iex
```

Then in Hermes:

```
load family-installer
```

The wizard interviews you, you pick your agents, name them, configure your stack. ~15 minutes.

---

## What Gets Created

```
~/.hermes/
├── soul-custom.md          # Your personalized SOUL.md
├── memories/
│   ├── USER.md             # Your profile
│   └── MEMORY.md           # System memory
├── skills/                 # Only the skills your agents need
├── credentials-needed.txt  # Which API keys to add
└── skills-to-install.md    # Manifest of installed skills
```

---

## Adding Agents Later

You're not locked in. After initial setup:

```
add the Designer
add Security Scanner
add career pipeline
```

Each new agent gets named, their skills installed, and your SOUL.md updated.

---

## File Structure

```
hermes-family/
├── bootstrap.sh              # One-liner installer
├── README.md                 # This file
├── family-installer/
│   └── SKILL.md              # The onboarding wizard skill
└── skills/                   # 41 Family Skills
    ├── gatekeeper/
    ├── builder/
    ├── coding-project/
    ├── designer/
    ├── writer/
    └── ... (40+ more)
```

---

## Requirements After Setup

The only things you bring:
- API keys (DeepSeek, Supabase, Vercel, GitHub, etc.)
- The installer tells you exactly which ones based on your agent choices

---

## License

MIT — build your own family. The architecture is open. Your agent names, your business, your rules.
