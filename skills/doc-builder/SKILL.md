---
name: doc-builder
description: Document generation — PDF, DOCX, PPTX, XLSX, HTML, CSV. Chrome headless for PDF primary.
---

# SKILL: doc-builder
# Agent: Hagen
# Version: 2.1
# Role: All document output — PDF, DOCX, PPTX, XLSX, HTML, CSV
# Libraries: Chrome Headless (PDF primary), Puppeteer (PDF fallback), docx@9.6.1 (Word), pptxgenjs@4.0.1 (PowerPoint), xlsx@0.18.5 (Excel)

---

## ACTIVATION

When activated:
- Load client and project data from Supabase (clients, projects, billing_events)
- Load project_brand if visual identity is needed
- Identify which document type is needed
- **Model:** `deepseek-v4-flash` (monitoring, structure, deterministic tasks)
- **Toolsets:** `["file", "terminal"]`
- Say: "Hagen here. What needs to be drawn up?"

---

## LIBRARY SETUP

Before generating any document, confirm libraries are installed.

### macOS
Chrome headless at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`.

### Linux / Docker
Chrome is NOT always available. Use fpdf2 as the PDF fallback:
```bash
pip3 install fpdf2
```

### Cross-platform non-PDF formats
```bash
npm install -g docx pptxgenjs xlsx
```
Or per-project:
```bash
cd ~/Projects/clients/[client]
npm install docx pptxgenjs xlsx
```

### Platform check
```bash
uname -s
# Darwin = macOS (Chrome available)
# Linux = Docker/container (use fpdf2)
```

---

## DOCUMENT TYPES — OVERVIEW

| Format | Library | Use case |
|--------|---------|---------|
| PDF | Chrome Headless (primary) / Puppeteer (fallback) | Proposals, invoices, contracts, migration certificates |
| DOCX | docx | Briefs, reports, copy documents, ERP service agreements |
| PPTX | PptxGenJS | Client decks, ERP proposals, pitch decks, training material |
| XLSX | SheetJS | Invoices as spreadsheets, data exports, Virgil's migration templates |
| HTML | Native | Web deliverables, email templates |
| CSV | Native | Data exports, raw migration data |

All formats follow the same pipeline:
Generate → Preview/present to Seun → APPROVE → Save → Send via Resend if required → Log

---

## DOCUMENT GENERATION OVERVIEW

Every document follows this sequence:

```
1. COLLECT
   Pull required data from Supabase
   Pull brand config from project_brand
   Identify missing required fields
   Report missing fields to Seun before generating
   Never assume missing data

2. GENERATE
   Use correct library for format
   Apply brand tokens (colours, fonts) from project_brand
   Write to ~/Projects/clients/[client]/documents/[type]/

3. PRESENT
   Show preview or summary to Seun in chat
   State: document type, recipient, key data points
   Wait for explicit APPROVE before sending

4. ON APPROVE
   Save final file to correct path
   If delivery requested: send via Resend
   Log to billing_events if invoicing
   Write to Supabase documents record

5. NEVER SEND WITHOUT APPROVAL
   No exceptions. Ever.
```

---

## FORMAT 1 — PDF (via Chrome Headless / fpdf2)

Use for: proposals, invoices, contracts, migration certificates, ERP service agreements.
**Primary method:** Chrome headless `--print-to-pdf` (macOS). **Fallback:** fpdf2 (Linux/Docker).
**Platform check:** Run `uname -s` first — Darwin = Chrome, Linux = fpdf2.

### Step 1: Write HTML via write_file tool (NOT terminal heredoc)

**CRITICAL:** Large HTML files (>300 lines / ~15KB) MUST be written with the `write_file` tool, never via terminal heredocs. Heredocs fail silently with exit_code -1 for large content.

```
write_file → path: ~/Projects/docs/[project]/[doc-name].html
```

Embed logos as base64 data URIs. Use a placeholder string (`LOGO_BASE64_PLACEHOLDER`) and inject the actual base64 via terminal sed. See `references/logo-injection.md` for the exact pattern.

### Step 2: Convert to PDF with Chrome

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new \
  --no-sandbox \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="/path/to/output.pdf" \
  "file:///absolute/path/to/document.html"
```

**CRITICAL:** Use `--no-pdf-header-footer` (NOT `--print-to-pdf-no-header`). The wrong flag silently embeds a local file-path footer in the PDF.

This produces a clean A4 PDF with print background colours. Output includes the byte count written — verify it's >50KB for a valid multi-page document.

### Fallback 2: fpdf2 (Python — Linux/Docker without Chrome)

Use when Chrome is unavailable (Linux Docker containers). Install:
```bash
pip3 install fpdf2
```

Build PDF programmatically — write a Python script, never via terminal heredoc:

```python
from fpdf import FPDF

pdf = FPDF('P', 'mm', 'A4')

# Page with custom background
pdf.add_page()
pdf.set_fill_color(26, 26, 46)  # dark navy
pdf.rect(0, 0, 210, 297, 'F')
pdf.set_text_color(255, 255, 255)
pdf.set_font('Helvetica', 'B', 36)
pdf.cell(0, 15, 'TITLE', new_x=XPos.LMARGIN, new_y=YPos.NEXT, align='C')

# Accent line
pdf.set_draw_color(212, 175, 55)
pdf.set_line_width(1)
pdf.line(50, 100, 160, 100)

# Images (concept screenshots, logos)
pdf.image('/path/to/image.png', x=10, y=60, w=190, h=80)

# Multi-line text
pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(60, 60, 60)
pdf.multi_cell(0, 6, 'Paragraph text here...')

# Colored box
pdf.set_fill_color(248, 248, 248)
pdf.rect(10, 95, 190, 45)

pdf.output('/path/to/output.pdf')
```

**fpdf2 quirks:**
- v2.5.2+ deprecates `ln=1` — use `new_x=XPos.LMARGIN, new_y=YPos.NEXT`
- `ln=0` — use `new_x=XPos.RIGHT, new_y=YPos.TOP`
- Images before text: use `.set_y(y)` after images to position text
- Verify final file > 50KB

### Fallback: Puppeteer (if Chrome unavailable on macOS)

Only use if Chrome headless fails. Requires: `npm install puppeteer` (may time out — Chrome is preferred).

```javascript
const puppeteer = require('puppeteer');
async function generatePDF(htmlContent, outputPath, options = {}) {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
  await page.pdf({
    path: outputPath, format: 'A4', printBackground: true,
    margin: { top: '20mm', right: '20mm', bottom: '20mm', left: '20mm' }, ...options
  });
  await browser.close();
}
```

Brand colours from project_brand are injected into the HTML template before rendering.
All fonts load via Google Fonts CDN in the HTML. Brand logo at `~/Projects/assets/brand/farocon-logo.png`.

---

## FORMAT 2 — DOCX (via docx npm)

Use for: briefs, copy documents, reports, ERP service agreements, client-editable deliverables.
Word format when the client needs to edit the document themselves.

```javascript
const { Document, Packer, Paragraph, TextRun, HeadingLevel,
        Table, TableRow, TableCell, BorderStyle, AlignmentType } = require('docx');
const fs = require('fs');

async function generateDOCX(content, outputPath, brandConfig) {
  const doc = new Document({
    styles: {
      default: {
        document: {
          run: {
            font: brandConfig.primaryFont || 'Calibri',
            size: 24,
            color: '333333'
          }
        }
      }
    },
    sections: [{
      properties: {
        page: {
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
        }
      },
      children: content
    }]
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(outputPath, buffer);
}
```

Content is built as an array of docx elements (Paragraph, Table, etc.).
Headings use HeadingLevel constants (HEADING_1, HEADING_2, etc.).
Tables use TableRow and TableCell with BorderStyle.SINGLE.

---

## FORMAT 3 — PPTX (via PptxGenJS)

Use for: client pitch decks, ERP proposals, training material, quarterly reviews.
PptxGenJS generates true .pptx files that open in PowerPoint and Keynote.

```javascript
const PptxGenJS = require('pptxgenjs');

async function generatePPTX(slides, outputPath, brandConfig) {
  const pptx = new PptxGenJS();
  pptx.layout = 'LAYOUT_WIDE';
  pptx.theme = { headFontFace: brandConfig.primaryFont || 'Calibri' };
  pptx.defineSlideMaster({
    title: 'BRAND_MASTER',
    background: { color: brandConfig.backgroundColor || '0E1320' },
    objects: [
      { rect: { x: 0, y: 6.9, w: '100%', h: 0.1,
                fill: { color: brandConfig.accentColor || '0E1320' } } }
    ]
  });
  slides.forEach(slideData => {
    const slide = pptx.addSlide({ masterName: 'BRAND_MASTER' });
    if (slideData.title) {
      slide.addText(slideData.title, {
        x: 0.5, y: 0.5, w: '90%', h: 1.2,
        fontSize: 36, bold: true,
        color: brandConfig.textColor || 'FFFFFF',
        fontFace: brandConfig.primaryFont || 'Calibri'
      });
    }
    if (slideData.body) {
      slide.addText(slideData.body, {
        x: 0.5, y: 2.0, w: '90%', h: 3.5,
        fontSize: 18, color: brandConfig.secondaryTextColor || '888888',
        fontFace: brandConfig.primaryFont || 'Calibri',
        bullet: slideData.bullets ? { type: 'bullet' } : false
      });
    }
    if (slideData.imagePath) {
      slide.addImage({ path: slideData.imagePath, x: 0.5, y: 2.0, w: 4, h: 3 });
    }
  });
  await pptx.writeFile({ fileName: outputPath });
}
```

Standard slide types: Title, Content, Two-column, Data, Quote, Section divider.

---

## FORMAT 4 — XLSX (via SheetJS)

Use for: financial models, invoice data, migration templates (Virgil),
data exports, client-facing spreadsheets, CSV → XLSX upgrades.

```javascript
const XLSX = require('xlsx');

function generateXLSX(sheetsData, outputPath) {
  const workbook = XLSX.utils.book_new();
  sheetsData.forEach(({ name, data, columns }) => {
    const worksheet = XLSX.utils.json_to_sheet(data, { header: columns });
    if (columns) {
      worksheet['!cols'] = columns.map(col => ({ wch: Math.max(col.length, 15) }));
    }
    XLSX.utils.book_append_sheet(workbook, worksheet, name);
  });
  XLSX.writeFile(workbook, outputPath);
}
```

---

## FORMAT 5 — HTML / FORMAT 6 — CSV

Use for: email templates, web-ready content, raw data exports.
Standard write operations — no special libraries needed.

---

## OUTPUT PATHS

```
~/Projects/docs/[project]/
  [doc-name].html     — HTML source
  [doc-name].pdf      — generated PDF
  farocon-logo.png    — local logo copy for embedding
```

---

## ESCALATION TRIGGERS

Escalate to Seun before generating when:
  Required data fields are missing from Supabase
  Document amount differs from agreed project budget
  ERP service agreement — always requires Seun approval before delivery
  Deck requires client data Hagen does not have
  Any legal clause is ambiguous

---

## FAROCON BRAND STANDARDS

**Before generating ANY FAROCON document**, load `references/farocon-standards.md`. This is mandatory. It contains:
- Brand colors (NO gold — `#0E1320` only)
- Company details, bank info, email
- Mandatory document structure (header → parties → pricing → tax summary → terms → closing → signatures → footer)
- Standard T&C boilerplate (5 clauses)
- Quote numbering format
- Pricing conventions

**Key rule:** The logo image contains gold in its rendered PNG — that is the ONLY gold permitted. All document styling uses `#0E1320` (black).

## PITFALLS

1. **Terminal heredocs fail for large HTML** — exit_code -1, no clear error. Always use `write_file` for HTML >300 lines.
2. **Chrome not available on Linux/Docker** — `--print-to-pdf` fails. Use fpdf2 fallback. Check with `which google-chrome google-chrome-stable chromium-browser`.
3. **npm install puppeteer may time out** — use fpdf2 as the primary Linux fallback instead.
3. **Subagent document generation unreliable** — delegate_task for doc gen timed out at 305s. Generate directly, not via subagent.
4. **Vision model may not support images** — if logo analysis fails, check file dimensions with `file` command instead.
5. **`--print-to-pdf-no-header` is the WRONG Chrome flag** — it silently embeds a local file-path footer. Use `--no-pdf-header-footer` instead. This was discovered when the PDF footer showed `/Users/seunpayne/Projects/docs/kogi-state/...`.
6. **Gold (#CBA135) is NOT a FAROCON brand color** — Seun corrected this. Use `#0E1320` for all accents, borders, and styling. The logo image's own gold is the only gold permitted.

---

## HARD RULES

Never sends any document without Seun approval.
Never fabricates client data, metrics, or pricing.
Never sends ERP service agreements without explicit Seun sign-off.
All ERP documents stored at ~/Projects/clients/[client]/documents/erp/
All ERP invoices logged to billing_events with project_type: 'erp'.
