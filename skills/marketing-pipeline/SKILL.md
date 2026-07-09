---
name: marketing-pipeline
description: Generates launch content across LinkedIn, X, email, and messaging platforms. Applies brand voice from decisions. Saves all approved content to disk and Supabase. Never publishes without explicit approval.
---

# Marketing Pipeline Skill

## Activation

**When activated:**
1. Gatekeeper pre-flight runs automatically
2. Check that Resend is authenticated in `~/.env.openclaw`
3. Query Supabase for the active project and client details
4. Load all brand voice and copy decisions for the active project from `decisions` table
5. Say: **"marketing-pipeline loaded. Generating launch content for [project name] — [client name]."**

---

## PHASE 1 — GATHER CONTEXT

**Before writing anything, pull all available context from Supabase:**

```sql
SELECT
 p.name as project_name,
 p.type as project_type,
 p.production_url,
 c.name as client_name,
 c.company,
 d.decision,
 d.rationale
FROM projects p
JOIN clients c ON c.id = p.client_id
LEFT JOIN decisions d ON d.project_id = p.id
 AND d.reversed = false
 AND (
 d.affects @> '["copy"]'
 OR d.affects @> '["brand"]'
 OR d.affects @> '["client-facing output"]'
 )
WHERE p.id = '[active_project_id]'
ORDER BY d.created_at ASC;
```

**Also ask Seun:**

1. What is the single most important thing this project does for the client's audience?
2. Are there any specific features, stats, or outcomes worth highlighting?
3. Is there anything that should NOT be mentioned publicly?
4. Who is posting this — Seun's agency, the client's own accounts, or both?

**Log any answers as decisions if they affect brand direction.**

---

## PHASE 2 — GENERATE LAUNCH CONTENT

**Generate all formats in one pass. Apply the client's confirmed brand voice throughout.**

---

### FORMAT 1 — LinkedIn Post

**Rules:**
- 150 to 250 words
- Professional but human tone
- Lead with the outcome or transformation, not the features
- Include one specific detail that makes it real — a number, a name, a problem solved
- End with a soft call to action — invite curiosity, not clicks
- No hashtag spam — maximum three relevant hashtags at the end
- No em dashes
- No corporate buzzwords

**Template:**
```
[DRAFT — LinkedIn]

[Opening line that stops the scroll]

[Two to three short paragraphs covering:
 — What was built and for whom
 — What problem it solves or opportunity it creates
 — One specific detail that makes it credible]

[Closing line — invitation, question, or quiet pride]

[production URL]

#[tag1] #[tag2] #[tag3]
```

---

### FORMAT 2 — X Post (Single)

**Rules:**
- Under 280 characters
- Lead with the most interesting thing
- One link — the production URL
- Zero hashtags unless the project is genuinely trending adjacent

**Template:**
```
[DRAFT — X single post]

[Punchy single sentence — what was built and why it matters]
[production URL]
```

---

### FORMAT 3 — X Thread

**Rules:**
- Four to six posts
- Post 1 hooks — what was built, why it is interesting
- Posts 2 to 4 go deeper — problem, solution, one feature worth explaining
- Post 5 shows the result — live URL, screenshot reference, or outcome
- Post 6 optional — personal reflection or invitation to connect
- Each post standalone readable
- Thread numbered: 1/ 2/ 3/ etc.

**Template:**
```
[DRAFT — X thread]

1/ [Hook]

2/ [The problem or context]

3/ [The solution or what was built]

4/ [One specific thing worth knowing]

5/ [The result — live at: production URL]

6/ [Optional closing thought]
```

---

### FORMAT 4 — Email Announcement

**Rules:**
- Subject line under 50 characters
- Preview text under 90 characters
- Three sections: what launched, why it matters, what to do next
- One clear CTA button — Visit the site
- No images in the template — copy only, Resend handles rendering
- Signed off personally — not from "The Team"

**Template:**
```
[DRAFT — Email]

SUBJECT: [subject line]
PREVIEW: [preview text]

---

Hi [first name],

[Opening paragraph — what just launched and the one sentence
reason they should care]

[Middle paragraph — what this means for them specifically.
Reference their industry, use case, or something personal
if known from the client record]

[Closing paragraph — simple, warm, no pressure]

[CTA: Visit [project name] → production URL]

[Sign-off]
[Seun / Agency name]
```

---

### FORMAT 5 — WhatsApp or Telegram Broadcast

**Rules:**
- Conversational, not corporate
- Under 100 words
- Reads like a message from a person, not a press release
- One link at the end
- Emoji optional — one maximum if brand allows

**Template:**
```
[DRAFT — WhatsApp/Telegram]

[Casual opener — as if messaging someone you know]
[What launched in one or two sentences]
[Why they might find it interesting]
[Link — production URL]
```

---

## PHASE 3 — REVIEW AND APPROVAL

**Display all five drafts in sequence.**

**Say:** "Here is the launch content for [project name]. Review each format and request changes by saying 'revise [format name]'. When you are happy with a format type 'approve [format name]'. Type 'approve all' to approve everything at once."

**For each revision request:**
- Rewrite only the requested format
- Display the revised version
- Do not change approved formats

---

## PHASE 4 — SAVE AND DELIVER

**When a format is approved:**

1. **Save it as a markdown file** to `~/Projects/content/[client-name]/[project-name]/launch-[format-name].md`
2. **Write an asset record** to Supabase `assets` table

**When all formats are approved:**

**Ask:** "Ready to send the email announcement? Confirm the recipient list or type SAVE to store without sending."

**If send is confirmed:**
- Use Resend to deliver the email to the confirmed list
- Log the send to Supabase `billing_events` table
- Update the asset record status to `sent`

**For all other formats — LinkedIn, X, WhatsApp:**
- Save the approved copy to file
- Display each one formatted cleanly for easy copy-paste
- Say: "Social copy saved. Post manually to your accounts or paste directly from the files above."

**Log all approved content as a decision in Supabase:**
```sql
INSERT INTO decisions (
 project_id,
 client_id,
 made_by,
 decision,
 rationale,
 affects,
 reversible
) VALUES (
 '[project_id]',
 '[client_id]',
 'Seun',
 'Launch content approved for [project name] across [list of formats]',
 'All formats reviewed and approved before distribution',
 ARRAY['copy', 'client-facing output', 'brand'],
 false
);
```

---

## ADDITIONAL COMMANDS

### regenerate all
Scraps all drafts and generates fresh versions with a different angle.

### generate teaser
Produces a shorter pre-launch version of the LinkedIn and X posts for building anticipation before go-live. Uses the staging URL with a "coming soon" message.

### generate case study
After a project has been live for 30 days, pulls the project record from Supabase and generates a longer form case study draft covering:
- Client challenge
- Solution built
- Outcome
- A quote placeholder for client testimonial

---

## Standing Rules

1. **Never publish or send anything without explicit approval from Seun**
2. **Never mention client financials, internal team details, or anything marked sensitive in the project record**
3. **Always apply the confirmed brand voice from the decisions table**
4. **If brand voice is absent:** ask Seun before generating any client-facing content
5. **Save every approved piece of content to both disk and Supabase** before considering the task complete

---

## Supabase Tables Used

- `projects` — Read project context and production URL
- `clients` — Read client information
- `decisions` — Read brand/copy decisions, write content approval decisions
- `assets` — Write approved content assets
- `billing_events` — Log email send costs (Resend)

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.openclaw`
- `SUPABASE_SECRET_KEY` from `~/.env.openclaw`
- `RESEND_API_KEY` from `~/.env.openclaw`

---

## Error Handling

If Resend send fails:
1. Log error to `agent_runs`
2. Alert Seun with error details
3. Do not retry more than twice without approval
4. Keep asset status as `pending` until confirmed sent

If brand voice is missing from decisions:
1. Pause generation
2. Ask Seun for brand voice clarification
3. Log response as a decision before proceeding
4. Do not generate content without confirmed voice
