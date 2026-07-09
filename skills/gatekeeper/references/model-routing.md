# Family Model Routing Table

**Last updated:** 2026-05-30
**Source:** SOUL.md §MODEL ROUTING

---

## Routing Philosophy

Match model capability to task criticality. Never overpay for monitoring. Never underpower judgment.

---

## Primary — deepseek-v4-pro (DeepSeek native)

**Default for all agents.** Used for orchestration, execution, and general reasoning.

| Agent | Role | 
|-------|------|
| The Don | Orchestration and routing |
| Michael | Conversational intake |
| Clemenza | All builds and code execution |
| Virgil | ERP migration |
| Apollonia | Design concepts |
| Sollozzo | Career preparation |
| Tom | Claim review |

---

## Planning (high-stakes) — anthropic/claude-sonnet-4-6 (via OpenRouter)

**Michael only.** Activated explicitly for PRD generation and complex intake requiring multi-turn reasoning.

---

## Ops — deepseek-v4-flash (DeepSeek native)

**Monitoring, structure, deterministic tasks.**

| Agent | Role |
|-------|------|
| Luca | Pre-flight checks (boolean pass/fail) |
| Consigliere | Briefings, cron jobs, monitoring |
| Hagen | Document generation (templated output) |
| Abbandando | Archiving (filing, not interpretation) |
| Fredo | Security scans (pattern-matching) |
| Kay | Copy and content writing |

---

## Vision — google/gemini-2.5-flash (via OpenRouter)

| Agent | Use |
|-------|-----|
| Michael | Screenshot analysis, visual review |
| Virgil | Notebook OCR, handwritten records |
| Apollonia | Design file reading, brand extraction |

Activate when input contains: image, screenshot, PDF, photo, or any non-text file requiring visual analysis.

---

## Image Generation — fal-ai/flux-2-pro (via FAL)

Apollonia output only.

---

## Delegation Default

**Any subagent not listed above:** deepseek-v4-pro

---

## Override Pattern

When a task requires a different model than the agent's default:

```javascript
delegate_task(
  goal="...",
  model="anthropic/claude-sonnet-4-6",  // override
  toolsets=["file", "web"]
)
```

**Valid reasons to override:**
- Task complexity exceeds agent's tier (e.g., PRD needs Claude)
- Specialized model needed (e.g., vision for image analysis)

---

## Verification

```bash
# System default
hermes config show | grep -i model

# Agent-specific (if hardcoded in skill)
grep -rn "model=" ~/.hermes/skills/openclaw-imports/*/SKILL.md
```

---

## Related

- SOUL.md §MODEL ROUTING — authoritative source
- ~/.hermes/config.yaml — system and delegation defaults
- `references/deepseek-native-config.md` — DeepSeek native provider setup + OpenRouter fallback fix
