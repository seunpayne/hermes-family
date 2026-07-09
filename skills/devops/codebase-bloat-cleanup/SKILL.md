---
name: codebase-bloat-cleanup
description: Systematic dead-code removal and token-budget optimization for any codebase.
---

# Codebase Bloat Cleanup & Context Optimization

A class-level workflow for auditing and reducing bloat across a codebase, with
special emphasis on **per-message token savings** for LLM-powered tools (agents,
web UIs, assistant frontends). The workflow is codebase-agnostic but has
Hermes WebUI–specific refinements.

## When to Use

- User reports messages are "burning too many tokens" or are expensive.
- A codebase has grown organically with no systematic cleanup pass (15K+ line
  route files, 50K+ line JS, orphaned constants, dead imports).
- Per-message system prompt includes verbose tool descriptions or project
  context files that could be tightened.
- Initial page-load bundles contain data that could be deferred (locales,
  unused CSS, large inline data blobs).

## Priority Order

1. **Tool/function descriptions** injected into every LLM call — biggest
   per-message savings per byte trimmed.
2. **Project context files** (AGENTS.md, CLAUDE.md, .cursorrules) injected
   every turn.
3. **Memory & skills** — ensure only necessary content is loaded.
4. **Frontend bloat** — large inline data, dead CSS, unused JS paths.
5. **Backend dead code** — unused imports, orphaned functions, dead constants.
6. **Test suite bloat** — slow or redundant tests (lower priority).

## Procedure

### 1. Establish Baselines

Before any change, measure the current state:

```bash
# File sizes
wc -l -c *.py **/*.py static/*.js static/*.css

# Token estimate (rough: 4 chars ≈ 1 token for most LLMs)
# Tool description chars → divide by 4 → approximate tokens

# Frontend transfer size
find static/ -name '*.js' -o -name '*.css' | xargs wc -c | tail -1
```

### 2. Audit LLM-Side Token Burn

The biggest wins are in what gets **sent to the LLM on every message**:

#### Tool Descriptions

Tool JSON schemas (`"name"`, `"description"`, `"parameters"`) are serialized
every turn. Common bloat patterns:

- **Cross-tool routing advice**: "Do NOT use X — use Y instead." This belongs
  in the system prompt, not in every tool's JSON. Remove from descriptions.
- **Implementation details**: "Ripgrep-backed, faster than shell equivalents",
  "only NEW errors introduced by this write are surfaced." The LLM doesn't
  need to know how the tool works internally.
- **Usage-guidance paragraphs**: "Two legitimate uses: (1) ... (2) ...",
  "Almost always pair with notify_on_complete=true." These are training
  materials, not parameter metadata.
- **Behavioral instructions**: "When the user asks to send to a specific
  channel..." — belongs in the system prompt or a skill.

**Target**: Each description should say *what the tool does and what values
the parameters accept*, not *why it was designed that way* or *when to prefer
another tool*.

#### Project Context Files

- AGENTS.md / CLAUDE.md / .cursorrules are injected every turn.
- Keep AGENTS.md under 100 lines / 5 KB. Longer files waste tokens.
- If an agent's own AGENTS.md is 1,000+ lines, ensure the running process's
  cwd doesn't point at that directory (context files are cwd-scoped).

#### Memory & Skills

- Empty memory is optimal. Verbose or stale memories waste tokens.
- Zero loaded skills is optimal. Only load skills relevant to the task.

#### Critical: Skills Index (System Prompt Injection)

**The agent's skills index is a major hidden token burner.** The
`build_skills_system_prompt()` function generates a `## Skills (mandatory)`
section that lists EVERY enabled skill's name + description in the system
prompt, wrapped in `<available_skills>` tags with boilerplate instructions.

**Measured cost (this session):** 107 skills → 13,625 chars → ~3,400 tokens
per message. That's more than the combined tool descriptions after optimization.

**Key insight: Categories compound the savings.** When 41 skills were moved
from flat layout into a single `Family Skills` category directory, the index
went from 41 separate uncategorized entries to 1 category header + 41 indented
lines. The category-name header is one index line — not 41. Consolidating
skills under a single category (e.g., `Family Skills/`) saves roughly
(N-1) × ~20 chars per entry in the index.

**How to organize skills into categories:**
```bash
# Move skills under a new category directory
mkdir -p ~/.hermes/skills/"Category Name"
mv ~/.hermes/skills/skill-a ~/.hermes/skills/"Category Name"/
mv ~/.hermes/skills/skill-b ~/.hermes/skills/"Category Name"/
# ... repeat for all skills in that category
```

The Hermes skill loader treats each subdirectory of `~/.hermes/skills/` as a
category. Skills directly under `~/.hermes/skills/` (no parent dir) appear as
uncategorized entries. After reorganizing, the skills index only shows the
category name once instead of repeating it for every entry.

**To refresh the skills index after reorganization** (the system prompt cache
is keyed on skills directory state — restart or trigger curator):
```bash
hermes skills list        # triggers re-scan
```

**How to measure it:**
```python
from agent.prompt_builder import build_skills_system_prompt
result = build_skills_system_prompt()
print(f"{len(result)} chars / {len(result)//4} estimated tokens")
```

**Mitigation options (from most to least effective):**
1. **Disable unused skills** via `hermes skills config` (interactive TUI) or
   `hermes skills config --disable <name>`. Disabled skills are excluded from
   the index.
2. **Move skills out of the index path** — Skills outside `~/.hermes/skills/`
   are only loaded when explicitly configured as `skills.external_dirs`.
   Skills in external dirs but NOT in the default dir are not indexed.
3. **Trim skill descriptions** to ≤60 chars (per Hermes skill-authoring
   standard). Long descriptions compound the token cost proportionally.
4. **Consolidate narrow skills** into class-level umbrellas with rich
   SKILL.md + references/ — fewer entries in the index, same coverage.
5. **The `DESCRIPTION.md` file** at category level also adds to the index.
   Keep it short or remove it.

### 3. Audit Python Backend Dead Code

```bash
# Unused imports — check each import against usage in file
# Orphaned functions — search function names across the codebase
grep -rn "def some_function" | wc -l       # count definitions
grep -rn "some_function" --include='*.py'  # count references (should be >1)

# Unused constants — same cross-reference pattern
# Duplicate imports — look for repeated module names in import blocks
```

Common targets:
- `import traceback`, `import uuid`, `import sys`, `import shlex` at module
  level that are never referenced.
- `from X import Y` where Y is never used.
- Constants defined at module level with zero callers.
- Wrapper functions that just delegate to another function (dead intermediary).
- Functions with "convenience" in the docstring that are never called.

### 4. Audit Frontend Bloat

#### CSS Dead Selectors

```bash
# Find selectors in CSS that reference non-existent JS/HTML IDs/classes
for id in $(grep -oP '#[\w-]+' style.css | sort -u); do
  el="${id#\#}"
  if ! grep -qr "$el" --include='*.js' --include='*.html' . 2>/dev/null; then
    echo "UNUSED: $id"
  fi
done
```

#### Locale / i18n Data — Lazy Loading Pattern

Monolithic locale files (15K+ lines, 900+ KB bundled inline) are common.
Strategy: keep the default locale inlined, lazy-load others via dynamic
`<script>` injection.

**Implementation pattern:**

1. **Extract each locale** into `static/i18n/<code>.js` using the safe wrapper:
   ```js
   (window.LOCALES=window.LOCALES||{})[code] = { ...keys... };
   ```

2. **Keep English inlined** in the main `i18n.js` under `LOCALES.en = { ... }`.

3. **Add a loaded-locales tracker:**
   ```js
   const _LOADED_LOCALES = new Set(['en']);
   ```

4. **Replace `setLocale()` with a lazy version:**
   ```js
   function setLocale(lang) {
     const resolved = resolveLocale(lang) || 'en';
     if (resolved === 'en' || _LOADED_LOCALES.has(resolved)) {
       _locale = LOCALES[resolved] || LOCALES.en;
       // persist + update DOM
       return;
     }
     const s = document.createElement('script');
     s.src = 'static/i18n/' + resolved + '.js';
     s.onload = function() {
       _LOADED_LOCALES.add(resolved);
       _locale = LOCALES[resolved];
       applyLocaleToDOM();
     };
     document.head.appendChild(s);
   }
   ```

5. **Verify balanced braces** for every locale file:
   ```bash
   for f in static/i18n/*.js; do
     o=$(tr -cd '{' < "$f" | wc -c)
     c=$(tr -cd '}' < "$f" | wc -c)
     [ "$o" = "$c" ] || echo "MISMATCH: $f"
   done
   ```

Typical savings: 976 KB → 81 KB (~92% reduction).

#### Duplicate Code

- Same logic defined in multiple files (e.g., `hasMessageToolMetadata` in
  messages.js and sessions.js) — extract to a shared helper.

### 5. Handling Permission Barriers (Docker Containers)

When tool files or directories inside a container are root-owned:

**Primary fix (from Docker host):**
```bash
docker exec -u 0 <container-name> sh -c "chown -R <uid>:<gid> /path/to/target"
```

**Inside-container fallback (if docker exec from host isn't available):**
- Rename the locked directory and create a fresh one (see `hermes-permissions-repair`).
- Or use `pexpect` for `su` password entry, though root is usually locked in
  Docker images — this approach is fragile.

**Key detail**: chowning the FILES inside a directory is not enough. The
DIRECTORY itself must also be writable, because tools like `patch` create
temp files (`.hermes-tmp.*`) in the same directory.

### 6. Measure Savings

After changes, calculate:

```bash
# Per-message savings
# Old chars - New chars = chars saved
# Chars / 4 = approximate tokens saved
# Tokens × avg cost/token = cost savings per message

# Frontend savings
# Old file size - New file size = bytes saved per initial load
```

## Pitfalls

- **Tool description order matters.** Some agents put common tools early in
  the tools array for attention. Don't reorder tools — only trim descriptions.
- **`import collections` at module level is often dead.** In Python 3.12+,
  `OrderedDict` can be imported as `from collections import OrderedDict`
  instead of `import collections`.
- **DO NOT save passwords to memory or skills.** Always prompt the user.
- **Avoid removing `import` that's used via namespace** (e.g., `shlex.split`).
  Verify with runtime test, not just grep. `py_compile` does NOT validate
  runtime symbol resolution — only an actual `import` + `module.attr` test
  proves the symbol is reachable from the module's namespace.
- **When splitting i18n.js**, verify balanced braces (`{` count == `}` count)
  for ALL locale files, not just the main file.
- **TOML/JSON/YAML in descriptions** — watch for `{` / `}` in template
  literals inside Python f-strings. They affect brace-count verification
  in Python syntax checks.
- **If the Hermes agent's tools/ directory is root-owned**, chown both the
  FILES and the DIRECTORY itself. The `patch` tool creates `.hermes-tmp.*`
  temp files in the target directory. chowning files alone leaves the
  directory unwritable — edits silently fail with "Permission denied".
- **A constant and its computing function may have different callers.** In one
  cleanup session, `CLI_TOOLSETS` (the constant) was dead while
  `_resolve_cli_toolsets()` (the computing function) was imported and used in
  two other modules. Always check callers of EACH symbol independently.
- **Tool descriptions with f-strings need extra care.** When trimming
  descriptions inside Python files, f-string `{variable}` interpolation
  uses brace syntax that looks like JSON/dict braces to naive scanners.
  Verify the file still compiles with `python3 -m py_compile` after every
  description edit.
- **After removing an import, verify with a live import, not just compile.**
  `python3 -c "import api.streaming; print('shlex:', getattr(api.streaming, 'shlex', 'REMOVED'))"` actually resolves
  the symbol chain; `py_compile` only checks syntax. The two can disagree.
- **The skills index is an invisible token burner.** It's not in any
  file you would measure with wc. You must call
  `build_skills_system_prompt()` from `agent.prompt_builder` to measure it.
  See `references/skills-index-token-audit.md` for the measurement recipe.
- **Bulk-chown inside Docker silently skips root files.** Running
  `chown -R` inside the container as a non-root user exits with code 0
  but does not change root-owned files. Always use
  `docker exec -u 0 <container> sh -c "chown -R <uid>:<gid> /path"`
  from the Docker host. Verify afterward with `stat` or `touch` on a few files.
- **chown of root-owned files in Docker containers requires the HOST command:**
  `docker exec -u 0 <container> sh -c "chown -R <uid>:<gid> /path"`.
  Inside the container, `su` often fails because root is locked (no password
  set in Docker images). The container-internal rename-recreate workaround
  (from `hermes-permissions-repair` skill) is a fallback, not the primary fix.
- **i18n locale files can't be loaded from `file://` or unexpected base URLs.**
  The lazy-load script tag uses `static/i18n/<code>.js`, which resolves
  relative to the HTML page. If the WebUI is behind a sub-path or reverse
  proxy, verify the script URL resolves correctly.
- **Terminal display truncates long file lines with `...`.** A line showing
  `SECRET=sb_sec...5bx` may actually be 41+ bytes — the `...` is the
  terminal tool's visual truncation, not the file contents. Always check
  `len(value)` in Python or use hex decoding before assuming a value is
  partial. See `references/env-value-recovery.md`.
- **Brace-balance verification for locale files must check EVERY file.**
  The main i18n.js may be balanced while individual locale files have
  an extra `}` from the extraction process (the original `},` closing
  plus the new `};` wrapping). Always run the `tr -cd` loop on all
  `static/i18n/*.js` files, not just the main bundle.
- **When editing tool descriptions in f-strings,** the brace characters
  `{` and `}` in f-string expressions look like JSON dict braces to
  naive scanners. Only `python3 -m py_compile` is authoritative for
  verifying the file is syntactically valid after an edit.

## Verification

```bash
# All Python files compile
cd /project && python3 -m py_compile api/*.py server.py

# WebUI imports succeed
python3 -c "import api.streaming; import api.routes; import api.models"

# Locale files have balanced braces
for f in static/i18n/*.js; do
  opens=$(tr -cd '{' < "$f" | wc -c)
  closes=$(tr -cd '}' < "$f" | wc -c)
  [ "$opens" = "$closes" ] || echo "MISMATCH: $f ($opens open, $closes close)"
done

# Live import test for removed symbols
python3 -c "import api.streaming; print('shlex:', getattr(api.streaming, 'shlex', 'REMOVED'))"
```
