# i18n Lazy-Loading Implementation

Pattern for splitting a monolithic locale bundle (~976 KB, 15K+ lines)
into per-locale files loaded on demand.

## Architecture

**Before:** All 11 locale catalogs inlined in `static/i18n.js` as a single
`LOCALES` object. Loaded on every page load regardless of user language.

**After:** `static/i18n.js` keeps English inline (~81 KB). Other locales
live under `static/i18n/<code>.js` and are loaded via dynamic `<script>`
injection when `setLocale()` is called.

## Procedure

### Step 1: Extract per-locale files

```python
# For each locale, extract from the original monolithic LOCALES object
# and wrap in the safe-assignment pattern:
starter = '(window.LOCALES=window.LOCALES||{})'
with open(f'/app/static/i18n/{code}.js', 'w') as f:
    f.write(f"// Locale: {code}\n")
    f.write(f"{starter}.{code} = {{\n")
    f.write(locale_body)  # key-value pairs only (no trailing `},`)
    f.write("};\n")
```

The safe-assignment pattern `(window.LOCALES=window.LOCALES||{})` works
regardless of whether the main `i18n.js` has already loaded or not.

### Step 2: Rewrite main i18n.js

Keep English inline; add a tracker + lazy setLocale:

```js
const LOCALES = {};
const _LOADED_LOCALES = new Set(['en']);

// English inlined directly:
LOCALES.en = { ...keys... };

// Existing helpers unchanged: t(), resolveLocale(), applyLocaleToDOM(),
// loadLocale(), resolvePreferredLocale()

// Replace setLocale with lazy-loading version:
function setLocale(lang) {
  const resolved = resolveLocale(lang) || 'en';
  if (resolved === 'en' || _LOADED_LOCALES.has(resolved)) {
    _locale = LOCALES[resolved] || LOCALES.en;
    try { localStorage.setItem('hermes-lang', resolved); } catch (_) {}
    document.documentElement.lang = (_locale && _locale._speech) || resolved;
    if (resolved !== 'en') applyLocaleToDOM();
    return;
  }
  const s = document.createElement('script');
  s.src = 'static/i18n/' + resolved + '.js';
  s.onload = function() {
    _LOADED_LOCALES.add(resolved);
    _locale = LOCALES[resolved];
    applyLocaleToDOM();
  };
  s.onerror = function() {
    console.warn('[i18n] Failed to load locale:', resolved);
    _locale = LOCALES.en;
  };
  document.head.appendChild(s);
}
```

### Step 3: Verify braces

```bash
for f in static/i18n/*.js; do
  o=$(tr -cd '{' < "$f" | wc -c)
  c=$(tr -cd '}' < "$f" | wc -c)
  [ "$o" = "$c" ] || echo "MISMATCH: $f ($o open, $c close)"
done
```

## Typical Savings

- Monolithic: 15,551 lines / 976 KB
- Lazy-loaded: 1,495 lines / 81 KB (English only)
- Savings: **92% / ~895 KB** initial page load
