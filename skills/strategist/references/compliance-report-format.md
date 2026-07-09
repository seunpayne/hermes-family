# Compliance Report Format (Michael)

## When to produce

When Seun asks for a compliance review of one or more codebases against a PRD. Produced after code is built, before deployment approval. This is a READ-ONLY output — Michael produces the report, The Don dispatches resulting addenda.

## Inputs
- PRD document (source of truth for requirements)
- Primary codebase (e.g. `main` branch, the Family build)
- Secondary codebase(s) for comparison (optional, e.g. `cc-build` from Claude Code)
- Compliance report template/document if provided

## Process summary

1. Clone secondary branches to `/tmp/` for side-by-side comparison with the primary
2. Run every requirement against each codebase independently — do not cross-contaminate
3. Per requirement: PASS / DIVERGENCE / FAIL, each with specific file evidence
4. Classify priority with gate qualification (staging vs production)
5. Produce structured report with delta comparison
6. Output addenda for Clemenza execution (CHANGE / DO NOT CHANGE / AFTER IMPLEMENTING)

## Output structure

### Executive Summary
Comparison table across: architecture, data entities, functional requirements, tests, key differentiators. One-line recommendation of primary codebase.

### Data Model Compliance (Section 2)
Table per entity: entity name → PASS/DIVERGENCE/FAIL per codebase. Notes for field/enum differences, schema design choices. Summary row with pass/divergence/fail counts.

### Functional Requirements Compliance (Section 3)
All FRs from PRD mapped to implementation. Columns: FR number, requirement, verification method, status per codebase, evidence notes. When a codebase has extra entities not in the PRD (e.g. separate User or Announcement models), flag as DIVERGENCE not FAIL.

### API Compliance (Section 4)
Endpoint table: method + path, required auth, status per codebase, notes. 15 core endpoints from PRD Section 13 must match exactly.

### Security & Compliance (Section 5)
Security controls against PRD Section 15: MFA, QR encryption, audit logging, consent enforcement, PII encryption, RBAC, cross-tenant isolation, CI/CD security, HTTPS, webhook validation. Each gets PASS/DIVERGENCE/FAIL.

### Non-Functional Requirements (Section 6)
Performance targets, Lighthouse scores, offline verification, multi-tenant isolation, sync indicators, SOS tap count.

### UI/UX Compliance (Section 7)
Design system: fonts, colour tokens, Tailwind defaults, icon choices, border radius, tap targets, colour+icon pairing, empty states, consent capture, phase progress card.

### Integration Compliance (Section 8)
Third-party integrations: Siteti, Termii, Paystack, S3, BullMQ, Sentry, BetterStack, Telegram. Each is PASS / stub / FAIL.

### Delta Report (Section 9 — when comparing 2+ codebases)
Side-by-side table per comparison area: architecture, QR encryption, RBAC, WhatsApp, SOS, offline cache, Paystack, enumeration validation, phase checklist, notifications, audit logging, offboarding, early access, Consigliere, RLS, identity tiers. Each row has implementation A, implementation B, and a specific recommendation (keep A, cherry-pick from B, or Seun decision).

### Clemenza Addendum (Section 10)
FAIL and DIVERGENCE items formatted as executable addenda. Each has:
- ADD-XXX identifier
- Priority (P0 staging / P0 production gate / P1)
- Exact file path and component
- CONTEXT, CHANGE, DO NOT CHANGE, AFTER IMPLEMENTING

### Sign-Off (Section 11)
Gates: review complete per codebase, delta complete, FAIL items resolved or risk-accepted, addenda closed, Seun deployment approval.

## Priority classification rules
- P0 staging: blocks staging deployment (broken auth, data loss risk)
- P0 production gate: blocks real data but not staging (PII encryption, DPA signing endpoint)
- P1: fix before steady state
- NDPR/DPIA compliance requirements are ALWAYS P0 for production gate, even if P1 for staging
- Never say "fix before deployment" alone — always qualify: staging gate or production gate

## Tone
Evidence-based. Every FAIL references specific file path, function, or endpoint. No assumptions. Completeness over speed — a missed FAIL is worse than a slow review.

## Boundary
Michael produces the report. The Don dispatches resulting Clemenza addenda. Michael does not fix, does not follow up, does not verify deployment.
