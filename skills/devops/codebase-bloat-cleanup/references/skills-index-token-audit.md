# Measuring Skills Index Token Cost

## Quick Measurement

```python
# From any Hermes-agent context
from agent.prompt_builder import build_skills_system_prompt
result = build_skills_system_prompt()
chars = len(result)
tokens = chars // 4  # rough: 4 chars per token
print(f"Skills index: {chars:,} chars / ~{tokens:,} tokens")
```

## Break Down by Category

```python
from agent.prompt_builder import build_skills_system_prompt
result = build_skills_system_prompt()
# Count lines per category section
for line in result.split('\n'):
    if line.startswith('  ') and not line.startswith('    '):
        print(line)
```

## Bulk Disable Unused Default Skills

```bash
# List all enabled skills
/app/venv/bin/hermes skills list

# Disable by name (interactive or scripted)
/app/venv/bin/hermes skills config --disable <skill-name>

# Or edit ~/.hermes/config.yaml directly:
# skills:
#   disabled:
#     - ascii-art
#     - gaming
#     - gifs
```

## Verifying the Reduction

```python
from agent.prompt_builder import build_skills_system_prompt

before = build_skills_system_prompt()  # with all skills
print(f"Tokens before: {len(before)//4}")

# After disabling: the cache invalidates automatically on next call
after = build_skills_system_prompt()
print(f"Tokens after:  {len(after)//4}")
print(f"Saved:         {len(before)//4 - len(after)//4}")
```

## What Gets Indexed

The skills prompt builder scans `~/.hermes/skills/` recursively, reads every
`SKILL.md`, and extracts:
- The skill's `name` (from frontmatter or directory name)
- The `description` (from frontmatter; capped at 60 chars by convention)
- The `category` (from parent directory name)

Category-level `DESCRIPTION.md` files are also included if present.

Skills are EXCLUDED from the index if:
- They are in the `disabled` list in config.yaml
- Their `platforms` frontmatter doesn't match the current platform
- Their `conditions` (`requires_tools`, `requires_toolsets`) aren't met
- They are in an external directory that isn't in the config

Skills are NOT indexed from directories outside `~/.hermes/skills/` unless
those directories are listed in `skills.external_dirs` in config.yaml.
