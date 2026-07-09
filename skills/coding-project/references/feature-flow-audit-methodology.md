# Feature Flow Audit Methodology

Pattern for auditing a feature end-to-end: trace every state transition,
check every guard, find silent failures. Used for KYC review and SOS systems.

## Step 1: Define the state machine

Draw every state the entity can be in, and every transition between states.
```
basic ──submit──→ pending ──approve──→ verified
                     │
                     └──reject──→ rejected ──resubmit──→ pending
```

## Step 2: Check every guard

For each transition, read the actual code (not the docstring). Verify:
- Can the transition be triggered from this state? (guard clause)
- Can it be triggered from a state it SHOULDN'T? (missing guard)
- What happens on edge cases (already-approved, never-submitted, stale)?

## Step 3: Trace the notification path

For every state change, check if the right people get notified:
- Resident: notified on approve? on reject? silently waiting?
- Admin: notified on new submission? does notification carry the right data?
- Are the notification channels actually delivering? (see notification-channel-map-mismatch.md)

## Step 4: Check for dead code

Look for:
- Fetched data never used (fallback responders fetched but not dispatched)
- Channels mapped but guaranteed to fail (IN_APP sent to phone number, EMAIL sent to phone)
- Methods that exist but have no caller (checkEscalation() with no cron job)

## Step 5: Check the frontend matches

For every backend state, verify the frontend shows the right UI:
- pending → "Under review" banner
- approved → verified badge, upgrade form hidden
- rejected → reason displayed, resubmit form visible

## Step 6: Present findings as a numbered table

| # | What | Severity | Status |
|---|------|----------|--------|

P0 = production broken (notifications never delivered, feature non-functional)
P1 = works but degraded (missing tracking, no escalation)
Minor = edge case or future improvement
