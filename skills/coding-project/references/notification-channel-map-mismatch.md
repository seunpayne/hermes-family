# Notification Channel Map Mismatch

When notification types map to channels that require recipient identifiers
not available in the dispatch call, every notification silently fails.

## The SOS case

SOS dispatch was mapped to `[IN_APP, EMAIL]` but dispatch sent phone numbers:
- IN_APP → needs `recipientClerkId` (Clerk user ID), got phone number → silent fail
- EMAIL → needs email address, got phone number → silent fail

All SOS alerts dispatched for weeks with zero responder notifications.

## Detection pattern

For each notification type, verify the channel map + recipient data match:

```typescript
// Check: does dispatch provide what the channel needs?
notificationService.send({
  type: NotificationType.XYZ,
  recipient: '0701...',          // ← what is this? phone? email? clerk ID?
  recipientClerkId: undefined,   // ← IN_APP needs this
  email: undefined,              // ← EMAIL needs this
  phone: '0701...',              // ← WHATSAPP/SMS need this
});
```

## Channel requirements table

| Channel | Required field | Valid format |
|---------|---------------|------------|
| IN_APP | `recipientClerkId` | `user_...` (Clerk ID) |
| EMAIL | `email` or `recipient` (as email) | `user@domain.com` |
| WHATSAPP | `phone` | `+234...` |
| SMS | `phone` | `+234...` |

## Fix: match dispatch to available recipients

If only Clerk IDs are available (from UserRole table), use IN_APP only.
If only phone numbers are available (from SOSResponder table), use WHATSAPP/SMS.
Never map to channels you can't fulfill.

Post-ADD-034 (WhatsApp/SMS dropped): all emergency notifications MUST route
through IN_APP with real Clerk user IDs. Phone-based responders are not
usable for dispatch until WhatsApp/SMS channels are re-enabled.
