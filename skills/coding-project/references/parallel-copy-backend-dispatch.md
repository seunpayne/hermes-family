# Parallel Copy + Backend Dispatch

When a task involves both Clemenza (backend code) and Kay (copy), dispatch
them in parallel to avoid blocking:

## Pattern

```
→ Create task in Supabase with agent="Clemenza + Kay"
→ Dispatch Kay FIRST (fast, file-only task):
    delegate_task(
      goal="Write all copy for [feature]: [specific items needed]",
      context="PRD copy requirements, tone guidance (Ilu: community warmth
        + institutional authority), audience, output format",
      toolsets=["file"]
    )
→ Dispatch Clemenza in SAME batch (or immediately after Kay):
    delegate_task(
      goal="Build [feature] backend: [specific endpoints]",
      context="Copy exists at src/common/i18n/[feature].en.ts when done",
      toolsets=["terminal", "file"]
    )
```

## Why it works

Kay's copy tasks complete in 30-60 seconds (file-only, no build steps).
Clemenza's build tasks take 3-10 minutes. Running them sequentially
wastes Kay's available time. Running them in parallel means Kay's output
is often ready before Clemenza needs it.

## Output location

Kay writes to `src/common/i18n/[feature].en.ts` with a matching
TypeScript export. The copy is a structured object, not free-form text.
Clemenza imports from this file when rendering UI text or composing
notification messages.

## When NOT to use

- If the copy defines the UI structure (e.g. form labels determine
  field order, which determines DTO shape) — do copy first, then dispatch
  backend after Kay confirms
- If Clemenza needs copy content to make API design decisions —
  dispatch sequentially
