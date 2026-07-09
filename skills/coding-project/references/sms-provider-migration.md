# SMS Provider Migration Pattern

## Stack progression
Siteti BSP → Termii Switch API → Twilio SDK

## Shared pattern across all providers

### 1. Never-throw-on-SMS rule
Every `sendSms()` method catches errors internally and logs them —
it NEVER throws. SMS failure must not break the caller's flow
(levy payment, SOS alert, guard invitation).

### 2. Backward compat alias
Always provide `async sendMessage(phone, body)` that delegates to
`sendSms()`. Other modules (conversation.service, notification.service)
call `sendMessage` — breaking that contract causes 3+ files of errors.

### 3. E.164 phone normalisation
```typescript
private normalisePhone(phone: string): string {
  if (phone.startsWith('+')) return phone;
  if (phone.startsWith('0')) return '+234' + phone.slice(1);
  if (phone.startsWith('234')) return '+' + phone;
  return '+234' + phone;
}
```

### 4. Convenience methods
Expose typed helpers: `sendVisitorPassNotification()`, `sendSOSAlert()`,
`sendLevyReminder()`, `sendGuardInvitation()`, `sendWelcome()`,
`sendMaintenanceUpdate()`.

## Provider-specific notes

### Termii (v3)
- URL: `https://v3.api.termii.com/api/sms/send`
- Normalisation: strip leading `0`, prepend `234` (no `+`)
- Key fields: `to`, `from`, `sms`, `type`, `channel`, `api_key`
- Standard Nigerian delivery: `channel: 'dnd'`

### Twilio (SDK)
- SDK: `npm install twilio`
- Import: `import twilio from 'twilio';`
- Normalisation: E.164 format (`+2348012345678`)
- Client: `twilio(accountSid, authToken)`
- Send: `client.messages.create({ body, from, to })`
- Contact: `this.from` = TWILIO_PHONE_NUMBER (E.164)
- Auth: TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN

### SendGrid (email companion)
- SDK: `npm install @sendgrid/mail`
- Import: `import * as sgMail from '@sendgrid/mail';`
- Init: `sgMail.setApiKey(apiKey)`
- Disabled mode: if SENDGRID_API_KEY is empty, logs all sends as
  "Not configured — skipping" without error
- From: `{ email: SENDGRID_FROM_EMAIL, name: SENDGRID_FROM_NAME }`
