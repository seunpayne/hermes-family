---
name: farocon-quoting
description: FAROCON LIMITED infrastructure quoting — network/power
  deployment proposals for Nigerian government and enterprise
  clients. Generates branded HTML quotes with embedded assets,
  Chrome headless PDFs, meeting prep cheat sheets, and
  post-meeting revision workflows. Covers Starlink, P2P
  wireless, civil works, service contracts.
license: MIT
metadata:
  author: The Don
  version: "1.0"
  organization: FAROCON LIMITED
  date: June 2026
  abstract: Complete FAROCON quote lifecycle — from initial
    HTML proposal through meeting prep, transcript analysis,
    pricing revision, PDF generation via Chrome headless,
    and project state maintenance. Distinct from SME website
    proposals (sales-proposal-generator).
---

# SKILL: farocon-quoting
# Version: 1.0

---

## ACTIVATION TRIGGERS

- "FAROCON quote", "FAROCON proposal"
- Starlink / NanoBeam / P2P / civil works deployment
- Infrastructure quote for government or enterprise
- Multi-site network installation pricing
- Any quote with FARO-YYYY-XX-NNN reference format
- Nigerian govt/enterprise RFQ requiring branded PDF

---

## DOMAIN: FAROCON LIMITED

Network & power infrastructure delivery. Abuja FCT.
Typical deployments: Starlink Business/Residential,
Ubiquiti NanoBeam P2P/P2MP, civil works, service contracts.

Brand assets (permanent):
- Logo: ~/Projects/assets/brand/farocon-logo.png (base64 embedded)
- Signature: ~/Projects/assets/brand/seun-signature.jpg (base64 embedded)
- Colors: #0E1320 (dark), clean greys — NO gold accents
- Bank: Zenith Bank | 1016001715 | FAROCON LIMITED
- Email: seun.payne@farocon.com.ng
- Closing: "Looking forward to your business."
- Quote ref format: FARO-YYYY-XX-NNN (e.g., FARO-2026-SE-001)
- Payment: 50/30/20 (deposit / hardware milestone / commissioning)

These are encoded in SOUL.md but repeated here as the quoting
checklist. Every HTML template MUST include: logo, signature,
bank details, email, address.

---

## PHASE 1 — INITIAL QUOTE BUILD

### 1A. SCOPE CONFIRMATION

Before touching HTML, confirm:
- Number of sites (with GPS coordinates if available)
- Hardware per site (Starlink kit type, P2P pairs, etc.)
- Subscription type (Business ₦110K/mo vs Residential ₦85K/mo)
- Civil works scope (poles? concrete? who provides poles?)
- Travel requirements (team size, base city, duration)
- Service contract tier (optional — Basic/Standard/Premium)
- Payment terms (default 50/30/20)

### 1B. PRICING TABLE

Build the table from confirmed scope. Standard line items:

| Item | Typical Unit | Notes |
|------|-------------|-------|
| Starlink Kit | ₦850,000 | Standard kit, one per site |
| Site Installation Labour | ₦150,000 | Per site. 10% reducible on negotiation |
| Ubiquiti NanoBeam P2P | ₦401,800/pair | ≤1km range. Per link, not per site |
| Civil Works | ₦120,000 | Per site. Mounting, concrete, conduits |
| Travel & Accommodation | ₦380-450K | Team transport + lodging |
| Starlink Subscription (Annual) | Varies | Business: ₦1.32M/yr. Residential: ₦1.02M/yr |
| Service Contract | ₦550K-1.32M | Optional. Basic/Standard/Premium |

### 1C. HTML TEMPLATE

Use the clean HTML template from the references directory.
Key requirements:
- Base64-embedded logo and signature (no external image refs)
- FAROCON dark palette (#0E1320, clean greys)
- Scope summary cards (3 cards: sites, P2P links, total points)
- Pricing table with sub-total → VAT (7.5%) → Total → Balance Due
- Tax summary table
- Optional service contract section (separate, clearly marked)
- Payment terms section
- Warranty section
- Site list table with GPS coordinates
- Bank details box
- Signature blocks (Seun + client contact)
- Footer with FAROCON boilerplate

The template supports both Business and Residential Starlink
subs — the description and pricing change per client choice.

### 1D. PDF GENERATION

Always via Chrome headless (NOT Hagen — Hagen is for SME proposals):

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless --disable-gpu --no-sandbox \
  --print-to-pdf=/Users/seunpayne/Projects/docs/<project-slug>/<filename>.pdf \
  "file:///Users/seunpayne/Projects/docs/<project-slug>/<filename>.html"
```

PDF naming: `<project>-<quote-ref>.pdf`
e.g., `kogi-starlink-quote-R1.pdf`

### 1E. PROJECT STATE FILE

Create/update PROJECT-STATE.md in the project docs directory:

```markdown
# <Project Name> — <Description>
# Project State — saved <date>

## CLIENT
- Company: <name>
- Contact: <name>
- Role: <title>
- Location: <city/state>

## SCOPE (confirmed)
- <N> Starlink installations
- <N> wireless P2P links
- <N> total connection points
- Civil works: <included/excluded>
- Travel: <included/excluded>

## SITE LIST
1. <Name> — <coords> — <N> P2P links
...

## PRICING (<version tag>)
| Item | Qty | Unit Price | Total |
...

Key fields: service contract tiers, payment terms, timeline,
deliverable paths, FAROCON standards, decisions log.

---

## PHASE 2 — MEETING PREP

When Seun has a client meeting about a quote:

### 2A. PREP QUESTIONS BY CATEGORY

Structure Q&A around what the client will actually push back on:

1. **Money** — "Why ₦X million?", "Can we phase?", "50% deposit too steep"
2. **Technical** — "Why Starlink not 4G/fibre?", "Rain?", "Why NanoBeam?"
3. **Timeline/Logistics** — "How long?", "Who handles faults?", "Civil works scope?"
4. **Contract/Risk** — "Warranty?", "SLA?", "Starlink price changes?"

### 2B. THE THREE-SENTENCE PITCH

Lead with the cost-of-inaction argument. For each deployment type:
- Solar plants: "One missed inverter fault costs more than this entire deployment"
- Office networks: "Downtime costs you ₦X/hr — Starlink eliminates the single point of failure"
- Remote sites: "4G doesn't reach here. Fibre would 3-5× this cost."

### 2C. POCKET NUMBERS

Give Seun a tight set to memorise: per-site cost, deposit amount,
minimum phase cost, hardware-only vs all-in.

### 2D. THE CLOSE

Three scenarios, each with an exact ask:
- **Best case:** "Can we get the LPO this week?"
- **Good case:** "Which sites are priority? Let's phase."
- **Minimum:** "What needs to change to make this work for your budget?"

### 2E. CHEAT SHEET

One-page markdown for Seun's phone. Structure:
- Top: key numbers (memorise these)
- Middle: hardest questions → tightest answers
- Bottom: the close (3 asks)
- Back pocket: site list

Save to project docs: `<project>/<CLIENT>-MEETING-CHEATSHEET.md`

### 2F. POCKET REVISION NUMBERS

Before the meeting, pre-calculate what the quote drops to under common discount scenarios so Seun can offer reductions on the spot:

| Scenario | Approx saving | New total (₦39.3M base) |
|---|---|---|
| Residential subs only | ~₦3.3M | ₦35.9M |
| +10% labour + civil | ~₦300K | ₦35.6M |
| Travel trim | ~₦70K | ₦35.5M |
| MikroTik swap (20% off P2P) | ~₦1.8M | ₦33.7M |
| Aggressive (all of the above) | ~₦5.5M | ₦33.8M |

### 2G. CLOSING MOVES

Three techniques proven in real meetings:

1. **"I have my assistant working on it"** — When a client asks for revisions mid-meeting, say the updated document is already being prepared. This sets urgency, shows responsiveness, and gives permission to close. *"I have my assistant working on it right now. We should be able to share an updated proposal within the next hour."*

2. **Timeline momentum** — "If we get the LPO this week, we start procurement Monday and commission by [N weeks]." Make the timeline feel connected to their action.

3. **Three-scenario ask** — Always end with tiered asks:
   - **Best:** "Can we get the LPO this week? I'll secure stock."
   - **Good:** "Which sites are priority? Let's phase and start."
   - **Minimum:** "What needs to change to make this work for your budget?"

---

## PHASE 3 — POST-MEETING REVISION

### 3A. TRANSCRIPT ANALYSIS

Real meeting transcripts are messy — overlapping speakers, network drops, Nigerian accents, dropped calls. Strategies:

- **Focus on substantive nouns** — Listen for: ₦ amounts, months/dates, site names, hardware names, "subscription", "warranty", "roaming", "pole", "contract". These anchor the discussion.
- **Identify each speaker's role** — Note who raised each concern: engineer (technical), budget-holder (commercial), management (decision). This tells you whose objections to prioritise.
- **"Hello? Can you hear me?" = network issue** — Don't over-interpret disconnected statements. If a sentence ends mid-word, the speaker probably lagged, not changed their mind.
- **Confirming ≠ conceding** — When Seun says "Okay, I understand" or "That's a valid concern", check whether he actually committed or just acknowledged.
- **Action items, not commentary** — Revision items are things Seun explicitly promised. Everything else is context.
- **Re-read the cheat sheet** after transcript analysis — the gaps between what was prepped and what happened tell you which objections to add for next time.

From the cleaned transcript, extract:

```markdown
## What they agreed to change
| Item | Original | Revised | Saving |
| --- | --- | --- | --- |

## What they asked for (action items for Seun)
1. [specific ask with who asked]
2. [specific ask with who asked]

## What was settled (no further discussion needed)
- [confirmed point]
- [confirmed point]

## New info discovered
- [fact learned about client, operations, or constraints]
```

### 3A1. HANDLING "SEPARATE QUOTE" REQUESTS

Clients often ask for a second, separate quote mid-meeting (portable kit, different hardware mix, single-site pilot). Protocol:

1. **Clarify scope immediately** — "Just so I'm clear, you want a separate quote for..." If wrong, they correct you.
2. **Be honest about feasibility** — If the request is for something that doesn't work (roaming in Nigeria), say so plainly. Offer alternatives: mesh network (≤3km), mobile data (interstate).
3. **Name the blocker** — "Starlink disabled roaming plans in Nigeria" closes the door cleanly so they don't keep asking.
4. **Separate quote = separate document** — New quote number, not an addendum. Keeps scope boundaries clean.
5. **Flag to Seun** — Note whether the client actually needs this or was exploring. He may decide not to produce it.

### 3B. REVISION CALCULATION

Apply changes in order:
1. Subscription downgrade (Business → Residential)
2. Percentage reductions on negotiable line items
3. Travel/lump sum adjustments
4. Recalculate Sub Total → VAT → Grand Total

### 3C. HTML PATCHING

Use targeted `patch()` calls — one per field. Be precise with
old_string/new_string context to avoid false matches.

Order of patches:
1. Quote metadata (number, dates)
2. Item descriptions (e.g., "Business Terminal" → "Standard Kit")
3. Unit prices and totals per line
4. Sub Total, VAT, Grand Total, Balance Due
5. Tax summary table numbers

Then: save revised HTML copy, generate PDF via Chrome headless.

Naming convention:
- HTML: `<base>-revised-R1.html` (increment R-number)
- PDF: `<project>-<quote-ref>-R1.pdf`

### 3D. PROJECT STATE UPDATE

After revision complete:
- Update pricing table to revised
- Update deliverable section with new paths and dates
- Append new decisions to DECISIONS LOGGED
- Update date header

---

## PRICING WIGGLE ROOM (negotiation defaults)

| Item | Default | Can drop to | How |
|------|---------|-------------|-----|
| Site Labour | ₦150K | ₦135K (−10%) | Volume discount |
| Civil Works | ₦120K | ₦108K (−10%) | If client provides poles |
| Travel | ₦450K | ₦380K | Trim accommodation days |
| P2P Hardware | ₦401.8K Ubiquiti | ₦280K MikroTik | Drop brand tier (20-30% save) |
| Starlink Sub | ₦110K/mo Business | ₦85K/mo Residential | Downgrade tier |

**Do not reduce:**
- Starlink hardware cost (₦850K — fixed by SpaceX)
- VAT (7.5% — statutory)
- Service contract pricing (optional, already separate)

---

## HARD RULES

1. **Embed all brand assets as base64** — no external image URLs in HTML.
2. **Chrome headless for PDF** — not Hagen. Hagen is for SME proposals.
3. **Service contract is ALWAYS separate and clearly marked OPTIONAL.**
4. **Every quote revision gets a new R-number** (R1, R2, etc.) and project state update.
5. **Never quote pole costs** — client provides electrical poles. FAROCON provides mounting extensions/brackets.
6. **Never promise interstate roaming** — Starlink roaming disabled in Nigeria.
7. **Payment terms default to 50/30/20** unless client negotiates otherwise.
8. **Gold accents are banned** — #0E1320 + clean greys only.
9. **Logo + signature + bank details in every quote** — no exceptions.

---

## COMMON CLIENT QUESTIONS (with answers)

### "Why Starlink and not 4G/fibre?"
→ 4G is patchy in rural areas. Fibre doesn't exist at these sites and trenching costs 3-5× more. Starlink: 100-200Mbps, sub-40ms latency, plug and play. Works the day you install.

### "What about rain/storms?"
→ Starlink dishes are weather-rated. At Nigerian latitudes (7-8°N), rain fade is minimal. NanoBeam ≤1km — weather irrelevant at that range.

### "Why NanoBeam and not something cheaper?"
→ NanoBeam NBE-5AC-GEN2: 450+Mbps, 5GHz, Ubiquiti local distributor support. Cheaper alternatives (TP-Link CPE, MikroTik Wireless Wire) have worse heat tolerance and weaker support chains. MikroTik is an option but drops 20-30% on quality.

### "Who manages Starlink accounts?"
→ FAROCON manages under service contract OR hand over dashboard credentials at commissioning. Client's choice.

### "What if Starlink raises prices?"
→ Hardware is yours, not rented. Can downgrade to Residential tier (₦38K/mo) if needed. Business pricing stable since Nigerian launch 2023.

---

## FILE STRUCTURE

```
~/Projects/docs/<project-slug>/
├── PROJECT-STATE.md
├── starlink-quote-clean.html        (or similar base HTML)
├── starlink-quote-revised-R1.html   (revision copies)
├── <project>-<ref>.pdf              (current PDF)
├── <project>-<ref>-R1.pdf           (revision PDFs)
├── <CLIENT>-MEETING-CHEATSHEET.md   (meeting prep)
└── archive/                         (old versions)
    ├── *.html
    └── *.pdf
```

---

## REFERENCES

- `references/meeting-prep-cheatsheet-pattern.md` — Annotated cheat sheet
  template from Saba Energy meeting. Shows structure: numbers → Q&A →
  close → site list.