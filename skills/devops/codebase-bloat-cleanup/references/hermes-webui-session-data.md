# Hermes WebUI — Bloat Cleanup Session Reference

Concrete measurements and results from a real cleanup pass against the
Hermes WebUI codebase (commit v0.51.192, May 2026).

## Baselines

| Area | Metric | Value |
|------|--------|-------|
| AGENTS.md | Size | 80 lines / 3.3 KB |
| Memory | Loaded | 0 bytes (optimal) |
| Skills | Loaded | 0 (optimal) |
| Tool descriptions (7 main files) | Total chars | ~14,436 |
| Tool descriptions | Est. tokens/message | ~3,600 |
| Python backend (api/*.py + server.py) | Total lines | ~54,670 |
| JS frontend (static/*.js) | Total lines | ~54,868 |
| static/i18n.js | Size | 15,551 lines / 976 KB (91% non-English) |
| static/style.css | Size | 4,819 lines |
| api/routes.py (biggest file) | Size | 14,925 lines |

## Per-Message Token Savings

| Tool File | Before (chars) | After (chars) | Saved | Tokens/Msg |
|-----------|-------|------|-------|-----------|
| terminal_tool.py | ~3,445 | ~775 | ~2,670 | ~670 |
| file_tools.py | ~1,416 | ~825 | ~591 | ~150 |
| cronjob_tools.py | ~4,930 | ~1,750 | ~3,180 | ~795 |
| browser_tool.py | ~2,835 | ~1,360 | ~1,475 | ~370 |
| web_tools.py | ~630 | ~320 | ~310 | ~78 |
| send_message_tool.py | ~770 | ~340 | ~430 | ~108 |
| skills_tool.py | ~410 | ~250 | ~160 | ~40 |
| **Total** | **~14,436** | **~5,620** | **~8,816** | **~2,200** |

## Dead Code Removed

| File | Removed | What |
|------|---------|------|
| api/config.py | 52 lines | `import traceback`, `import uuid`, `from urllib.parse import parse_qs`, `CODE_EXTS` constant (27 lines), `_LEGACY_CLI_TOOLSET_ALIASES`, `_normalize_cli_toolsets()`, duplicate `import collections` |
| api/streaming.py | 6 lines | `import sys` (unused), `from api.workspace import set_last_workspace`, `_dedupe_replayed_active_context()` wrapper |
| api/models.py | 4 lines | `import collections` (unused), `clear_cli_sessions_cache()` |
| api/routes.py | 49 lines | duplicate `import re`, `_clear_live_models_cache()`, `_resolve_compatible_session_model()`, `_normalize_session_model_in_place()`, `_approval_sse_notify()` |
| static/style.css | 7 lines | `#composerProfileLabel`, `#sidebarWsDisplay`, `#composerMobileCtxBadge` |

## i18n Locale Boundaries (original i18n.js)

| Locale | Line Range | Keys | File Size |
|--------|-----------|------|-----------|
| en | 7–1340 | ~1,291 | 75 KB |
| it | 1341–2666 | ~1,273 | 81 KB |
| ja | 2667–3997 | ~1,291 | 61 KB |
| ru | 3998–5265 | ~1,119 | 78 KB |
| es | 5266–6527 | ~1,111 | 79 KB |
| de | 6528–7793 | ~1,117 | 77 KB |
| zh | 7794–10380 | ~1,223 | 109 KB |
| pt | 10381–11524 | ~994 | 68 KB |
| ko | 11525–12840 | ~1,166 | 70 KB |
| fr | 12841–14096 | ~1,232 | 82 KB |
| tr | 14097–15418 | ~1,270 | 80 KB |

## Key Principles

1. **Tool descriptions: remove cross-tool routing.** "Don't use X — use Y"
   belongs in the system prompt, not in tool JSON schemas. It's duplicated
   in every tool AND in the terminal tool's description.
2. **Tool descriptions: remove implementation details.** The LLM doesn't
   need to know about riprep backends, internal limits, or fallback chains.
3. **Tool descriptions: remove usage-guidance essays.** "Two legitimate
   uses" paragraphs are training material, not parameter metadata.
4. **Locales: lazy-load by default.** The initial page load should only
   contain the user's preferred locale + English fallback.
5. **Dead Python code is overwhelmingly:**
   - `import` of stdlib modules that were added during development and never removed
   - Wrapper functions created during refactors that lost their callers
   - Constants defined for a feature that was later removed
6. **Verify brace balance after i18n splits.** Every locale file must have
   matching `{` and `}` counts.
