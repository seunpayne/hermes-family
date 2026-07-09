# Phased Delivery Template

## Overview
Use this template when producing a multi-phase improvement plan with checkpoint gates. Adapt section content to the domain — this is the structural skeleton.

---

## Opening Instruction
One paragraph: what this plan covers, who it's for, and the execution rule (gated phases, no phase starts without approval, nothing deploys without explicit signoff).

---

## Phase 0 — Quick Wins (Pre-Execution)
**Why before anything else:** Low-effort, high-impact changes that reduce cost immediately.

### 0A — [Quick win name]
**Action:** Specific config change, file edit, or command.
**Token/Time saving:** Estimated impact.

### 0B — [Quick win name]
**Action:** Specific action.
**Token/Time saving:** Estimated impact.

### 0C — [Quick win name]
**Action:** Specific action.
**Token/Time saving:** Estimated impact.

### ✅ CHECKPOINT 0
"All quick wins applied. Config updated. Ready for infrastructure phases."
**Seun must type APPROVED before Phase 1 begins.**

---

## Phase N — [Name] (🕒 Time Estimate)

**Why:** One paragraph — the problem this phase solves.

### What To Build

**A) [Component/Table/Config]**
Description, SQL DDL or code structure, key decisions.

**B) [Component/Table/Config]**
Description, design decisions, dependencies.

**C) Verification**
How to confirm it works.

### Dependencies
- Previous phases complete
- Specific prerequisites

### Success Criteria
- [ ] Concrete outcome 1
- [ ] Concrete outcome 2

---

## ✅ CHECKPOINT N
"Phase N complete. [Summary]. Tested: [result]."
**Seun must type APPROVED before Phase N+1 begins.**

---

## Summary Table

| Phase | Name | What It Solves | Time Estimate |
|-------|------|----------------|---------------|
| 0 | Quick Wins | Low-effort improvements | ~10 min |
| 1 | Core | Primary problem | ~2-3h |
| 2 | Secondary | Secondary problem | ~2-3h |

---

## Notes
- Dependency chain is fixed — phases cannot be reordered
- Each phase is one approval unit
- Rollback: DDL changes reversible, config changes revertible
