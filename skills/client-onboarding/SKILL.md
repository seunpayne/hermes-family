---
name: client-onboarding
description: Run structured client intake and generate project scope documents. Use when onboarding new clients or defining project requirements.
---

# Client Onboarding Skill

## Activation

When this skill is loaded/activated:

1. **Gatekeeper pre-flight runs automatically**
2. **Load any existing client record from Supabase `clients` table**
3. **Say:** "Hagen here. Let's build the client brief. I'll work through each section — answer as completely as you can. Anything missing I'll flag at the end."

---

## Structured Brief Collection

Work through all ten sections in order. Present each section as a block — wait for answers before moving to the next.

### SECTION 0.1 — Company

```
COMPANY NAME:
RC / REGISTRATION NUMBER:
REGISTERED ADDRESS:
FOUNDED:
FOUNDER NAME:
FOUNDER TITLE:
INDUSTRY / SECTOR:
ONE-LINE POSITIONING:
TAGLINE (if any):
```

### SECTION 0.2 — Audience and tone

```
PRIMARY AUDIENCE:
(e.g. HNW individuals / enterprise / institutional / SME / retail)

SECONDARY AUDIENCE (if any):

TONE:
(e.g. authoritative and approachable / bold and direct / premium and restrained)

WHAT THE COMPANY IS NOT:
(positioning guardrails — what to avoid sounding like)
```

### SECTION 0.3 — Brand

```
LOGO FILE NAME:

PRIMARY COLOUR (HEX):

SECONDARY COLOUR (HEX):

ACCENT / PATTERN COLOUR (HEX): (optional)

DARK MODE: yes / no / system preference

CULTURAL IDENTITY ELEMENT: yes / no
If yes:
  PATTERN STYLE: (e.g. Yoruba ankara / Adire / Kente / geometric)
  PATTERN APPLICATION: (describe where it appears)
  PATTERN COLOUR: (hex)

TYPOGRAPHY PREFERENCE: (specific fonts or general direction)
```

### SECTION 0.4 — Contact and compliance

```
DOMAIN:

CONTACT EMAIL:

PHONE / WHATSAPP NUMBER:

WHATSAPP ENABLED: yes / no

SOCIAL LINKS: (LinkedIn / X / Instagram / etc.)

REGULATORY BODY: (if applicable)

COMPLIANCE CREDENTIAL: (e.g. SEC licence number, NDPC cert)
```

### SECTION 0.5 — Pages

```
LIST ALL PAGES REQUIRED:
(e.g. Home / Services / About / Contact / Privacy Policy)

LEGAL PAGES: (Privacy Policy / Terms / Cookie Policy)
```

### SECTION 0.6 — Services or products

```
LIST ALL SERVICES OR PRODUCTS:
For each:
  NAME:
  ONE-LINE DESCRIPTION:
  KEY FEATURES / OFFERINGS:
  STATUS: (active / emerging / by selection)
```

### SECTION 0.7 — Proof and credibility

```
CASE STUDIES: yes / no
If yes, for each:
  SECTOR:
  PROJECT TITLE:
  SUMMARY: (what the problem was, what was done)
  OUTCOME: (result — or "currently in delivery" if active)

STATISTICS / PROOF POINTS:
(e.g. years active, projects delivered, sites deployed)

CLIENT LOGOS / SECTORS: (named clients if permitted, or sectors only)

TESTIMONIALS: yes / no
```

### SECTION 0.8 — Backend requirements

```
CONTACT FORM: yes / no

ADDITIONAL FORMS: (list if any)

SUPABASE BACKEND: yes / no

EMAIL NOTIFICATIONS: yes / no
If yes, NOTIFICATION EMAIL:

ADMIN DASHBOARD: yes / no
If yes, ADMIN EMAIL DOMAIN: (e.g. @company.com)

AI CHATBOT: yes / no
If yes:
  CHATBOT NAME:
  CHATBOT PERSONA: (describe in a sentence)
  WHAT CHATBOT KNOWS: (list services / products it should discuss)
  WHAT CHATBOT MUST NOT DO: (guardrails)
  ESCALATION CONTACT: (email / phone for handoff)
```

### SECTION 0.9 — Images and assets

```
LIST ALL SUPPLIED IMAGES:
(file name → what it shows → where it is used)

IMAGES STILL NEEDED: (slots that need generation or sourcing)
```

### SECTION 0.10 — Any other requirements

```
ANYTHING ELSE THAT MATTERS:
(competitive context, previous site issues, hard requirements,
launch deadline constraints, migration plans, etc.)
```

---

## After All Sections Complete

**Flag every blank or vague field clearly:**

```markdown
MISSING INFORMATION — required before The Don can plan:
[list each missing field and why it matters]

FLAGGED FOR ASSUMPTION — will proceed with these unless corrected:
[list each assumed value and the assumption made]
```

**Write the complete brief:**

1. **To Supabase:** Insert into `clients` and `projects` tables
2. **To disk:** Save as `~/Projects/clients/[client-name]/brief.md`
3. **Log to Supabase:** Insert into `decisions` table

**Say:** "Brief complete. [X] fields collected. [Y] items flagged. Pass this to super-prompt-builder when ready."

---

## Brief Markdown Template

```markdown
# Client Brief: [Company Name]

## Section 0.1 — Company
[All fields]

## Section 0.2 — Audience and tone
[All fields]

## Section 0.3 — Brand
[All fields]

## Section 0.4 — Contact and compliance
[All fields]

## Section 0.5 — Pages
[All fields]

## Section 0.6 — Services or products
[All fields]

## Section 0.7 — Proof and credibility
[All fields]

## Section 0.8 — Backend requirements
[All fields]

## Section 0.9 — Images and assets
[All fields]

## Section 0.10 — Any other requirements
[All fields]

---

## Missing Information
[list]

## Flagged Assumptions
[list]
```
