# DOCX Programmatic Editing Patterns

Use when you need to edit an existing DOCX file (PRD, proposal, report) programmatically — not generate from scratch, but modify specific content: remove paragraphs, update table cells, insert text, bump version numbers.

## Tooling

```bash
pip3 install python-docx
```

Import:
```python
import docx
from docx import Document
```

## Patterns

### 1. MD5 Identity Check (Before Re-reading)

Before reviewing an "updated" document, always check if it actually changed:

```python
import hashlib
hash1 = hashlib.md5(open('v1.1.docx', 'rb').read()).hexdigest()
hash2 = hashlib.md5(open('v1.2.docx', 'rb').read()).hexdigest()
# If identical, report and stop — don't re-read
```

### 2. Find and Remove a Paragraph by Text Content

```python
doc = Document('path/to/document.docx')

for i, para in enumerate(doc.paragraphs):
    if para.text.strip() == 'Exact text of the line to remove':
        p_element = para._element
        p_element.getparent().remove(p_element)
        print(f"Removed para {i}")
        break

doc.save('path/to/output.docx')
```

**Quirks:**
- `para._element` is an `lxml` element — `getparent()` returns the XML parent node
- `.remove()` removes it from the DOM tree
- This modifies the document in place — the paragraph index shifts after removal
- Use `strip()` on comparison text to ignore leading/trailing whitespace
- The paragraph object is STILL in the `doc.paragraphs` list after removal (it's a reference copy) — but the XML tree is clean

### 3. Find and Update a Table Cell

```python
for ti, table in enumerate(doc.tables):
    for ri, row in enumerate(table.rows):
        for ci, cell in enumerate(row.cells):
            if cell.text.strip() == 'Old value':
                row.cells[ci].text = 'New value'
                # Or access by specific cell index
                # table.rows[ri].cells[ci].text = 'New value'
```

**Finding the right table:** Tables in DOCX are not numbered the same way as visual order. Use content matching (`if 'PRD Version' in cells`) rather than hardcoded table indices.

```python
for ti, table in enumerate(doc.tables):
    for ri, row in enumerate(table.rows):
        cells = [c.text.strip() for c in row.cells]
        if 'PRD Version' in cells:
            # Found the metadata table
            row.cells[1].text = '1.2'  # Update version
```

### 4. Find and Update a Specific Paragraph by Multiple Tokens

When exact text match is fragile (whitespace, formatting spans):

```python
for para in doc.paragraphs:
    text = para.text.strip()
    if text.startswith('v1.') and 'changes:' in text:
        para.text = text + '\n\nNew v1.2 changes: ...'
        break
```

### 5. Save as New File

```python
doc.save('output/path/Chaingang_PRD_v1.2.docx')
```

Always save to a new path — never overwrite the original unless you have a backup.

## When to Use This vs. DOCX Generation

| Task | Tool |
|------|------|
| Create a new DOCX from data | `docx` npm (via doc-builder skill) |
| Edit an existing DOCX (remove/add paragraphs, update table cells, fix typos) | `python-docx` (this reference) |
| Convert HTML to DOCX | Write HTML first, then use `python-docx` to wrap it |

## Pitfalls

- **Paragraph removal is permanent** — the element is gone from the XML tree. Test on a copy first.
- **Table indices are unreliable** — tables from headers/footers/embedded objects can appear in unexpected positions in `doc.tables`. Always match on cell content.
- **`doc.paragraphs` gets stale** — after removing an element, the in-memory `doc.paragraphs` list still contains the removed paragraph. Access the XML tree directly for verification, or save and re-open.
- **Formatting may be lost** — setting `cell.text = 'new'` replaces all content including formatting (bold, fonts, etc.). For formatted cell updates, manipulate the cell's paragraph runs instead.
- **python-docx does not preserve all DOCX features** — some advanced Word features (custom XML parts, activeX, OLE objects) may be dropped on save.
