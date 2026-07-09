# Career Files — Path Reference

**Last verified:** May 25, 2026

---

## Career File Locations

All career-related files live under `~/.openclaw/career/`, NOT `~/.hermes/career/`.

This is a migration artifact from the OpenClaw → Hermes transition.
Career files were not moved during migration.

---

## Required Files

| File | Path | Purpose |
|------|------|---------|
| CV Master | `~/.openclaw/career/cv-master.md` | Seun's master CV — source of truth for all career applications |
| Claims | `~/.openclaw/career/claims.md` | Verified career claims with evidence references |
| Applications | `~/.openclaw/career/applications/` | Output directory for tailored CVs, cover letters, application answers |

---

## Supabase Career Schema

Career data is isolated in Supabase under the `career` schema:

- `career.career_profile` — Seun's professional profile
- `career.career_applications` — Track applications submitted
- `career.career_answers` — Stored answers to common application questions
- `career.career_claims` — Verified claims with evidence
- `career.career_documents` — CV versions, cover letters, portfolios

**Isolation rule:** Career agents (Sollozzo, Tom, Abbandando) NEVER access client delivery tables. Client delivery agents NEVER access career tables.

---

## For Agents

When the `career-preparer` skill activates:
1. Load CV from `~/.openclaw/career/cv-master.md`
2. Load claims from `~/.openclaw/career/claims.md`
3. Query `career.career_claims` from Supabase
4. Output tailored documents to `~/.openclaw/career/applications/[company]-[role]-[date]/`

**Do NOT assume** files exist at `~/.hermes/career/` — that path does not exist.

---

## Migration Status

As of May 2026:
- Career files remain at `~/.openclaw/career/`
- No migration to `~/.hermes/` planned
- Skills reference the correct OpenClaw paths
