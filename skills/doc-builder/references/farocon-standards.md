# FAROCON Document Standards

Extracted from INV-000113 (Foremost Capital, 15 May 2026). Apply to ALL FAROCON documents.

---

## Brand Identity

### Colors
- **Primary dark:** `#0E1320` — all accents, borders, section titles, table headers, total rows
- **Background:** `#fff` — page background
- **Table alternating:** `#fafafa` — even rows
- **Note boxes:** `#f8f9fa` — default background
- **Green (warranty only):** `#28a745` border, `#f0fff4` background
- **Grey (exclusions):** `#999` border, `#f5f5f5` background
- **Text:** `#1a1a1a` body, `#0E1320` headings, `#555` secondary, `#888` muted

### FORBIDDEN: Gold/Yellow Accents
- Do NOT use `#CBA135` or any gold/yellow in document styling
- The logo image itself contains gold — that is the ONLY gold allowed
- All document-level accents (borders, section titles, scope cards, contract boxes, note boxes) use `#0E1320` (black)
- The user corrected this explicitly: "The document is using colors not native to FAROCON (Gold) it should be removed"

### Fonts
- **Primary:** Inter (Google Fonts) — weights 400, 500, 600, 700
- Import: `@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');`

### Assets
- **Logo:** `~/Projects/assets/brand/farocon-logo.png` (638×176 RGBA)
- **Signature:** `~/Projects/assets/brand/seun-signature.jpg` (475×399 JFIF)
- Embed both as base64 data URIs using placeholder + sed injection pattern (see `references/logo-injection.md`)

---

## Company Identity

```
FAROCON LIMITED
Abuja Federal Capital Territory, Nigeria
seun.payne@farocon.com.ng
```

### Banking
```
Account Name: FAROCON LIMITED
Account Number: 1016001715
Bank: Zenith Bank
```

---

## Document Structure (Mandatory)

### 1. Header
- FAROCON logo (left, 42px height)
- Company info below logo (8.5pt, grey)
- Quote/Invoice meta (right-aligned): Document type, Number, Date, Valid Until, Terms

### 2. Parties
- "Prepared By" (left) — FAROCON LIMITED full details
- "Prepared For" (right) — Client name, contact person, title, location

### 3. Project Title & Scope
- Section title with project name
- Scope summary cards (3-across, key metrics)

### 4. Pricing Breakdown
- Columns: Item & Description | Qty | Rate (₦) | Amount (₦)
- Line items with descriptions in `<small>` tags
- Spec details in `<span class="spec">` for technical notes

### 5. Totals (in this exact order)
```
Sub Total
Total Tax (7.5%)
Total
Balance Due
```

### 6. Tax Summary (standalone section)
```
Tax Details | Taxable Amount (₦) | Tax Amount (₦)
```

### 7. Payment Terms
- Payment schedule (deposit / milestone / balance)
- Timeline (validity, commencement, completion)

### 8. Warranty (green note box)
### 9. Exclusions (grey note box)
### 10. Terms & Conditions
- Account Details box (bank info)
- Legal boilerplate (5 clauses)
- Variations in writing, NGN pricing, due on receipt, timeline from deposit, force majeure

### 11. Closing line (centered, italic)
```
"Looking forward to your business."
```

### 12. Signatures (two-column)
- FAROCON: signature image + name + title + company
- Client: blank line + name + title + company

### 13. Footer
```
FAROCON LIMITED — Network & Power Infrastructure Delivery
Abuja Federal Capital Territory, Nigeria | seun.payne@farocon.com.ng
This [document] is confidential and intended solely for the named recipient.
```

---

## Quote Numbering
```
FARO-YYYY-CC-NNN
```
- YYYY = year
- CC = client initials (e.g., SE for Saba Energy)
- NNN = sequential

---

## Pricing Conventions
- All amounts in Nigerian Naira (₦)
- Display with `.00` suffix (e.g., `850,000.00`)
- VAT always 7.5% calculated on Sub Total
- Discount line (if any) between Tax and Total — green row

## Standard Terms & Conditions (5 clauses)
1. Entire scope — variations in writing
2. NGN pricing — 30-day validity
3. Due on receipt unless otherwise agreed
4. Timeline from deposit + site readiness
5. Force majeure / site access / third-party delays

## Email Drafting

When sending a quote to a client:
- **Subject:** Quotation — [Project Name] (FARO-YYYY-CC-NNN)
- Open with summary bullets (3-4 key metrics)
- State Grand Total prominently
- Note payment structure and timeline
- Mention optional items separately
- Close with openness to discuss/adjust
- Sign as "Best regards, Seun"
