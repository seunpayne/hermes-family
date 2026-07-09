# DeepSeek Native Provider Configuration

**Last verified:** 2026-05-30

---

## The Problem

DeepSeek models were routing through OpenRouter even though the config specified `provider: deepseek`. Token usage showed on OpenRouter dashboard but zero on native DeepSeek.

## Root Cause

`base_url` was missing. Without `https://api.deepseek.com`, Hermes could not resolve where to send native DeepSeek API calls and silently fell back to OpenRouter (which lists DeepSeek models in its catalog).

## Fix (3 commands)

```bash
# 1. Set base URL for main model
hermes config set model.base_url https://api.deepseek.com

# 2. Set base URL for delegation/subagents
hermes config set delegation.base_url https://api.deepseek.com

# 3. Lock ALL auxiliary providers to deepseek (prevent auto-resolve to OpenRouter)
hermes config set auxiliary.compression.provider deepseek
hermes config set auxiliary.skills_hub.provider deepseek
hermes config set auxiliary.approval.provider deepseek
hermes config set auxiliary.title_generation.provider deepseek
hermes config set auxiliary.triage_specifier.provider deepseek
hermes config set auxiliary.kanban_decomposer.provider deepseek
hermes config set auxiliary.profile_describer.provider deepseek
hermes config set auxiliary.curator.provider deepseek
```

## Verification

```bash
# Check routing is locked
hermes config show | grep -i "model\|provider"

# Expected output:
#   Model: deepseek-v4-pro, provider: deepseek, base_url: https://api.deepseek.com
#   Delegation: deepseek-v4-pro, provider: deepseek, base_url: https://api.deepseek.com
#   Vision: provider=openrouter (only model using OpenRouter)
#   All auxiliary: provider: deepseek
```

## Config Structure (correct)

```yaml
model:
  default: deepseek-v4-pro
  base_url: https://api.deepseek.com
provider:
  name: deepseek
  api_key_env: DEEPSEEK_API_KEY
fallback_model:
  provider: deepseek
  model: deepseek-v4-flash
delegation:
  model: deepseek-v4-pro
  provider: deepseek
  base_url: https://api.deepseek.com
```

## Only OpenRouter Routes

After fix, only two paths use OpenRouter:
- **Vision:** `google/gemini-2.5-flash` (no DeepSeek equivalent)
- **Michael PRD:** `anthropic/claude-sonnet-4-6` (explicitly set, not DeepSeek)

No DeepSeek model should EVER touch OpenRouter.
