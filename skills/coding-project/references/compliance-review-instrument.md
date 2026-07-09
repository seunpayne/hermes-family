# Compliance Review Instrument — Michael's PRD-to-Codebase Review

## Purpose
Structured checklist for verifying a codebase implementation against PRD v2.1 specification. Run after all features are built and before production deployment. Produces Clemenza addenda for each FAIL/DIVERGENCE found.

## When to Use
- After Phase 5 (Integration & QA) and before Phase 6 (Production Deployment)
- When comparing two implementations (e.g. family build vs Claude Code build)
- When Seun requests a compliance check before approving production

## Methodology

### Setup
1. Identify primary codebase (the branch to deploy)
2. If comparing two implementations: clone both and run reviews independently
3. Load the PRD document (extract paragraphs AND tables via python-docx)
4. Open the compliance report template

### Review Sections (in order)

**1. Data Model — 19 PRD entities**
For each entity in the PRD, check the Prisma schema:
- Entity name matches
- All fields present with correct types
- All fields present with correct types
- All relations (foreign keys, indexes) present
- Enums match PRD enum values exactly
- Count total models: `grep "^model " prisma/schema.prisma | wc -l`

Mark as PASS if all match. DIVERGENCE if extra fields/enums exist (document what). FAIL if missing.

**2. Functional Requirements — 28 FRs**
For each FR, verify by:
- Checking the API endpoint exists (method + path)
- Checking auth requirements are met
- Checking the business logic matches PRD spec
- Checking error handling for edge cases

Key FRs requiring special attention:
- FR-06 (WhatsApp): Stub vs real integration. Note if Siteti API key is missing.
- FR-12 (Identity tiers): Check enum values match PRD exactly.
- FR-13 (Offline cache): localStorage vs Service Worker.
- FR-20 (Offboarding): Check if reminders are stubs or implemented.
- FR-22 (DPA): Check if signing endpoint exists or only external document.
- FR-27 (Platform fee): Verify 0.5% calculation.

**3. API Compliance — 15 Core Endpoints**
For each endpoint, verify:
- Method matches (POST/GET/PATCH)
- Path matches exactly
- Auth requirement matches (Public / Role-scoped)
- Route is registered (check by starting app briefly or examining controller decorators)

**4. Security & Compliance**
- MFA enforced for admin roles (or stub noted)
- QR payloads encrypted/signed
- Audit logging on all mutating calls
- Consent captured before data collection
- PII fields noted for encryption
- RBAC guards on all protected routes
- Cross-tenant isolation (app-layer middleware or RLS)
- HTTPS enforced in deployment config
- Webhook signature validation for Paystack

**5. Non-Functional Requirements**
- Lighthouse targets (Performance >= 85, Accessibility >= 90)
- Offline QR verification capability
- BullMQ notification reliability
- Multi-tenant isolation mechanism
- SOS within 2 taps from any resident screen

**6. UI/UX**
- Colour tokens match PRD spec
- Plus Jakarta Sans loaded
- No Tailwind gray-100 as primary surface
- No drop shadows (flat + 1px borders)
- Border radius: cards 16px, buttons 10px, inputs 8px
- SOS button persistent and ≤2 taps
- Tap targets: 44px resident, 56px guard
- Colour never the only differentiator (icon + colour paired)
- Empty states for all list views
- Offline indicator on guard surface
- Consent capture before data collection forms

**7. Integration Compliance**
For each integration, check if it's a live implementation or a stub:
- Siteti WhatsApp BSP
- Termii SMS
- Paystack (including webhook)
- AWS S3 document storage
- BullMQ + Redis
- Sentry error tracking
- BetterStack uptime monitoring
- Telegram ops channel
- Meta WhatsApp test API

### Delta Report (Two-Implementation Comparison)

When comparing two implementations, produce a side-by-side delta table:

| Area | Implementation A | Implementation B | Recommendation |
|------|-----------------|-----------------|---------------|
| Data entities | Count + notes | Count + notes | Primary + cherry-pick |
| QR encryption | Approach | Approach | |
| RBAC | Implementation | Implementation | |
| WhatsApp | State machine depth | State machine depth | |
| SOS escalation | Approach | Approach | |
| Offline cache | Method | Method | |
| Paystack | Integration depth | Integration depth | |
| Enumeration validation | Depth | Depth | |
| Notification engine | Queue type | Queue type | |
| Audit logging | Approach | Approach | |
| Offboarding | Implementation | Implementation | |

### Addendum Generation

For each FAIL/DIVERGENCE, produce a Clemenza addendum:

```
## [CLIENT] — ADDENDUM [NUMBER]
### [TITLE]
**Priority:** P0 / P1 / P1 staging·P0 prod
**Applies to:** [exact file path]

**CONTEXT:** [why — one sentence]
**CHANGE:** [exactly what — specific, with code examples]
**DO NOT CHANGE:** [everything adjacent — prevent scope creep]
**AFTER IMPLEMENTING:** [verification steps — what to run/test]
```

Priority classification:
- **P0 (production gate):** Blocks first real estate data. NDPR exposure (DPA endpoint, PII encryption).
- **P1 staging / P0 prod:** Safe for staging, must fix before real data enters system. Same urgency as P0 but with staging flexibility.
- **P1:** Dev quality. Should fix before steady state.

The test for production gate: "can an estate advance to a phase requiring real resident data without this fix?" If yes, it's a production gate.

### Sign-Off Gates

| Gate | Description | Owner |
|------|-------------|-------|
| Primary implementation review complete | All sections checked, addenda generated | Michael |
| Secondary implementation review complete | All sections checked | Michael |
| Delta report complete | Side-by-side comparison delivered | Michael |
| All FAIL items resolved or risk-accepted | Seun sign-off | Seun |
| All P0 addenda closed by Clemenza | Fixes implemented and verified | Clemenza |
| Seun deployment approval | Final go/no-go | Seun |
