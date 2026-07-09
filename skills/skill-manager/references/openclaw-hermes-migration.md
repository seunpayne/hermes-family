# OpenClaw → Hermes Skill Migration Reference

## Purpose

This document captures the systematic migration patterns for converting OpenClaw-era skills to Hermes conventions. Use this when auditing remaining openclaw-imports skills or when importing new legacy skills.

## Migration Checklist

When reviewing a skill file, search for these patterns in order:

### 1. Path References
```
Search: ~/.openclaw/
Replace: ~/.hermes/
```

### 2. Environment Files
```
Search: ~/.env.openclaw
Replace: ~/.env.hermes
```

### 3. Subagent Spawning
```
Search: sessions_spawn({
  runtime: "opencode",
  pty: true,
  background: true,
  cwd: "...",
  prompt: "..."
})

Replace:
delegate_task(
  goal="[task from prompt field]",
  context="Project path: [cwd value]. [all relevant context: project IDs, Supabase URL, brand tokens, GitHub repo, staging URL].",
  toolsets=["terminal", "file"],  // adjust per task
  model="[appropriate model per SOUL.md routing]",
  base_url="http://localhost:11434/v1"
)

Critical: Hermes subagents start with zero parent context.
Everything must be in the context field.
```

### 4. Notification Patterns
```
Search: openclaw message send
Replace: send_message(content="[message]", platform="telegram")

Note: delegate_task results are returned automatically.
No manual notification needed for subagent completion.
```

### 5. Tool/API References
```
Search: openclaw gateway, openclaw heartbeat, openclaw cron
Replace: Hermes gateway, Hermes cronjob tool, or remove if handled by gateway
```

### 6. Model References
```
Search: GPT-5, gpt-4-vision, openai, OpenAI
Replace: anthropic/claude-sonnet-4-6 (for vision/high-stakes tasks per SOUL.md)

Exception: If skill uses image_gen tool natively, no model override needed.
```

### 7. CLI Tool References
```
Search: OpenClaw's `cron` tool, openclaw message
Replace: Hermes `cronjob` tool, Hermes `send_message` tool
```

## Skills Migrated (Session: 2026-05-19)

| Skill | Lines Changed | Patterns Found |
|-------|---------------|----------------|
| web-builder | 1 | Removed obsolete notification rule |
| account-manager | 4 | Paths (3), cron tool reference (1) |
| erp-migration | 1 | OCR model (GPT-5 → anthropic/claude-sonnet-4-6) |
| designer | 2 | Design system paths |
| writer | 3 | Environment variable paths |
| doc-builder | 0 | Already clean |
| security-reviewer | 3 | .gitignore patterns, exclusion rule |

## Patterns NOT Found (Good to Know)

- No `background_session` calls in any skill
- No direct `curl` API calls for image generation (all documented fal.ai usage was reference only)
- No `openclaw message send` hardcoded notifications
- No `sessions_spawn` in most skills (they were documentation/reference files, not execution scripts)

## Model Routing Reference (from SOUL.md)

When replacing `sessions_spawn` with `delegate_task`, use these models:

| Agent | Model | Purpose |
|-------|-------|---------|
| Clemenza (code) | deepseek-v4-pro | All build/code execution |
| Clemenza (non-code) | anthropic/claude-sonnet-4-6 | Reasoning, planning |
| Fredo | deepseek-v4-pro | Security scans |
| Kay | deepseek-v4-pro | Copy/content writing |
| Hagen | deepseek-v4-flash | Document generation |
| Consigliere | deepseek-v4-flash | Monitoring, briefings |
| Virgil | anthropic/claude-sonnet-4-6 | ERP migration, NDPR decisions |
| Apollonia | anthropic/claude-sonnet-4-6 | Brand decisions, design review |

## Verification Steps

After migrating a skill:

1. **Search again** to confirm no patterns were missed:
   ```bash
   grep -r "openclaw\|~/.openclaw\|sessions_spawn" ~/.hermes/skills/openclaw-imports/[skill-name]/
   ```

2. **Check environment variables** section for `.env.openclaw` references

3. **Verify model assignments** match SOUL.md family model routing

4. **Test activation** — load the skill and confirm it activates without errors

5. **Update this reference** — add the skill to the "Skills Migrated" table

## Remaining Skills to Audit

Check these openclaw-imports skills for migration patterns:
- [ ] client-onboarding
- [ ] content-pipeline
- [ ] marketing-pipeline
- [ ] project-manager
- [ ] site-reviewer
- [ ] super-prompt-builder
- [ ] db-backup
- [ ] system-backup
- [ ] system-restore
- [ ] domain-manager
- [ ] gatekeeper / gatekeeper-agent
- [ ] nodejs-backend-patterns
- [ ] nodejs-best-practices
- [ ] supabase-postgres-best-practices
- [ ] career-archivist
- [ ] career-preparer
- [ ] career-reviewer
- [ ] strategist
- [ ] architect
- [ ] builder
- [ ] auth-manager
- [ ] designer (separate from image-gen)

## Notes

- Most skills were **documentation/reference files** without executable `sessions_spawn` calls
- The migration is primarily **path updates** and **tool name changes**
- No skills required structural rewrites — all were find-and-replace patterns
- Fredo's security checks use **direct terminal commands** (trufflehog, observatory-cli, npm audit) — these do not need `delegate_task` wrapping
