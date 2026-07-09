# KYC Review Flow Audit Pattern

## The full flow to audit

When auditing a submit→review→approve/reject workflow, trace all 4 paths:

```
Resident submits → pending → admin approves → verified → resident notified ✓
Resident submits → pending → admin rejects  → basic    → resident notified ✓
Admin views queue → shows ONLY pending residents (not approved/rejected/none)
Resubmit: rejected → re-submit → pending again
```

## Common gaps found (ADD-053)

| # | Gap | Where | Impact |
|---|-----|-------|--------|
| 1 | Duplicate `notifySuperAdmins` | Service has private copy; shared helper unused | Maintenance debt |
| 2 | Resident not notified on approval | No in-app notification sent when `identityTier` flips to `verified` | Resident waits days, never knows |
| 3 | Resident not notified on rejection | No in-app notification with rejection reason | Resident rechecks KYC page manually |
| 4 | `requestFullKyc()` is a stub | TODO comment for support ticket creation | `verified → full_kyc` upgrade path blocked |

## Audit checklist

When reviewing a submit→review→approve/reject workflow:

- [ ] Submission: is `kycReviewStatus` set to `pending`? Is `identityTier` unchanged?
- [ ] Queue: does the admin queue query `kycReviewStatus === 'pending'`?
- [ ] Approve: does it flip `identityTier` + `kycReviewStatus` + timestamps + reviewer?
- [ ] Reject: does it set status + note + timestamps + reviewer? Does NOT flip tier?
- [ ] Resident notification on approve: is an in-app notification created?
- [ ] Resident notification on reject: is an in-app notification created WITH the reason?
- [ ] Resubmit after rejection: does `upgradeToVerified()` check for `rejected` status? (should allow)
- [ ] Pending double-submission prevention: does the submit path reject if already pending?
- [ ] Admin notification: is a super_admin notified when a new submission arrives?
- [ ] Full KYC path: does `verified → full_kyc` have a real implementation (not a stub)?
- [ ] Service boundaries: is `notifySuperAdmins` a shared helper or duplicated in each service?

## Related references

- NestJS circular dependency pitfalls: `references/nestjs-circular-dependency-forwardref.md`
- Prisma migration idempotency: `references/prisma-migration-already-exists.md`
