# Notification Identity Traps

## Pattern: Wrong field used for recipientClerkId

When creating in-app notifications, the `recipientClerkId` field expects a
Clerk user ID (e.g. `user_3FzGpdu0WqX7XwYX35n16hoXUl5`). Sub-agents
frequently populate it with:

| Wrong value | Source field | Symptom |
|------------|-------------|---------|
| `resident.phone` | Phone number string | Notification created silently but never shown to the resident |
| `resident.email` | Email address | Same — never matches any Clerk ID |
| `resident.id` | Prisma cuid | Notification stored but resident's bell never shows it |

### Root cause

The sub-agent sees a `recipient` field in the notification job and assumes
"recipient = phone number" (common in Twilio/SMS patterns) without checking
what the in-app notification query actually matches against.

### Fix

Always resolve the resident row first, then use `resident.linkedClerkUserId`:
```typescript
const resident = await this.prisma.resident.findFirst({
  where: { id: residentId },
  select: { linkedClerkUserId: true, fullName: true },
});

await this.notificationService.createInAppNotification({
  recipientClerkId: resident.linkedClerkUserId, // NOT resident.phone
  type: 'broadcast',
  body: message,
  communityId,
});
```

### Detection

After sending a broadcast or any in-app notification, verify:
1. Check Railway logs — does the notification job actually process?
2. Query the resident's notifications endpoint — does it return the new entry?
3. If job processes but notification never appears in feed, check what value
   was used for `recipientClerkId`

### Audit trigger

When adding ANY new notification call site, grep to confirm the field name:
```bash
grep -n "recipientClerkId" src/modules/**/*.ts
```
If the right-hand side contains `.phone`, `.email`, or a raw string that
doesn't start with `user_`, it's wrong.
