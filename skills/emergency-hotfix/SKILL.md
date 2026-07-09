---
name: emergency-hotfix
description: Emergency production hotfix protocol.
  Load ONLY when a production site is broken and
  Seun is unreachable. Revert only. No new code.
---

# SKILL: emergency-hotfix
# Version: 1.0
# Extracted from SOUL.md v1.x — May 2026
# Use ONLY when production is broken AND Seun unreachable

---

## WHO CAN ACT

Clemenza only.
No other family member may initiate a hotfix.

---

## PERMITTED ACTION

Revert the last deployment only:
  vercel rollback --target production

That is the only permitted action.

NOT permitted under this protocol:
  New feature code
  Bug fixes
  Dependency updates
  Config changes
  Database changes (schema or data)
  Environment variable changes
  Any change that is not a clean revert

If the revert does not fix the issue:
  Do not attempt further changes.
  Alert Seun and wait.
  The site remains broken until Seun is available.

---

## REQUIRED BEFORE REVERT

Fredo must run a security scan on the
version being reverted TO (not the broken version).

Fredo confirms: CLEAR
Then and only then: Clemenza executes the revert.

If Fredo finds issues in the revert target:
  Alert Seun immediately.
  Do not revert to a version with security issues.
  Wait for Seun.

---

## NOTIFICATION — send immediately on activation

Send to Seun via Telegram:
"🚨 HOTFIX ACTIVATED
Site: [site name and URL]
Issue: [one sentence description]
Action: reverting to previous deployment
Fredo scan: [CLEAR / in progress]
Time: [timestamp]

Awaiting your review."

Send this message BEFORE executing the revert,
not after. Seun must know this is happening.

---

## POST-HOC REVIEW

Required within 24 hours of any hotfix activation:

Clemenza documents:
  - What broke and when
  - What the revert restored
  - Root cause (if known)
  - How to prevent recurrence

Log to Supabase decisions table:
  incident_type: 'hotfix'
  description: [full incident report]
  resolved: true/false
  resolved_at: [timestamp]

Seun reviews the incident report.
The Don schedules a proper fix as a standard task
following the full coding project protocol.

---

## WHEN NOT TO USE THIS SKILL

Do NOT activate emergency hotfix for:
  Staging environment issues (not production)
  Performance degradation (not broken)
  Feature not working as expected (not broken)
  Client feedback on design (not an emergency)
  Database issues that a revert cannot fix

Only activate when:
  Production site is completely inaccessible
  OR a critical data-corrupting bug is live
  AND Seun cannot be reached within 30 minutes
