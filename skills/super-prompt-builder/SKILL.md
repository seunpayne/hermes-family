---
name: super-prompt-builder
description: "Assemble structured super prompts for web projects — Clemenza (web-builder) or Lovable (no-code). Handles intake, brand extraction, copy writing, image briefs, and delivery path routing."
---

# Super Prompt Builder Skill

## Activation

When this skill is loaded/activated:

1. **Load the completed client brief from `~/Projects/clients/[client-name]/brief.md`**
2. **Load all decisions for the active project from Supabase**
3. **Determine delivery target.** Ask Seun if not already clear from context:
   - **Clemenza / web-builder** — our internal pipeline (React/Vite/Tailwind/Supabase/Vercel). Full spec with backend schema, RLS, chatbot config.
   - **Lovable** — no-code / AI builder. Spec is purely presentational: brand, copy, design, page structure, image generation prompts. No backend schema, no RLS, no chatbot internals.
   - **Other** — ask what they're using and adapt accordingly.
4. **Say:** "super-prompt-builder loaded. Delivery target: [Clemenza | Lovable | Other]. Reading brief for [client name]..."

---

## Token Risk Check

Before writing anything, run this check against the brief. Flag any of the following as **critical** before proceeding:

- □ Copy not provided — must be written in full, no placeholders
- □ Cultural identity requested but not specified as SVG — must be resolved first
- □ Security model or admin dashboard required but not specified
- □ Image file names not provided — for Clemenza path, exact names required
- □ Image generation prompts not written — for **Lovable path**, these are REQUIRED (see Section 6B)
- □ Light/dark mode preference not specified — must be set upfront
- □ Tech stack not confirmed — use default stack below
- □ **Tailwind CSS version not decided** — v3 (stable, safest for Lovable) vs v4 (breaking changes, CSS-first config). Lovable defaults toward v3 syntax. DECIDE before writing and pin it in the spec.
- □ Vercel/SSR config not confirmed (Clemenza path) — must be set upfront
- □ WhatsApp number not confirmed — cannot spec the button without it
- □ Chatbot requested but system prompt not written
- □ Forms required — for Clemenza: Supabase schema required. For Lovable: simple Formspree/EmailJS spec is fine
- □ **Contact info NOT env-var-hardened** — email, phone, and address must reference `import.meta.env.*` in code, never hardcoded. Hardcode only in display copy (footer, JSON-LD example).
- □ **Footer not specified** — every multi-page site needs one. At minimum: columns, links, copyright, social rule (explicitly list or say "none").
- □ **Image fallback during dev not specified** — what renders when hero images don't exist yet? Gradient? Solid colour? Specify in Section 12.
- □ **Component architecture not specified** — for 3+ pages sharing patterns (hero, service grid, CTA), specify reusable primitives to prevent copy-paste spaghetti.
- □ **Page transitions / loading states not specified** — define how routes transition (AnimatePresence fade, etc.) to avoid blank flash.
- □ **404 / catch-all route not specified** — define unhandled routes. At minimum: "Return Home" CTA.
- □ **Social links rule missing** — explicitly list socials OR explicitly state "No social links. Do not add them." Silence == Lovable invents social icons.
- □ **Button hover states not defined** — every button variant (primary gold, secondary electric blue, outline white) needs hover + active behaviour specified.
- □ **Card hover behaviour ambiguous** — if site has multiple card types across sectors, specify uniform or sector-keyed. Ambiguity creates inconsistency.
- □ **Hero overlay opacities incomplete** — every hero image section needs an explicit overlay opacity value. Leaving any blank = arbitrary default.
- □ **Formspree / backend endpoint not env-var-hardened** — form submission URL must be `import.meta.env.VITE_FORMSPREE_ENDPOINT` with a visible warning if unset.

**For any flagged item:** stop and resolve with Seun before producing the super prompt.

---

## Default Tech Stack

Use unless client has explicitly stated otherwise.

**For Clemenza / web-builder path:**

- **Framework:** React with TanStack Router
- **Routing:** One route file per page — no hash-anchor SPA
- **Styling:** Tailwind CSS v4
- **Fonts:** Google Fonts loaded in root layout head
- **Database:** Supabase — direct client, not any platform wrapper
- **Email:** Resend via server-side API route
- **Deployment:** Vercel — SSR via @vercel/node
- **Environment:** All secrets in Vercel environment variables only

**For Lovable path:**

- **Framework:** React (Lovable outputs React by default)
- **Styling:** Tailwind CSS v3/4
- **Animations:** Framer Motion (Lovable supports it natively)
- **Forms:** Formspree or EmailJS — no backend required, static compatible
- **Deployment:** Vercel or Netlify
- **SEO:** react-helmet-async (Lovable supports)
- Include the stack in the super prompt as a recommendation, but keep it flexible — Lovable may override pieces.

---

## Super Prompt Structure

Produce the super prompt as a single markdown document with these 12 sections in this exact order:

### SECTION 1 — Opening instruction

One paragraph telling the build agent what it is building, the overall tone, and the single most important thing to get right. No vagueness. This paragraph sets the standard for everything that follows.

### SECTION 2 — Technical stack

The complete default stack above unless overridden. Include: framework, routing approach, styling, fonts, database client, email service, deployment target, environment variable rules.

### SECTION 3 — Company details

All registration, address, contact, and founder information from the brief. Nothing omitted.

### SECTION 4 — Brand

Colours as hex values and CSS variable names. Typography — exact Google Font names and weights. Aesthetic reference. Dark mode behaviour. All design tokens defined here — nowhere else.

### SECTION 5 — Cultural identity

Only if requested in the brief. If yes: full SVG pattern specification, exact placements across every page and component, opacity rules, usage constraints, and one hard rule — the pattern must be implemented as a shared SVG component, not CSS or background images.

If not requested: omit this section entirely.

### SECTION 6 — Images

#### 6A — Supplied images (both paths)

Every supplied image listed as a table:

| File name | What it shows | Where it is used | Treatment |
|-----------|---------------|------------------|-----------|

Treatment instructions must be exact: overlay opacity, crop behaviour (object-top / object-center), fade direction, aspect ratio. Every image slot that has no supplied file must be flagged `{/* TODO: image required — [description] */}`.

#### 6B — AI image generation prompts (REQUIRED for Lovable path, optional but recommended for Clemenza path)

When Seun says "include image ideas" or the delivery target is **Lovable**, add this subsection. For every hero/section background that has no supplied image file, write a generation prompt.

Format:

```markdown
### [Section name] — [Slot name]

```
Prompt: [Full prompt — style, mood, colours, composition, aspect ratio, rendering engine hint]

Platform: [Midjourney / DALL·E / Stable Diffusion]
Aspect ratio: [ar tag or ratio]
```

Rules for prompts:
- Include the brand's colour palette in the prompt (Deep Navy, Electric Blue, Gold)
- Specify photographer style: "architectural photography", "cinematic", "product photography"
- Always include aspect ratio
- Always end with rendering quality tags (--v 6, 4K, photorealistic, etc.)
- For African brands: include setting and context (Nigerian, Lagos, Abuja, etc.) — not just generic "African"

At minimum, generate prompts for: hero backgrounds, section banner images, decorative between-section graphics, contact section backgrounds, and any OG-image concept.

### SECTION 7 — Site structure

One subsection per page in this format:

```markdown
### PAGE [N]: [NAME] ([/route])

[Layout description — structure, columns, grid, section order]

**[Section name]**
[Layout detail]

> [All copy for this section written in full — verbatim, ready to use]

CTA: [exact button text] → [destination route or external URL]
Animation: [exact scroll trigger, threshold, and behaviour if any]
```

Every page. Every section. All copy written out in full inside blockquotes — no placeholders. Legal pages (Privacy Policy, Terms) written in full — NDPR compliant if the company is Nigerian.

### SECTION 8 — Forms

For every form in the project, write the spec.

**Clemenza path:**

```markdown
FORM: [name]
Fields: [complete field list with type, required/optional, validation rules]
Success state: [exact message shown]
Failure state: [exact message shown]
Backend: [where data goes — Supabase table name]

Supabase schema:
[SQL CREATE TABLE statement]

RLS policies:
[SQL RLS statements — anon insert disabled, service role only]

Email notification:
[Resend config — from, to, subject, body template]
```

**Lovable path:**

Configurable: Formspree, EmailJS, or Web3Forms. Choose Formspree by default (easiest to set up in Lovable, no backend).

```markdown
FORM: [name]
Fields: [complete field list with type, required/optional, validation rules]
Success state: [exact message shown]
Failure state: [exact message shown]
Service: [Formspree / EmailJS / Web3Forms]
Backend: POST to [service endpoint]
Environment variable: [e.g. VITE_FORMSPREE_ENDPOINT]
```

For Lovable, skip Supabase schema, RLS policies, and Resend config entirely — the form is handled by the third-party service.

### SECTION 9 — Security model

Only if admin dashboard or authentication is required. If yes: auth method, protected routes, role definitions, RLS policy approach, admin email domain restriction.

If not required: omit this section entirely.

### SECTION 10 — AI chatbot

Only if requested in the brief. If yes:

```markdown
Chatbot name: [name]
Model: claude-sonnet-4-20250514
API: POST https://api.anthropic.com/v1/messages — direct, no SDK wrapper
API key source: Supabase secrets (ANTHROPIC_API_KEY)
Max tokens: 1024
anthropic-version: 2023-06-01
System prompt file: src/config/chatbot-system-prompt.js

System prompt:
[Full system prompt written out — persona, what it knows, guardrails,
escalation behaviour, what it must never do]

Rate limit: [requests per user per hour]
Escalation: [exact email or phone for handoff when chatbot cannot help]
```

If not requested: omit this section entirely.

### SECTION 11 — SEO and metadata

For every route:

```markdown
Route: [/path]
Title: [page title — under 60 characters]
Description: [meta description — under 155 characters]
OG title: [Open Graph title]
OG description: [Open Graph description]
OG image: [file name]
```

Plus: JSON-LD schema for the organisation, robots.txt rules, sitemap inclusion rules.

### SECTION 12 — Global design rules

Mandatory ruleset. Every super prompt must contain this section with AT LEAST these topics filled in. Omit only what truly does not apply.

```markdown
Navbar: [scroll behaviour, transparent state, mobile collapse behaviour, active page indicator]
Footer: [background colour, column layout, links, copyright line, social rule — list socials or explicitly say "No social media icons. No social links. Do not add them."]
WhatsApp button: [scroll depth trigger — 15% default, pre-filled message text, position, number must read from env var, never hardcoded]
Accessibility: [html lang attribute, viewport meta, focus states, ARIA labels, skip-to-content, colour contrast minimums, alt text rule]
Mobile behaviour: [breakpoints, stacking rules, nav collapse breakpoint, padding reduction ratio]
Animation rules: [scroll trigger approach, duration defaults, easing, stagger delays, no parallax/no continuous, prefers-reduced-motion override, AnimatePresence page transitions with duration]
Button & hover states: [every button variant: primary gold (hover background, transition, active scale), secondary electric blue, outline white. Include hex values.]
Card hover behaviour: [if multiple card types/sectors exist, specify per-sector or uniform. Template: "hover lifts N px, [colour] [side]-border reveal (N px solid), Ns ease."]
Hero image overlays: [every hero section gets an explicit overlay opacity. If N pages share a hero component, say "uniform X%" or list per page.]
Image fallback during dev: [exact gradient or colour to use while image files are pending. Rule: do not use placeholder.com, unsplash, or lorem picsum.]
Component architecture: [list reusable components: <HeroBanner />, <ServiceGrid />, <SectionCTA />, <PageBanner />, <Card />, button variants. Each with brief props API. Rule: each page composes from primitives — no copy-pasting layout code.]
Copy rules: [hard rule — all copy in this prompt is final. Do not rewrite, summarise, or paraphrase any of it.]
```
---

## Pre-Submission Blindspot Scan

Before presenting the super prompt to Seun, run this self-review. It mirrors the dimensions Seun actually checks when reviewing. Grade each item and fix before submission.

### Structure review (pass/fail each)

Use these categories. Every FAIL must be fixed before presenting.

**🔴 Hard failures — fix before presenting:**
- [ ] Every env-var-eligible value (phone, email, Formspree endpoint) is referenced as `import.meta.env.VITE_*` with a hard rule against hardcoding at the code level. Exception: display copy (footer text) can show the actual value as fallback.
- [ ] Tailwind version is explicit and justified (v3 with config path for Lovable, v3 or v4 for Clemenza).
- [ ] No duplicate form field specs — if Section 7 shows a form and Section 8 defines it, Section 8 is marked canonical with a deferral note.
- [ ] Form submission endpoint is an env var, with a visible warning if unset.

**🟡 Design consistency — fix before presenting:**
- [ ] All hero image overlays have explicit opacity values. Zero blanks.
- [ ] Button hover/active states defined for every variant present in the spec.
- [ ] Card hover behaviour is either "uniform" or sector-keyed per page. No ambiguity.
- [ ] Image fallback gradient/colour specified for all slots during development.
- [ ] Social links rule present: list socials OR "no social links — do not add them."

**🟠 Coverage gaps — fix before presenting:**
- [ ] Footer defined (columns, links, copyright, social rule).
- [ ] Component architecture specified for 3+ page sites.
- [ ] Page transitions defined (AnimatePresence fade or similar).
- [ ] 404/catch-all route defined.
- [ ] Navbar specified (scroll behaviour, transparent/white state, active indicator).
- [ ] WhatsApp button: number read from env var, not hardcoded.

**🟢 Per-page completeness:**
- [ ] Every route has a title, meta description, OG title, OG description.
- [ ] Every section has copy written in full (blockquotes).
- [ ] Every image slot either has a supplied file name or an AI generation prompt.
- [ ] JSON-LD schema present with actual (not placeholder) values.
- [ ] Sitemap generation method specified (vite-plugin-sitemap or manual).

### Procedural rule

If ANY 🔴 item fails, STOP. Do not present. Fix it.
If 3+ 🟡 items fail, STOP. Fix them.
If any 🟠 item fails, fix before presenting (they fill quickly and degrade quality).
🟢 failures are acceptable to flag as "TODO" in the output summary — but try to fill them.

### After scan

On completion: say "Blindspot scan passed. [N]🔴, [N]🟡, [N]🟠, [N]🟢 gaps fixed." Then present.

---

## Handling Blindspot Feedback

When Seun returns a blindspot review (as he will — he checks everything):

1. **Categorise every finding** into the 4-tier framework above (🔴/🟡/🟠/🟢). This maps directly onto his review categories.
2. **Resolve all 🔴 items first** — env var hardening, Tailwind version, form duplication, form endpoint. Everything below depends on these.
3. **Resolve 🟡 items next** — design consistency issues (overlays, hover states, card behaviour, image fallbacks, social rule).
4. **Resolve 🟠 items** — coverage gaps (footer, components, transitions, 404, navbar, WhatsApp).
5. **Resolve 🟢 items** — per-page completeness (SEO, copy, images, schema, sitemap).
6. **For each finding:** explain the fix explicitly. Use the existing spec text as old_string and the corrected text as new_string.
7. **Re-present** with a delta summary: "All [N] items resolved. Remaining: [list of any you chose to leave open with reason]."
8. **Wait for explicit approval** before routing.

**Rule:** Never present a super prompt with unresolved 🔴 items. Seun will catch them, and it erodes confidence in the spec's completeness.

## After Producing the Super Prompt

1. **Run the Pre-Submission Blindspot Scan** (above). Fix all 🔴, 🟡, and 🟠 items before proceeding.
2. **Save it to:** `~/Projects/clients/[client-name]/super-prompt-v1.md`
3. **Log completion as a decision in Supabase**
4. **Present it to Seun for review** with blindspot scan results included.
5. **Say:** "Super prompt complete. [X] pages specified. [Y] image generation prompts. [Z] blindspot scan gaps fixed (N🔴/N🟡/N🟠/N🟢). Delivery target: [Clemenza | Lovable]. Review and type APPROVE to pass along, or request changes."

**On APPROVE:**

- **Clemenza path:** Load web-builder skill. Pass the super prompt as the first message. Say "Clemenza — build: [project name]. Seun approved. Full spec in attached document."
- **Lovable path:** Seun will drop it into Lovable directly. No build agent needed. Say "Super prompt ready for Lovable. All copy is verbatim. Drop the document into Lovable as your starting prompt. Generate the hero/background images using the prompts in Appendix A before pasting in, so you can slot them in as you build."
- **Other path:** Confirm the handoff destination with Seun, then route accordingly.

---

**Lovable-specific pitfalls**

1. **Copy is final.** Lovable may try to rewrite copy. The super prompt must include a hard rule: "All copy in blockquotes is verbatim. Do not rewrite, summarise, or paraphrase." Flag this prominently in Section 12.
2. **Image generation prompts must be in the document itself**, not a separate file. Lovable users work inline. Append them as an appendix.
3. **No backend assumptions.** Lovable handles forms via Formspree/EmailJS. Do not specify Supabase schemas or RLS policies — they add noise and confuse the prompt.
4. **Stack as recommendation, not requirement.** Lovable has its own opinions on routing, state management, and component structure. Specify what the output should look like (pages, sections, behaviours) — not how to implement it internally.
5. **Animations must be tool-agnostic.** Specify the trigger, duration, easing, and visual effect — not the Framer Motion API signature. Let Lovable translate.
6. **Keep forms simple.** Specify field names, validation rules, success/failure text, and the third-party endpoint. That's all Lovable needs.
