# Document Generation — Failure Patterns & Fixes

**Last updated:** 30 May 2026
**Key session:** Kogi State Starlink quote (Saba Energy, ₦39.3M)

---

## Problem 1: npm install puppeteer times out

**Symptom:** `npm install puppeteer` hits 120s timeout with no output
**Root cause:** Puppeteer downloads Chromium (~300MB), slow on Nigerian connections
**Fix:** Use pre-installed Chrome headless directly:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --no-sandbox --disable-gpu \
  --print-to-pdf="output.pdf" --print-to-pdf-no-header \
  "file:///absolute/path/to/document.html"
```

Chrome is always available on macOS. Output includes byte count — verify >50KB for valid multi-page PDF.

---

## Problem 2: Terminal heredocs fail for large HTML

**Symptom:** `exit_code -1` with no error, or false `Foreground command uses '&'` message
**Threshold:** HTML files >300 lines / ~15KB
**Fix:** Always use `write_file` tool for HTML content (tested: 15,807 bytes written reliably)

```python
write_file(path="~/Projects/docs/project/quote.html", content="<full HTML>")
```

Never use heredocs for document HTML. If chunking is needed, write_file handles any size.

---

## Problem 3: Subagent document generation times out

**Symptom:** `delegate_task` for doc gen returns `status: "interrupted"` after 305s
**Root cause:** Complex documents (10+ line items, tables, multi-section) exceed subagent model timeout
**Fix:** Generate documents directly (no subagent delegation). Write HTML → Chrome PDF in 2 steps from the main conversation.

---

## Problem 4: Vision model may not support image analysis

**Symptom:** `Error code: 404 - No endpoints found that support image input`
**Context:** Sonnet 4 via OpenRouter may lack vision support depending on config
**Fix:** Skip image analysis. Check file dimensions with `file` command instead:
```bash
file /path/to/logo.png
# Output: PNG image data, 638 x 176, 8-bit/color RGBA
```

---

## Base64 Logo Embedding Pattern

See `references/logo-injection.md` for full step-by-step.
Quick reference:
1. Copy logo to project dir: `cp ~/Projects/assets/brand/farocon-logo.png .`
2. Write HTML with `LOGO_BASE64_PLACEHOLDER` in img src
3. Inject: `BASE64=$(base64 -i farocon-logo.png | tr -d '\n') && sed -i '' "s|LOGO_BASE64_PLACEHOLDER|${BASE64}|g" doc.html`
4. Convert: Chrome headless `--print-to-pdf`

---

## Reliable Quote Generation Workflow

For FAROCON infrastructure quotes (Starlink, DCU, civil works):

1. **Shape brief** — confirm scope, line items, pricing with Seun
2. **Write HTML** via `write_file` tool (logo placeholder, all four changes in one pass)
3. **Inject logo** via terminal sed (one command, ~43KB base64)
4. **Convert PDF** via Chrome headless `--print-to-pdf`
5. **Present** PDF to Seun for review via MEDIA: path

Total steps: 4-5 tool calls. No subagents, no npm installs, no heredocs.
