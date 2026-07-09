# Super Prompt Verification Checklist

Use this checklist to verify a super prompt is complete before presenting to Seun for approval.

## Section-by-Section Verification

### Section 1: Client Identity
- [ ] Business name populated
- [ ] Owner name populated
- [ ] Location populated
- [ ] Vertical/category populated
- [ ] Staff count and tech comfort populated
- [ ] Customer types populated
- [ ] Revenue range populated (if known)

### Section 2: Design Language (Apollonia)
- [ ] Brand personality defined
- [ ] Colour palette: 4 colours with hex codes
- [ ] Typography: system font specified
- [ ] Dark mode: YES/NO with rationale
- [ ] Cultural element: described
- [ ] Tone IS: 3 adjectives
- [ ] Tone NOT: 3 adjectives

### Section 3: Functionality Overview
- [ ] P0 features: 3 items (from primary pain points)
- [ ] P1 features: 3 items (from intake signals)
- [ ] P2 features: 2 items (derived growth)

### Section 4: Copy and Content
- [ ] App name defined
- [ ] Welcome message: personalized
- [ ] Key screen labels: localized (market language)
- [ ] Error messages: plain English guidance
- [ ] Success states: defined

### Section 5: Infrastructure
- [ ] Stack: confirmed (React Native + WatermelonDB + Supabase)
- [ ] Offline-first: YES/NO with dependency level
- [ ] Sync config: batch size, retry logic, conflict resolution
- [ ] WhatsApp tier: none/standard/priority
- [ ] Deployment: EAS + Google Play specified

### Section 6: Constraints
- [ ] Devices: android-budget/android-mid/iphone/mixed
- [ ] Internet: hours per day
- [ ] Staff tech comfort: low/medium/high
- [ ] Migration: source identified, concierge YES/NO

### Section 7: Open Questions
- [ ] All intentional gaps listed
- [ ] Phone number marked PENDING if not collected
- [ ] Email marked PENDING if optional
- [ ] Other gaps documented

### Section 8: Decisions Already Made
- [ ] Stack decision documented
- [ ] Sync prototype results cited (if applicable)
- [ ] Subscription tier confirmed
- [ ] WhatsApp tier confirmed
- [ ] Concierge confirmed
- [ ] Timeline confirmed

### Section 9: Assumptions
- [ ] 5+ operational assumptions listed
- [ ] Nigeria ops (WAT, NGN) assumed if applicable
- [ ] Device sharing possibility noted
- [ ] Power/internet interruptions expected

### Section 10: Technical Specifications
- [ ] proto_ tables defined (4 minimum)
- [ ] WatermelonDB mapping noted
- [ ] RLS policies described
- [ ] Testing requirements: 70%+, Detox, sync scenarios

### Section 11: Task Breakdown
- [ ] T-001 to T-010: 10 tasks listed
- [ ] Each task has CODE/RUN/VERIFY/REPORT format
- [ ] CODE: actual code/SQL/commands, not descriptions
- [ ] RUN: exact terminal command
- [ ] VERIFY: independent confirmation
- [ ] REPORT: PASS format + FAIL format

### Section 12: Approval Gates
- [ ] 8 gates listed
- [ ] Gate 1 marked as current (Seun review)
- [ ] Gates 2-8 documented

## Playbook Compliance

### Universal Principles (11 principles)
- [ ] P1: Logic testable without full stack → Unit tests first
- [ ] P2: Supabase DDL via CLI/migration, not REST
- [ ] P6: No literal credentials in code → .env pattern
- [ ] P7: VERIFY confirms success independently
- [ ] P8: REPORT includes FAIL format
- [ ] P9: Native modules abstracted behind interfaces
- [ ] P10: Prototype tables use proto_ prefix

### ERP Pitfalls (6 pitfalls)
- [ ] Pitfall 1: Supabase REST cannot run DDL → Use CLI
- [ ] Pitfall 2: Decorators need TypeScript config
- [ ] Pitfall 3: baseline_stock captured at write time
- [ ] Pitfall 4: ADJUSTMENT never auto-merged
- [ ] Pitfall 5: WatermelonDB synchronize() needs custom chunking
- [ ] Pitfall 8: DO NOT USE EXPO TO PROTOTYPE SYNC

## Routing Instructions
- [ ] 4-step flow documented (Michael → Seun → Don → Clemenza)
- [ ] "Do not start until Seun approves" warning present

## Commercial Summary
- [ ] Subscription tier matches intake
- [ ] Concierge noted if required
- [ ] Timeline noted

## Final Checks
- [ ] All sections populated or marked intentional gap
- [ ] No contradictory information across sections
- [ ] Pain points quoted verbatim (not sanitized)
- [ ] Device constraints drive optimization decisions
- [ ] Offline dependency drives sync configuration

---

## Usage

Run this checklist before presenting super prompt to Seun.

**If all items checked:** "Super prompt verified complete. Awaiting approval."

**If items unchecked:** List missing items, complete them, then re-verify.

**Critical gaps (block approval):**
- Section 2 without Apollonia tokens
- Section 11 tasks without CODE/RUN/VERIFY/REPORT
- Playbook principles violated
- Pain points sanitized or missing
