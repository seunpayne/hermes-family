# Four-Lane Boundary — Design Decisions

## The Violation (Sani General Stores, 2026-05-20)

**What happened:**
The Don generated a complete super prompt with Section 2 (Design Language) fully populated — including colour palette (#065F46, #F97316, #F59E0B), typography (Inter), and cultural elements — without routing to Apollonia first.

Seun caught it immediately: "I don't see any design work by apollonia."

**Why this is a violation:**
- Apollonia owns brand decisions and design tokens
- The Don/Michael/Kay do NOT make design decisions
- Super prompt Section 2 should be populated BY Apollonia's output, not guessed

## Correct Flow

1. Intake complete (Michael)
2. **Apollonia activation** — produces design tokens:
   - Colour palette (hex codes with rationale)
   - Typography (system font recommendation)
   - Cultural element/motif
   - Tone guidance (IS / NOT adjectives)
   - Dark mode recommendation
3. Kay writes Section 2 + Section 4 using Apollonia's tokens
4. Full super prompt presented to Seun

## Detection Checklist

Before presenting super prompt, verify:
- [ ] Apollonia was activated for this project
- [ ] Design tokens are attributed to Apollonia in Section 2
- [ ] Colour palette has hex codes + rationale (not just names)
- [ ] Typography has performance justification (not just preference)

## Fix Procedure

If violation detected mid-session:
1. Acknowledge the violation immediately
2. Activate Apollonia
3. Wait for design tokens
4. Patch super prompt Section 2 with attributed tokens
5. Log the lesson to .learnings/

## Apollonia's Output Format

```markdown
## Design Tokens — [Project Name]
Primary: [hex] — [rationale]
Secondary: [hex] — [rationale]
Accent: [hex] — [rationale]
Typography: [font] — [performance/cultural rationale]
Cultural Element: [description]
Tone IS: [adj], [adj], [adj]
Tone NOT: [adj], [adj], [adj]
Dark Mode: [YES/NO — rationale]
```

## Related

- SOUL.md: "The Four-Lane Boundary" section
- coding-project skill: HARD RULES #11
- strategist skill: Michael's role definition
