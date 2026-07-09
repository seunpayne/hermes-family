# DOCX Content Extraction — Two-Pass Method

When the user uploads a `.docx` file (PRD, spec, contract, etc.), extract content properly using python-docx. This is more reliable than pandoc or unzip+XML approaches because it preserves table structure and paragraph styles.

## Method

```python
from docx import Document

doc = Document('path/to/file.docx')

# PASS 1: Paragraphs — captures all running text
for i, p in enumerate(doc.paragraphs):
    style = p.style.name if p.style else 'None'
    if p.text.strip():
        print(f'{i}|{style}|{p.text}')

# PASS 2: Tables — captures structured data (entities, tasks, pricing, etc.)
# These are OFTEN the most important parts of a business document
for ti, table in enumerate(doc.tables):
    print(f'\n=== Table {ti} ===')
    for ri, row in enumerate(table.rows):
        cells = [cell.text.strip() for cell in row.cells]
        print(f'  Row {ri}: {" | ".join(cells)}')
```

## Why Two Passes

- **Paragraphs first**: Captures narrative text, user stories, descriptions, headings
- **Tables second**: Captures entity definitions, task breakdowns, pricing tiers, approval gates, data models — often the most actionable content in a PRD
- Single-pass approaches (pandoc, unzip+XML) lose table structure or merge cells awkwardly

## Common Pitfalls

- Running `cat` or `head` on a .docx file yields garbage (it's a ZIP archive of XML)
- `pandoc -t markdown` works but loses table nesting and multi-row structure
- python-docx may not be pre-installed — install with `pip install python-docx` if missing
