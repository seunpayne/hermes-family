# Hermes WebUI Bloat Cleanup — June 2026 Session

This file captures the concrete findings and savings from a real cleanup pass
on the Hermes WebUI codebase. Use as a benchmark when auditing similar projects.

## Scope

- **LLM-side (per-message)**: Tool descriptions injected every turn
- **Frontend (per-page-load)**: i18n locale data, CSS selectors
- **Backend**: Python dead code (imports, functions, constants)

## Token Savings: Tool Descriptions

| Tool File | Before (chars) | After (chars) | Saved | ~Tokens/Msg |
|-----------|-------|------|-------|:----------:|
| `terminal_tool.py` | ~3,445 | ~775 | ~2,670 | ~670 |
| `file_tools.py` | ~1,416 | ~825 | ~591 | ~150 |
| `cronjob_tools.py` | ~4,930 | ~1,750 | ~3,180 | ~795 |
| `browser_tool.py` | ~2,835 | ~1,360 | ~1,475 | ~370 |
| `web_tools.py` | ~630 | ~320 | ~310 | ~78 |
| `send_message_tool.py` | ~770 | ~340 | ~430 | ~108 |
| `skills_tool.py` | ~410 | ~250 | ~160 | ~40 |
| **Total** | **~14,436** | **~5,620** | **~8,816 chars** | **~2,200** |

### Patterns Removed

1. **Cross-tool routing advice** (~750 chars in file_tools alone):
   - "Do NOT use cat/head/tail — use read_file instead"
   - "Use this instead of grep/rg/find/ls"
   - "For simple info retrieval, prefer web_search"
   
2. **Implementation details**:
   - "Ripgrep-backed, faster than shell equivalents"
   - "only NEW errors introduced by this write are surfaced"
   - "HARD RATE LIMIT: at most 1 notification per 15 seconds per process — ..."

3. **Usage-guidance paragraphs** (heaviest in terminal_tool and cronjob_tools):
   - Background-pattern paragraphs explaining two-use-case model
   - Behavioral instructions ("When the user asks to send to...")
   - Platform examples in parameter descriptions (10+ examples)

4. **Training-in-parameter-descriptions**:
   - `watch_patterns` param had ~880 chars of rate-limit documentation
   - `deliver` param had ~870 chars of platform-specific examples
   - `no_agent` param had ~830 chars of behavioral design doc

## Frontend Savings

| File | Before | After | Saved |
|------|-------|------|-------|
| `static/i18n.js` | 15,551 lines / 976 KB | 1,495 lines / 81 KB | **895 KB (91.7%)** |
| `static/style.css` | 4,819 lines | 4,812 lines | 7 lines (3 unused selectors) |

### i18n Lazy-Loading Architecture

- Created `static/i18n/{de,en,es,fr,it,ja,ko,pt,ru,tr,zh}.js`
- Each file: `(window.LOCALES=window.LOCALES||{})['xx'] = { ... }`
- Modified `setLocale()` to inject `<script>` for non-English locales
- `_LOADED_LOCALES` Set tracks which locales have been fetched
- English stays inline as fallback (`t()` falls back to `LOCALES.en[key]`)
- Balanced braces verified with `tr -cd '{'` / `tr -cd '}'` on all 11 files

## Backend Dead Code Removed

| File | Lines Removed | What |
|------|:-----------:|------|
| `api/config.py` | 52 | 3 unused imports, `CODE_EXTS` (27-line dead set), `_LEGACY_CLI_TOOLSET_ALIASES`, `_normalize_cli_toolsets()`, duplicate `import collections` |
| `api/streaming.py` | 6 | `import sys` (unused), `from api.workspace import set_last_workspace` (unused), `_dedupe_replayed_active_context()` (delegation wrapper) |
| `api/models.py` | 4 | `import collections` (unused), `clear_cli_sessions_cache()` (orphaned) |
| `api/routes.py` | 49 | Duplicate `import re`, `_clear_live_models_cache()`, `_resolve_compatible_session_model()`, `_normalize_session_model_in_place()`, `_approval_sse_notify()` |

### Key Finding: Dead Constant ≠ Dead Computing Function

`CLI_TOOLSETS` was a module-level constant with ZERO callers — safe to remove.
But `_resolve_cli_toolsets()` (the function that computes it) was imported by
both `routes.py` and `streaming.py`. Removing the constant is fine; removing
the function breaks two call sites. Always search callers of EACH symbol.

### Key Finding: `shlex` Compiles but Fails at Runtime

Removing `import shlex` from streaming.py compiled fine (`py_compile` doesn't
check runtime symbol resolution), but `shlex.split()` at line 399 raised
`NameError` at runtime. Python's `py_compile` only checks syntax, not name
resolution. Use `python3 -c "import module"` for runtime verification.

## Permission Workflow

To edit root-owned files in a Docker container:

```bash
# From host:
docker exec -u 0 <container> sh -c "chown -R <uid>:<gid> /path/to/target"
```

This session required two passes — one for files, one for the directory itself
(because `patch` creates `.hermes-tmp.*` temp files in the target directory).

Full recursive ownership fix for entire Hermes state:
```bash
docker exec -u 0 <container> sh -c "chown -R 1024:1024 /home/hermeswebui/.hermes"
```
