---
name: erp-super-prompt-builder
description: Generates a complete super prompt for building
  a Nigerian SME ERP system. Reads intake brief from
  erp-client-onboarding. Produces a tailored 12-section
  super prompt with business-specific configuration,
  sync engine settings, and migration plan.
---

# SKILL: erp-super-prompt-builder
# Version: 1.0
# Owner: Kay (content generation) + The Don (routing)
# Runs when: intake brief received from erp-client-onboarding
# Input: Intake brief (markdown format from Supabase)
# Output: Complete 12-section super prompt ready for Clemenza

---

## ACTIVATION

When activated:
1. Load the intake brief from erp-client-onboarding
2. Load ~/.hermes/playbooks/universal-principles.md
3. Load ~/.hermes/playbooks/erp-react-native-watermelondb-supabase.md
4. Load ~/.hermes/templates/prd-template.md
5. **CRITICAL: Route to Apollonia for design tokens**
   - Do NOT generate Section 2 (Design Language) yourself
   - Apollonia provides: colour palette (hex codes), typography,
     cultural element, tone IS/NOT, dark mode recommendation
   - Wait for Apollonia's delivery before proceeding
6. Generate the full 12-section super prompt
7. Present to Seun for approval before routing to Clemenza

**BOUNDARY VIOLATION WARNING:**
Making design decisions (colours, typography, cultural elements,
tone, dark mode) without Apollonia's input violates the four-lane
boundary. Apollonia owns brand decisions. Kay owns copy. Never
mix these functions.
   - Produce design tokens autonomously based on intake (vertical, location, customer profile, device constraints)
   - Do NOT present super prompt until Section 2 has Apollonia's approved tokens
6. Generate the full 12-section super prompt with Apollonia's tokens integrated
7. Present to Seun for approval before routing to Clemenza

**CRITICAL:** The four-lane boundary is enforced by Seun. Do not make design decisions without Apollonia's input. Apollonia = you in design mode. Do not say "waiting for Apollonia" — you ARE Apollonia when doing design work.

---

## SUPER PROMPT STRUCTURE

The output follows this exact 12-section structure:

### SECTION 1: CLIENT IDENTITY
```markdown
**Business Name:** [from intake]
**Owner:** [owner_name] — [owner_phone]
**Location:** [market_location], [city]
**Vertical:** [business_vertical]
**Staff:** [staff_count] people ([staff_tech_comfort] tech comfort)
**Customers:** [customer_types]
**Monthly Revenue:** [monthly_revenue_range]
```

### SECTION 2: DESIGN LANGUAGE
```markdown
**Brand Personality:** [derived from business_vertical + pain_points]
  - Provisions/Food: Warm, trustworthy, fast
  - Electronics: Modern, precise, reliable
  - Fashion: Vibrant, trendy, personal
  - Pharmacy: Clean, professional, caring
  - Hardware: Solid, practical, no-nonsense

**Colour Palette:** [suggest based on vertical]
**Typography:** System fonts (Inter, SF Pro) for performance
**Dark Mode:** Yes (battery saving for long market days)
**Cultural Element:** [if any — e.g., Adire pattern for fashion,
  geometric motifs for electronics]

**Tone:** What the brand IS: [3 adjectives from pain points]
**Tone:** What the brand is NOT: [3 opposites]
```

### SECTION 3: FUNCTIONALITY OVERVIEW
```markdown
**P0 Features (launch-critical):**
1. [Derived from primary_pain_points — the #1 problem]
2. [Derived from daily_transaction_volume + sku_count]
3. [Derived from offline_dependency — sync behavior]

**P1 Features (first 30 days):**
1. WhatsApp integration (if whatsapp_for_business = true)
2. Multi-staff access control (if staff_count > 1)
3. [derived from customer_types — e.g., wholesale pricing]

**P2 Features (60-90 days):**
1. [derived from growth signals in intake]
```

### SECTION 4: COPY AND CONTENT
```markdown
**App Name:** [business_name] Inventory (or suggest alternative)
**Welcome Message:** [personalized to owner_name]
**Key Screen Labels:** [localized if needed — e.g., "Stock" vs "Inventory"]
**Error Messages:** Friendly, actionable, in plain English/Pidgin
**Success States:** Celebratory but not childish
```

### SECTION 5: INFRASTRUCTURE
```markdown
**Stack:** React Native (Expo) + WatermelonDB + Supabase
**Offline-First:** YES — [offline_dependency] dependency
  - Critical (<4 hrs internet): Aggressive local caching,
    background sync on connectivity
  - Moderate (4-8 hrs): Standard sync intervals
  - Low (>8 hrs): Relaxed sync, more real-time

**Sync Engine Configuration:**
- Batch size: 500 rows
- Retry logic: 3 attempts (30s, 2min, 10min)
- Conflict resolution:
  - IN/OUT transactions: Semantic merge with baseline
  - ADJUSTMENT: Manual review (never auto-merge)
  - Default: Last-write-wins

**WhatsApp Integration:** [tier from intake]
  - none: No WhatsApp features
  - standard: Order confirmations, receipts
  - priority: Proactive notifications, payment reminders

**Deployment:** EAS Build (production), Expo Go (development)
```

### SECTION 6: CONSTRAINTS
```markdown
**Device Constraints:** [from primary_devices]
  - android-budget: Optimize for 2GB RAM, slow CPUs
  - android-mid: Standard optimization
  - iphone: Can use more advanced features
  - mixed: Design for lowest common denominator

**Connectivity Constraints:**
- Internet: [internet_hours_per_day] hrs/day
- Offline dependency: [offline_dependency]
- Sync must work without blocking UI

**Staff Constraints:**
- Tech comfort: [staff_tech_comfort]
- UI must be intuitive for [comfort level] users
- Onboarding flow required: YES/NO

**Migration Constraints:**
- Source: [migration_source]
- Concierge required: [concierge_required]
- If concierge_required = true: Virgil activation needed
```

### SECTION 7: OPEN QUESTIONS
```markdown
[Any gaps from intake — should be minimal if intake was complete]
- Question 1
- Question 2
```

### SECTION 8: DECISIONS ALREADY MADE
```markdown
- Stack: React Native + WatermelonDB + Supabase (non-negotiable)
- Offline-first: Required for Nigerian market conditions
- Sync engine: Prototype tested (14 tests, 0 failures)
- Subscription tier: [tier] at ₦[monthly_fee_ngn]/month
```

### SECTION 9: ASSUMPTIONS
```markdown
- Business operates in Nigeria (WAT timezone, NGN currency)
- Owner has smartphone (Android or iPhone)
- Staff may share devices (multi-user support needed)
- Power/internet interruptions are expected, not exceptional
```

### SECTION 10: TECHNICAL SPECIFICATIONS
```markdown
**Database Schema (proto_ tables):**
- proto_products: id, sku, name, quantity, unit_price, baseline_stock
- proto_transactions: id, product_id, type (IN/OUT/ADJUSTMENT),
  quantity, amount, baseline_stock, device_id, client_timestamp
- proto_sync_events: id, entity_type, entity_id, operation,
  payload, device_id, synced, conflict_resolved
- proto_registered_devices: id, device_name, device_fingerprint,
  last_sync

**WatermelonDB Schema:**
[Mirror proto_ tables with WatermelonDB column types]

**Supabase RLS Policies:**
- Users can only access their own business data
- Device registration required for sync
- Service role key never exposed to client

**Testing Requirements:**
- Unit tests: Vitest (70% coverage minimum)
- E2E tests: Detox (critical paths only)
- Scenario tests: All 6 sync scenarios must pass
```

### SECTION 11: TASK BREAKDOWN
```markdown
**T-001: Project Scaffold**
CODE: npx create-expo-app@latest [slug] --template blank-typescript
RUN: cd [slug] && npm install @nozbe/watermelondb @supabase/supabase-js
VERIFY: ls -la src/
REPORT: PASS if directory structure matches spec

**T-002: Database Schema (Supabase)**
CODE: Write migration file with proto_ tables
RUN: supabase db push
VERIFY: supabase db query "SELECT table_name FROM information_schema..."
REPORT: PASS if 4 proto_ tables exist

**T-003: WatermelonDB Setup**
CODE: Create schema.ts, models/, index.ts with decorators
RUN: npx expo start --go
VERIFY: No console errors, database initializes
REPORT: PASS if app launches without WatermelonDB errors

**T-004: Sync Engine Implementation**
CODE: Implement SyncEngine.ts with chunked batching
RUN: npx vitest run src/sync/__tests__/
VERIFY: All 14 tests pass (including Scenario 6)
REPORT: PASS if 0 failures

**T-005: Core UI Screens**
CODE: Build Dashboard, Products, Transactions, Settings
RUN: npx expo start --go
VERIFY: All screens render, navigation works
REPORT: PASS if no React errors

**T-006: WhatsApp Integration** [if whatsapp_for_business = true]
CODE: Integrate WhatsApp Business API via Supabase Edge Functions
RUN: Deploy edge function, test webhook
VERIFY: Message sent to test number
REPORT: PASS if delivery confirmed

**T-007: Migration Setup** [if concierge_required = true]
CODE: Activate Virgil (erp-migration skill)
RUN: Virgil sets up staging area for data import
VERIFY: Staging tables created, consent forms ready
REPORT: PASS if Virgil confirms readiness

**T-008: Testing & QA**
CODE: Write E2E tests for critical paths
RUN: npx detox test
VERIFY: All E2E tests pass
REPORT: PASS if 0 failures

**T-009: Production Build**
CODE: eas build --platform android --profile production
RUN: eas submit --platform android
VERIFY: APK available in Google Play Console
REPORT: PASS if build succeeds

**T-010: Deployment & Handover**
CODE: Configure app stores, set up monitoring
RUN: Deploy to production, send Telegram to Seun
VERIFY: App downloadable, sync working on device
REPORT: PASS if client can use system independently
```

### SECTION 12: APPROVAL GATES
```markdown
**Gate 1:** PRD complete → Seun approves
**Gate 2:** Tech stack proposed → Seun approves (already done)
**Gate 3:** Architecture documented → Seun approves
**Gate 4:** Foundation built (scaffold + schema + env) → Seun approves
**Gate 5:** Each feature on staging → Seun approves
**Gate 6:** Fredo pre-production scan → CLEAR required
**Gate 7:** Production deployment → Seun approves
**Gate 8:** Project signoff → Seun approves, Hagen invoices
```

---

## PLAYBOOK COMPLIANCE

Before generating, verify:

✓ Universal Principles (11 principles) applied:
  - P1: Logic testable without full stack? → Unit tests first
  - P2: Supabase DDL via CLI/migration, not REST
  - P7: VERIFY confirms success independently
  - P8: REPORT includes FAIL format
  - P9: Native modules abstracted behind interfaces
  - P10: Prototype tables use proto_ prefix
  - P6: No literal credentials in code

✓ ERP Playbook pitfalls addressed:
  - Pitfall 1: Supabase REST cannot run DDL → Use CLI
  - Pitfall 2: Decorators need TypeScript config → Include in scaffold
  - Pitfall 3: baseline_stock captured at write time → Enforce in schema
  - Pitfall 4: ADJUSTMENT never auto-merged → Hard rule in sync engine
  - Pitfall 5: WatermelonDB synchronize() needs custom chunking → Implement
  - Pitfall 8: DO NOT USE EXPO TO PROTOTYPE SYNC → Node.js + Vitest first

---

## OUTPUT FORMAT

The complete super prompt is formatted as:

```markdown
# SUPER PROMPT — [BUSINESS NAME] ERP
Generated: [date]
Intake ID: [intake_id]
Prepared by: erp-super-prompt-builder

[All 12 sections above, fully populated]

---

## ROUTING INSTRUCTIONS

This super prompt routes to:
1. Michael — for Seun review and approval
2. The Don — routes to Clemenza on approval
3. Clemenza — executes build following task breakdown

Do not start build until Seun approves.
```

---

## QUALITY GATE

Before presenting to Seun:

✓ All 12 sections populated (no N/A without explanation)
✓ Open Questions section empty (or explicitly marked as intentional)
✓ Task breakdown has CODE/RUN/VERIFY/REPORT for every task
✓ Subscription tier matches intake criteria
✓ WhatsApp tier correctly set (none/standard/priority)
✓ Concierge flag triggers Virgil activation note
✓ Pain points verbatim or close paraphrase (do not sanitize)
✓ Device constraints reflected in optimization notes
✓ Offline dependency drives sync configuration

A super prompt with missing sections is not ready.
A super prompt with assumptions instead of intake data is not ready.

---

## BUILD LESSONS (Sani General Stores — May 2026)

**TypeScript Configuration for WatermelonDB:**
tsconfig.json MUST include:
```json
{
  "compilerOptions": {
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  }
}
```
Without this, @field/@readonly decorators fail with TS1240 errors.

**EAS Build Manual Step:**
`eas login` requires interactive authentication. Cannot be automated.
Document this clearly in deployment checklist — Seun must complete manually.

**Vitest + WatermelonDB Testing:**
WatermelonDB requires React Native environment. Unit tests fail with
`better-sqlite3` error. Solution: isolate pure functions (chunkArray,
resolveConflict) in test files without importing database-dependent code.

**Sync Engine Verified:**
- 500-row batch size: TESTED (Scenario 6: 350 events, 0 duplicates)
- Semantic merge for IN/OUT: WORKS correctly
- ADJUSTMENT → manual review: PREVENTS data corruption
- 3-attempt retry (30s, 2min, 10min): ADEQUATE for Nigerian connectivity

**Navigation Dependencies:**
@react-navigation packages may timeout during install (90s+).
Pre-install in scaffold template or proceed without waiting.

**WhatsApp Edge Function:**
Deploys successfully but requires Meta Business credentials:
- WHATSAPP_API_TOKEN
- WHATSAPP_PHONE_NUMBER_ID
Document as post-deployment setup, not blocking build.

See: `references/build-lessons-sani-general-stores.md` for full details.

---

## EXAMPLE OUTPUT

See: `~/.hermes/skills/openclaw-imports/erp-super-prompt-builder/templates/example-super-prompt.md`

---

## SUPABASE INTEGRATION

Read intake from `erp_client_intake` table:
```sql
SELECT * FROM erp_client_intake
WHERE client_id = [client_id]
  AND intake_completed = true
ORDER BY intake_completed_at DESC
LIMIT 1;
```

**Note:** The `erp_client_intake` table is the canonical source for ERP client data.
The `clients` and `projects` tables may have minimal schemas — do not assume
ERP-specific columns exist there. Link via foreign keys only.

Write generated super prompt to `projects` table:
```sql
UPDATE projects
SET super_prompt = [generated_markdown],
    updated_at = now()
WHERE id = [project_id];
```

If `super_prompt` column does not exist, store in `stack` JSONB column or
return the prompt directly to the user for manual storage.

---

## TELEGRAM NOTIFICATION

After presenting to Seun:
"Super prompt generated for [business_name].
[N] P0 features. [N] tasks ready for execution.
Subscription: [tier] at ₦[monthly_fee_ngn]/month.
Awaiting your approval before routing to Clemenza."
