# Hermes WebUI — Bloat Cleanup Session Results (June 4, 2026)

## Per-Message Token Savings

Target: 7 tool files in `~/.hermes/hermes-agent/tools/`
Method: Trimmed JSON schema "description" fields (removed cross-tool routing advice, implementation details, usage-guidance paragraphs)

| Tool File | Before (chars) | After (chars) | Saved | Tokens/Msg |
|-----------|-------|------|-------|:---------:|
| terminal_tool.py | ~3,445 | ~775 | ~2,670 | ~670 |
| file_tools.py | ~1,416 | ~825 | ~591 | ~150 |
| cronjob_tools.py | ~4,930 | ~1,750 | ~3,180 | ~795 |
| browser_tool.py | ~2,835 | ~1,360 | ~1,475 | ~370 |
| web_tools.py | ~630 | ~320 | ~310 | ~78 |
| send_message_tool.py | ~770 | ~340 | ~430 | ~108 |
| skills_tool.py | ~410 | ~250 | ~160 | ~40 |
| **Total** | **~14,436** | **~5,620** | **~8,816** | **~2,200** |

## Frontend Initial Load Savings

**i18n.js lazy loading:** Extracted 11 locales into `static/i18n/<code>.js` files. English stays inline; others load on demand via dynamic `<script>` injection when user switches language.

| Before | After | Saved |
|--------|-------|-------|
| 15,551 lines / 976 KB | 1,495 lines / 81 KB | **895 KB (91.7%)** |

## Python Backend Dead Code Removed

| File | Lines Removed | What |
|------|:-----------:|------|
| api/config.py | 52 | 3 unused imports, CODE_EXTS, dead alias/normalize code |
| api/streaming.py | 6 | 2 unused imports, dead wrapper function |
| api/models.py | 4 | 1 unused import, orphaned cache-clear function |
| api/routes.py | 49 | 1 duplicate import, 4 orphaned functions |
| static/style.css | 7 | 3 unused CSS selectors |
| **Total** | **~118 lines** | |

## Key Techniques Used

### Tool Description Trimming
```python
# BEFORE (309 chars) — cross-tool routing + usage guidance
"Read a text file with line numbers and pagination. Use this instead of cat/head/tail in terminal. Output format: 'LINE_NUM|CONTENT'. Suggests similar filenames if not found. Use offset and limit for large files. Reads exceeding ~100K characters are rejected; use offset and limit to read specific sections of large files. NOTE: Cannot read images or binary files — use vision_analyze for images."

# AFTER (190 chars) — just what it does
"Read a text file with line numbers and pagination (LINE_NUM|CONTENT format). Use offset/limit for large files. Suggests similar filenames. Cannot read binary files."
```

### i18n Lazy Loading Pattern
See main SKILL.md for the pattern. Key details from this session:
- Each locale file wraps in `(window.LOCALES=window.LOCALES||{})[code] = { ... };`
- Main file: `const _LOADED_LOCALES = new Set(['en']);`
- Modified `setLocale()` creates a `<script>` tag if locale not loaded
- Verify brace balance for ALL locale files after extraction

### Docker Permission Fix
```bash
# From Docker HOST — NOT inside container
docker exec -u 0 <container> sh -c "chown -R <uid>:<gid> /path"
```
Both the directory AND its contents need to be writable. The `patch` tool creates `.hermes-tmp.*` files in the target directory.
