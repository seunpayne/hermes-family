# Logo Embedding Pattern for PDF Documents

## Overview

Embed the FAROCON brand logo (`~/Projects/assets/brand/farocon-logo.png`, 638×176 RGBA) as a base64 data URI in HTML documents before PDF conversion. This ensures the logo renders reliably without external file dependencies.

## Step-by-Step

### 1. Write HTML with placeholder

Use `write_file` tool to create the HTML document. In the `<img>` tag for the logo, use the placeholder string `LOGO_BASE64_PLACEHOLDER`:

```html
<img class="logo-img" src="data:image/png;base64,LOGO_BASE64_PLACEHOLDER" alt="FAROCON LIMITED">
```

### 2. Inject actual base64 data

```bash
cd ~/Projects/docs/[project]/
BASE64=$(base64 -i farocon-logo.png | tr -d '\n')
sed -i '' "s|LOGO_BASE64_PLACEHOLDER|${BASE64}|g" document.html
echo "Logo injected: $(grep -c 'data:image/png' document.html) occurrences"
```

### 3. Convert to PDF

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --no-sandbox --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="output.pdf" \
  "file://$(pwd)/document.html"
```

**CRITICAL:** Use `--no-pdf-header-footer` (NOT `--print-to-pdf-no-header`). The wrong flag silently produces a PDF with a local file-path footer.

### 4. Signature Injection (Multi-Asset Pattern)

When injecting both logo AND signature, use a single sed pass with multiple placeholders:

```bash
LOGO=$(base64 -i ~/Projects/assets/brand/farocon-logo.png | tr -d '\n')
SIG=$(base64 -i ~/Projects/assets/brand/seun-signature.jpg | tr -d '\n')
sed -i '' "s|LOGO_PLACEHOLDER|${LOGO}|g; s|SIG_PLACEHOLDER|${SIG}|g" document.html
```

**HTML template placeholders:**
- Logo: `<img src="data:image/png;base64,LOGO_PLACEHOLDER" alt="FAROCON LIMITED">`
- Signature: `<img src="data:image/jpeg;base64,SIG_PLACEHOLDER" alt="Seun Payne Jackson">`

**Permanent asset paths:**
- Logo: `~/Projects/assets/brand/farocon-logo.png` (638×176 RGBA)
- Signature: `~/Projects/assets/brand/seun-signature.jpg` (475×399 JFIF)

## Notes

- The base64 string is ~43KB for the FAROCON logo — manageable inline
- Always verify `grep -c` returns exactly 1 occurrence after injection
- Copy the logo PNG to the project's docs directory first: `cp ~/Projects/assets/brand/farocon-logo.png .`
- Chrome headless handles base64 images correctly; some other renderers may not