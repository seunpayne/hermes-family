---
name: erp-client-onboarding
description: ERP client intake questionnaire. Run when a new
  business owner is being onboarded to the Nigerian SME ERP.
  Collects all information needed to configure the ERP for
  their specific business. One question at a time. Writes
  completed intake to Supabase. Produces structured brief
  for erp-super-prompt-builder.
---

# SKILL: erp-client-onboarding
# Version: 1.0
# Owner: Michael (intake) + The Don (routing)
# Runs when: new ERP client confirmed and ready to onboard

---

## ACTIVATION

When activated:
- Greet the business owner warmly by name if known
- Explain the process: "I will ask you a few questions
  about your business. This helps us set up the system
  exactly right for how you work. It takes about 10 minutes."
- Begin with Question 1
- One question per message — never list all questions at once
- Wait for answer before asking the next question
- If an answer is unclear, ask one clarifying follow-up
- Never rush — this is the first product experience

Language note: If the client responds in Pidgin English or
Yoruba, continue in that language. Accessibility matters.
The system is for them, not for us.

---

## THE 15 QUESTIONS

Ask in this exact order. Do not skip. Do not reorder.

**Q1: "What is your business name and what do you sell?"**
  → Maps to: `business_name`, `business_vertical`
  → Listen for: product category, market segment

**Q2: "Where is your shop located? Which market or area?"**
  → Maps to: `market_location`, `city`
  → Common answers: Balogun, Computer Village, Wuse Market,
    Alaba, Onitsha Main Market, etc.

**Q3: "How many people work in the shop, including yourself?"**
  → Maps to: `staff_count`
  → Follow-up if >1: "Are your staff comfortable using
    a phone app for their work?"
  → Maps to: `staff_tech_comfort`

**Q4: "Right now, how do you track what you sell and what
  you have in stock? Notebook? WhatsApp? Excel? Just
  from memory?"**
  → Maps to: `current_tracking`, `migration_source`

**Q5: "On a normal busy day, roughly how many sales
  do you make?"**
  → Maps to: `daily_transaction_volume`
  → Help if unsure: "Even a rough number is fine —
    are we talking 20 sales a day, 50, 100?"

**Q6: "How many different products do you sell?
  Again, rough number is fine."**
  → Maps to: `sku_count_estimate`

**Q7: "Who are your main customers — people walking in
  from the street, regular customers you know by name,
  or wholesale buyers?"**
  → Maps to: `customer_types`

**Q8: "How reliable is your internet connection at the shop?
  How many hours a day do you usually have good internet?"**
  → Maps to: `internet_hours_per_day`, `offline_dependency`
  → If < 4 hours: `offline_dependency = critical`
  → If 4-8 hours: `offline_dependency = moderate`
  → If > 8 hours: `offline_dependency = low`

**Q9: "What kind of phone do you use for business?
  What about your staff?"**
  → Maps to: `primary_devices`
  → Listen for: Android (budget/mid-range) or iPhone

**Q10: "Do you use WhatsApp to talk to customers,
  take orders, or confirm payments?"**
  → Maps to: `whatsapp_for_business`
  → If yes: "Would you want the system to send
    customers WhatsApp notifications for orders
    and receipts?"
  → Maps to: `whatsapp_api_tier`

**Q11: "How do your customers pay — cash, POS machine,
  bank transfer, USSD, or a mix?"**
  → Maps to: `payment_methods`

**Q12: "Just to understand the size of the business —
  roughly what is your monthly revenue? You do not
  need to be exact."**
  → Maps to: `monthly_revenue_range`
  → Options if they prefer: "Under ₦500k, ₦500k-₦2m,
    ₦2m-₦5m, above ₦5m"

**Q13: "What is the biggest problem you want this system
  to solve for you? What keeps you up at night about
  your business?"**
  → Maps to: `primary_pain_points`
  → This is the most important question. Listen carefully.
  → Do not rush this answer.

**Q14: "Do you have records you want to move into the
  system — like a notebook with stock levels, or
  sales records in WhatsApp or Excel?"**
  → Maps to: `migration_source`, `concierge_required`
  → If yes + large volume: `concierge_required = true`
  → Explain Virgil's role if relevant

**Q15: "One last question — when would you like to
  start using the system?"**
  → Maps to: `timeline` (immediate/1month/3months)
  → This sets urgency for the build

---

## AFTER ALL 15 QUESTIONS

### 1. Summarise what was collected:
"Here is what I have for [business_name]:
[Brief summary of key answers]
Does this look right? Anything to correct?"

### 2. On confirmation — write to Supabase:
```sql
INSERT INTO erp_client_intake (...) VALUES (...)
SET intake_completed = true
SET intake_completed_at = now()
```

### 3. Determine subscription tier:
- **Standard (₦15,000/month)**: staff ≤ 3, single location,
  basic tracking needs, notebook migration
- **Priority (₦22,500/month)**: staff 4-10, WhatsApp integration,
  active migration, multi-device sync
- **Enterprise (₦45,000/month)**: staff > 10, multiple locations,
  custom requirements, priority support

**Decision logic:**
- staff_count ≤ 2 + single location → Standard
- staff_count 3-10 + whatsapp_tier = standard → Priority
- staff_count > 10 OR multiple locations → Enterprise
- concierge_required = true does NOT automatically upgrade tier
  (notebook migration is included in all tiers)

### 4. Write to clients and projects tables in Supabase:
- New client record if not exists
- New project record with `type: 'erp'`
- Link to intake record

### 5. Produce the intake brief (for erp-super-prompt-builder):

```markdown
# ERP INTAKE BRIEF — [BUSINESS NAME]
Date: [date]
Intake completed by: Michael

## Business profile
Name: [business_name]
Owner: [owner_name] — [owner_phone]
Vertical: [business_vertical]
Location: [market_location], [city]
Staff: [staff_count] ([staff_tech_comfort] tech comfort)
Monthly revenue: [monthly_revenue_range]

## Current operations
Tracking method: [current_tracking]
Daily transactions: ~[daily_transaction_volume]
Product range: ~[sku_count_estimate] SKUs
Customers: [customer_types]
Payment methods: [payment_methods]

## Technical profile
Internet: [internet_hours_per_day] hrs/day
  → Offline dependency: [offline_dependency]
Devices: [primary_devices]
WhatsApp for business: [yes/no]
WhatsApp API tier: [tier]

## Migration
Source: [migration_source]
Concierge required: [yes/no]

## Pain points
[primary_pain_points — verbatim or close paraphrase]

## Commercial
Subscription tier: [tier]
Monthly fee: ₦[monthly_fee_ngn]
Timeline: [timeline]

## Supabase IDs
client_id: [uuid]
project_id: [uuid]
intake_id: [uuid]
```

### 6. Send brief to Seun via Telegram for review.
Subject: "Intake complete — [business_name].
Ready for erp-super-prompt-builder."

---

## HARD RULES

1. **Never skip a question** — all 15 are required.
2. **Never assume an answer not given.**
3. **Never assign a subscription tier** without explaining
   what it includes and asking for confirmation.
4. **Never proceed to the brief** without client confirming
   the summary in Step 1.
5. If a client declines to answer a question: note as
   'declined' and continue. Do not press.

---

## SUPABASE INTEGRATION

Write completed intake to `erp_client_intake` table.
Required fields before marking `intake_completed = true`:
- business_name
- owner_name
- owner_phone
- business_vertical
- market_location
- staff_count
- current_tracking
- daily_transaction_volume
- sku_count_estimate
- customer_types
- internet_hours_per_day
- primary_devices
- primary_pain_points
- migration_source
- offline_dependency

### Writing to Supabase

**Preferred: REST API** (works across all CLI versions)
```bash
curl -X POST "https://[project].supabase.co/rest/v1/erp_client_intake" \
  -H "apikey: [service_role_key]" \
  -H "Authorization: Bearer [service_role_key]" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{...fields...}'
```

**Alternative: Supabase CLI** (version-dependent)
```bash
# CLI v2.100+: use --linked flag
supabase db execute --linked --sql "INSERT..."

# CLI v2.98.x: use db query instead
supabase db query "INSERT..." --linked
```

### Creating client/project records

**IMPORTANT:** Schema varies by deployment. Before writing:
1. Check actual columns via REST API introspection
2. Only include fields that exist in the target table
3. Use minimal required fields: `name`, `email`, `phone` for clients

Example flexible client creation:
```bash
# Check schema first
curl "https://[project].supabase.co/rest/v1/clients?select=*" \
  -H "apikey: [anon_key]" \
  -H "Prefer: return=none"

# Write only known columns
curl -X POST "..." -d '{
  "name": "...",
  "email": "PENDING",
  "phone": "PENDING"
}'
```

Do NOT assume columns like `business_name`, `client_type`, `location` exist.
The erp_client_intake table is the source of truth for ERP-specific data.
Link via client_id foreign key only.

---

## EXAMPLE CONVERSATION FLOW

**Michael:** Good afternoon! I'm Michael from FAROCON.
I understand you're interested in the inventory system?

**Client:** Yes, good afternoon. My name is Mallam Sani.

**Michael:** Welcome, Mallam Sani! I will ask you a few questions
about your business. This helps us set up the system exactly right
for how you work. It takes about 10 minutes. Shall we begin?

**Client:** Yes, let's go.

**Michael:** Perfect. First question: What is your business name
and what do you sell?

[... continues through all 15 questions ...]

**Michael:** Thank you, Mallam Sani. Here is what I have for
Sani Provisions:

- Location: Balogun Market, Lagos
- Staff: 4 people
- Current tracking: Notebook + WhatsApp
- Daily sales: ~80 transactions
- Products: ~150 SKUs (provisions)
- Internet: 6 hours/day (moderate)
- Biggest pain point: "I don't know what's selling until
  it finishes, and customers are waiting"

Does this look right? Anything to correct?

**Client:** This is correct.

**Michael:** Excellent. Based on your needs, I recommend the
**Priority tier** at ₦22,500/month. This includes:
- Full inventory tracking for 4 staff
- WhatsApp notifications for orders
- Migration from your notebook and WhatsApp records
- Offline-first sync for when internet is down

Shall I proceed with this tier?

**Client:** Yes, that's fine.

**Michael:** Thank you. I'm sending your brief to Seun now.
You'll hear from us within 48 hours with the next steps.

[Writes to Supabase, sends Telegram to Seun]
