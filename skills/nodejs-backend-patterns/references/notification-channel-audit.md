# Notification Channel Audit — Clerk-Based vs Phone-Based Recipients

## The Pattern

Notification channels must match recipient types. After ADD-034 dropped WhatsApp/SMS, the only live channel is `IN_APP`. IN_APP requires a **Clerk user ID** as the recipient — sending a phone number or email address will silently fail.

## Audit Methodology

When reviewing a notification flow, ask these questions in order:

1. **Who are the recipients?** (Clerk users with accounts, or phone-number-only contacts?)
2. **What channels are mapped?** Check `NOTIFICATION_CHANNEL_MAP` for the notification type.
3. **Does the recipient data match the channel requirement?**
   - `IN_APP` → needs `recipientClerkId` (a Clerk user ID string)
   - `EMAIL` → needs `email` field
   - `WHATSAPP` → needs phone number (dropped per ADD-034)

4. **If mismatch, find Clerk-based alternatives.** For SOS dispatch, phone-based responders don't work. Instead, query `UserRole` for security/estate_admin users by their Clerk IDs.

## Example: SOS Dispatch (Broken → Fixed)

**Before (broken):**
```typescript
// SOS dispatch sent to phone-based SOSResponders
// Channel map: [IN_APP, EMAIL]
// IN_APP recipient: responder.phone (NOT a Clerk ID — fails silently)
// EMAIL recipient: responder.phone (NOT an email — fails silently)
```

**After (fixed):**
```typescript
// Find Clerk-based security/estate_admin users
const staffUsers = await this.prisma.userRole.findMany({
  where: {
    communityId,
    roles: { hasSome: ['security', 'secretariat', 'estate_admin', 'super_admin'] },
  },
  select: { clerkUserId: true },
});

// Dispatch to Clerk user IDs
for (const clerkUserId of staffUsers.map(u => u.clerkUserId)) {
  await this.notificationService.send({
    type: NotificationType.SOS_DISPATCH,
    recipient: clerkUserId,
    recipientClerkId: clerkUserId, // IN_APP can deliver this
    data: { ... },
  });
}
```

## Channel Map Guidelines

Post ADD-034 (no WhatsApp/SMS), the safe channel map for each recipient type:

| Recipient Type | Safe Channel | Notes |
|---------------|-------------|-------|
| Clerk users (residents, admins) | `IN_APP` only | Use `recipientClerkId` |
| Phone-only (responders, visitors) | None available | Must convert to Clerk-based dispatch via `UserRole` lookup |
| Email-based | `EMAIL` | Requires actual email address |
