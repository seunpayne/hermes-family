---
name: sales-proposal-generator
description: Generates website redesign proposals for
  Abuja SME prospects. Activated by Telegram from N8N
  when a qualified prospect needs a proposal. Generates
  homepage concept via Apollonia, personalised copy via
  Kay, and 5-page PDF via Hagen. Drafts WhatsApp and
  Instagram messages for Seun to send manually.
license: MIT
metadata:
  author: The Don
  version: "1.0"
  organization: TMG Capital
  date: May 2026
  abstract: End-to-end sales proposal generation for qualified Abuja SME prospects. Orchestrates Apollonia (concept images), Kay (proposal copy), and Hagen (PDF generation). Outputs draft WhatsApp and Instagram messages for Seun to send manually. Never sends anything without Seun's explicit approval.
---

# SKILL: sales-proposal-generator
# Version: 1.0

---

## ACTIVATION

Receives via Telegram from N8N notification when a prospect is qualified.
Prospects arrive via the **client-discovery** pipeline (`sales/client-discovery`):
  discovered → pending → qualified → proposal_ready

Read full prospect from Supabase:

```sql
SELECT * FROM sales_prospects
WHERE business_name = '[name]'
AND status = 'qualified'
ORDER BY created_at DESC LIMIT 1
```

---

## STEP 1 — BRAND EXTRACTION

**Type A (has website):**
- Visit `website_url`
- Extract: colours, logo style, font, tone
- Note ONE specific problem in one sentence.

Examples:
- "No mobile layout — site breaks on phones"
- "Last updated [year estimate] — looks outdated"
- "No clear contact button or call to action"
- "Site loads slowly — images not compressed"

**Type B (Instagram only):**
- Visit `instagram.com/[handle]`
- Extract: colours, aesthetic, content style
- Observation: "Your business has [N] Instagram followers but no website — invisible on Google"

---

## STEP 2 — APOLLONIA GENERATES HOMEPAGE CONCEPT

```python
delegate_task(
  goal="Generate a full homepage concept for [name].
  This is a sales proposal. Make it impressive.
  4 images — one per section.",
  context="""
  Business: [name] | Category: [category]
  Area: [area], Abuja | Type: [A/B]
  Brand signals: [extracted colours, style, tone]

  IMAGE 1 — Hero:
    Large, professional. Business name prominent.
    Their brand colours. Clear CTA button.
    Photography: [relevant to category].
    NO generic stock photos. NO indigo.

  IMAGE 2 — About/Services:
    Clean grid. 4-6 key services or offerings.
    Monoline SVG icons. Their accent colour.

  IMAGE 3 — Gallery/Showcase:
    Products, team, space, or portfolio.
    Grid layout. Real photo aesthetic.

  IMAGE 4 — Contact/CTA:
    WhatsApp button prominent (green).
    Address. Simple contact form.
    Strong closing statement.

  Save to:
  ~/Projects/sales/proposals/[slug]/concept/
  where slug = business name, lowercase, hyphens
  """,
  toolsets=["file", "image_gen"],
  model="anthropic/claude-sonnet-4-6"
)
```

---

## STEP 3 — KAY WRITES COPY

```python
delegate_task(
  goal="Write sales proposal copy for [name].
  Max 200 words. Direct. No jargon. No hype.
  Nigerian professional English.",
  context="""
  Business: [name] | Category: [category]
  Area: [area] | Type: [A/B]
  Observation: [from Step 1]

  STRUCTURE — follow exactly:

  Sentence 1: Who I am.
    'My name is Seun, I build websites for
    businesses in Abuja.'

  Sentence 2-3: Specific observation about them.
    Reference their actual business.
    Never generic. Never flattering.

  Sentence 4-5: What I built.
    'I spent time building a concept for [name]
    — what it could look like with a proper website.'

  Sentence 6-7: The offer.
    '₦150,000 one-time, live in 5-7 working days.
    Or ₦25,000/month with no upfront cost.'

  Sentence 8: CTA.
    'Let me know if you would like to see it.'

  DO NOT USE:
  'I hope this message finds you well'
  'I am reaching out'
  'Dear Sir/Ma'
  Any superlative about their business
  """,
  toolsets=["file"],
  model="deepseek-v4-pro"
)
```

---

## STEP 4 — WHATSAPP AND INSTAGRAM DRAFTS

Write two message drafts for Seun to send manually.

**WhatsApp (for phone contact):**
Short. Personal. Max 3 sentences.

```
Hi [first name / boss], I'm Seun from Abuja.
I built a website concept for [Business Name]
after seeing your [current site / Instagram].
Mind if I send it over?
```

**Instagram DM (for Instagram-only businesses):**
Even shorter. 2 sentences.

```
Hi [handle] — I designed a website concept
for your business. Worth 2 minutes?
Can I send it?
```

---

## STEP 5 — HAGEN GENERATES PDF

```python
delegate_task(
  goal="Generate 5-page PDF proposal for [name].",
  context="""
  Page 1: Cover
    Business name large.
    'A website concept by Seun [or studio name]'
    Date. Clean, minimal.

  Page 2: Current State
    Screenshot of their current site OR Instagram.
    One sentence observation below it.
    Label: 'Today'

  Pages 3-4: The Concept
    Apollonia's 4 images laid out as homepage.
    Flowing page layout, top to bottom.
    Label: 'What it could be'

  Page 5: The Offer
    Kay's proposal copy.
    Pricing table:
      Option A: ₦150,000 — full website, 5-7 days
      Option B: ₦25,000/month — no upfront, 3-month minimum
    What is included (both options):
      Design and development
      Mobile responsive
      Contact form
      WhatsApp button
      Google Analytics
      1 month of support
    Seun's WhatsApp number — large and clear.

  Images from: ~/Projects/sales/proposals/[slug]/concept/
  Output: ~/Projects/sales/proposals/[slug]/proposal.pdf
  """,
  toolsets=["file", "terminal"],
  model="deepseek-v4-flash"
)
```

---

## STEP 6 — UPDATE SUPABASE AND NOTIFY SEUN

After PDF confirmed:

```sql
UPDATE sales_proposals SET
  proposal_copy = '[copy]',
  pdf_path = '[path]',
  whatsapp_draft = '[draft]',
  instagram_draft = '[draft]',
  status = 'ready',
  generated_at = now()
WHERE prospect_id = '[id]';

UPDATE sales_prospects
SET status = 'proposal_ready',
    updated_at = now()
WHERE id = '[prospect_id]';
```

**Send Telegram to Seun:**

```
✅ Proposal ready — [Business Name]
[Category] | [Area], Abuja
Score: [N]/10 | Type: [Redesign/New Website]

Observation: [one sentence from Step 1]

PDF: ~/Projects/sales/proposals/[slug]/proposal.pdf

─── WhatsApp (copy-paste) ───
[WhatsApp draft from Step 4]
─────────────────────────────

─── Instagram DM (copy-paste) ───
[Instagram draft from Step 4]
─────────────────────────────

Email outreach via N8N starts tomorrow.
Reply HOLD to pause. Reply SKIP to disqualify.
```

---

## HARD RULES

1. **Never fabricate website flaws** — only state what is actually visible.
2. **Never promise under 5 working days.**
3. **Always give Seun the HOLD option.**
4. **Never send anything without Seun's copy-paste message** being included in the Telegram notification.
5. **Never auto-send proposals** — Seun manually sends via WhatsApp or Instagram DM.
6. **N8N handles email outreach only** — starts 24 hours after proposal is marked ready.

---

## FILE STRUCTURE

```
~/Projects/sales/proposals/[slug]/
├── concept/
│   ├── 01-hero.png
│   ├── 02-services.png
│   ├── 03-gallery.png
│   └── 04-contact.png
├── proposal.pdf
└── metadata.json
```

---

## PROSPECT TYPE DETECTION

| Signal | Type | Score Impact |
|--------|------|--------------|
| No website, has Instagram | `new_build` | +5 |
| DIY builder (Wix, WordPress.com) | `redesign` | +4 |
| Custom website | `redesign` | +2 |

---

## PRICING (FIXED)

| Option | Price | Terms |
|--------|-------|-------|
| A — One-time | ₦150,000 | Full website, 5-7 days |
| B — Monthly | ₦25,000/month | No upfront, 3-month minimum |

**Both options include:**
- Design and development
- Mobile responsive
- Contact form
- WhatsApp button
- Google Analytics
- 1 month of support

---

## ESCALATION

Stop and wait for Seun if:
- Prospect has no website AND no Instagram (cannot extract brand)
- Website is password-protected or returns 404
- Instagram account is private
- Business category is unclear or high-risk
- Prospect already has a recent website (within 6 months)

Declare: `"BLOCKED — [business name] — [reason]"`
Log to `sales_prospects.disqualify_reason`
Set status to `cold`
