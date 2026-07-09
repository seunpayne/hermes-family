# .env File Reading: Terminal Truncation Gotcha

## The Problem

When you `cat ~/.hermes/.env` in a terminal, long lines are **visually truncated** with `...` in the middle. The file on disk has the complete value — only the display is cut off.

**This causes the agent to incorrectly believe keys are missing/truncated and ask the user to re-paste them.** The user gets frustrated ("I cannot keep pasting keys na").

## The Fix

**Never ask the user to re-paste a key without first verifying the actual file contents with Python.**

### Step 1 — Check Lengths

```bash
python3 -c "
with open('/home/hermeswebui/.hermes/.env') as f:
    for line in f:
        line = line.strip()
        if '=' in line:
            k, v = line.split('=', 1)
            print(f'{k}: {len(v)} chars')
"
```

### Step 2 — Expected Lengths Reference

| Key | Expected Length | Pattern |
|-----|----------------|---------|
| DEEPSEEK_API_KEY | 35 | `sk-` + 32 hex |
| OPENROUTER_API_KEY | ~73 | Variable length |
| SUPABASE_URL | ~40 | `https://*.supabase.co` |
| SUPABASE_SECRET_KEY | 41 | `sb_secret_` + 32 chars |
| SUPABASE_ANON_KEY | 46 | `sb_publishable_` + 34 chars |
| RESEND_API_KEY | 36 | `re_` + rest |
| BROWSER_USE_API_KEY | 46 | `bu_` + rest |
| FAL_KEY | 69 | UUID + `:` + hex |
| VERCEL_TOKEN | ~60 | `vcp_` + rest |
| TAVILY_API_KEY | ~58 | `tvly-` + rest |
| FIGMA_ACCESS_TOKEN | ~45 | `figd_` + rest |
| N8N_API_TOKEN | ~272 | JWT (three base64 segments) |
| GITHUB_TOKEN | ~40 | `ghp_` or `github_pat_` |

### Step 3 — Verify Full Value (if still unsure)

```bash
python3 -c "
with open('/home/hermeswebui/.hermes/.env', 'rb') as f:
    for line in f:
        if line.startswith(b'SUPABASE_SECRET_KEY='):
            val = line.split(b'=', 1)[1].strip()
            print(f'Value: {val.decode()}')
            print(f'Hex: {val.hex()}')
            print(f'Length: {len(val)}')
"
```

### When to Actually Ask for a Re-Paste

Only ask if:
- The length doesn't match expected (see table above)
- The value starts with `***` — those are genuine placeholders
- The file doesn't exist yet (fresh migration, no .env)
- The user explicitly says they haven't populated it yet
