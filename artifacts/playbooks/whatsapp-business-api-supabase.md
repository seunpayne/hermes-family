# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

# STACK PLAYBOOK: WhatsApp Integration — WhatsApp Business API + Supabase
# Version: 1.0
# Michael reads this before generating task CODE sections
# for any project requiring WhatsApp messaging (ERP, client marketing, notifications).
# Reference: Siteti API (Nigeria) + Meta WhatsApp Business Platform

---

## STACK IDENTITY

```
API:          WhatsApp Business API (Cloud API via Meta)
Provider:     Siteti (Nigerian reseller) OR direct Meta access
Webhook:      Fastify endpoint (see API/backend playbook)
Database:     Supabase (message logs, templates, contacts)
Language:     TypeScript (Node.js)
Testing:      Vitest (unit) + ngrok (local webhook testing)
Compliance:   Must have approved message templates for outbound
```

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **Template messages only for outbound (first contact).**
   You can only send free-form messages within 24 hours
   of the customer sending you a message first.
   Outside the 24-hour window: use approved templates only.
   Never send unapproved text outside the window — account gets flagged.

2. **Webhook verification must happen before processing.**
   Meta sends a GET request to verify your webhook before
   sending any messages. Handle `hub.mode`, `hub.verify_token`,
   `hub.challenge` in the GET handler.
   The verify token is a secret you set in Meta dashboard.
   Never skip this verification.

3. **WhatsApp API approval takes 2-4 weeks.**
   The Siteti application checklist must be started immediately
   when a project needs WhatsApp. Do not build the integration
   first and apply later — the approval is on the critical path.

4. **Phone numbers must be in E.164 format.**
   Nigerian numbers: +2348012345678 (not 08012345678).
   Always normalise phone numbers to E.164 before sending.
   Store numbers in E.164 in Supabase.

5. **Rate limits: 1,000 messages/day on free tier.**
   Siteti and Meta both have rate limits.
   For ERP bulk notifications: batch sends and use queues.
   Never fire 5,000 messages in a loop — implement delays.

6. **Message status webhooks are separate from incoming messages.**
   Outbound message status (sent, delivered, read, failed)
   arrives via the same webhook endpoint.
   Check `statuses` array in webhook payload separately from
   `messages` array.

7. **ngrok required for local webhook testing.**
   Meta cannot reach localhost. Use ngrok to expose a tunnel.
   `ngrok http 3000` → copy the HTTPS URL to Meta webhook config.
   Use a consistent ngrok subdomain if possible (paid ngrok).

8. **Siteti API differences from direct Meta API.**
   Siteti is a Nigerian reseller with a wrapper API.
   Base URL differs: check Siteti docs for current endpoint.
   Authentication may differ from Meta's standard Bearer token.
   Always confirm with Siteti's latest documentation.

---

## META WHATSAPP BUSINESS API SETUP

```
1. Create Meta Business Account at business.facebook.com
2. Create WhatsApp Business App in Meta Developer Console
3. Add WhatsApp product to the app
4. Get test phone number (provided by Meta for development)
5. Add your actual phone number for production
6. Configure webhook URL (your Railway/Vercel endpoint)
7. Set webhook verify token (a secret string you choose)
8. Subscribe to: messages, message_status, messaging_postbacks

Required credentials (save to Railway env vars):
  WHATSAPP_PHONE_NUMBER_ID  — from Meta dashboard
  WHATSAPP_ACCESS_TOKEN     — permanent token (not temp)
  WHATSAPP_VERIFY_TOKEN     — string you set in Meta dashboard
  WHATSAPP_APP_SECRET       — for signature verification
  WHATSAPP_BUSINESS_ACCOUNT_ID
```

---

## SITETI API SETUP (Nigerian provider)

```
1. Apply at siteti.com → WhatsApp Business API
2. Provide: business registration, CAC document, website URL
3. Approval: 1-3 weeks for Nigerian businesses
4. After approval: receive API credentials and sandbox access
5. Test in sandbox before going live

Required credentials:
  SITETI_API_URL     — Siteti's API endpoint
  SITETI_API_KEY     — from Siteti dashboard
  SITETI_SENDER_ID   — your approved WhatsApp number
```

---

## MESSAGE TEMPLATES

### Create template (Meta dashboard or API)
```typescript
// Create via Meta API
const response = await fetch(
  `https://graph.facebook.com/v19.0/${process.env.WHATSAPP_BUSINESS_ACCOUNT_ID}/message_templates`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.WHATSAPP_ACCESS_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: 'erp_migration_complete',
      language: 'en',
      category: 'UTILITY',
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Migration Complete ✓'
        },
        {
          type: 'BODY',
          text: 'Hello {{1}}, your data migration is complete.\n\n' +
                'Records imported:\n' +
                '• Products: {{2}}\n' +
                '• Customers: {{3}}\n' +
                '• Transactions: {{4}}\n\n' +
                'You can now start using your ERP system.'
        },
        {
          type: 'FOOTER',
          text: 'Nigerian SME ERP'
        }
      ]
    })
  }
)
```

### ERP standard templates to create
```
erp_migration_complete     — Virgil sends after migration
erp_sync_complete          — Sync engine sends after sync
erp_sync_failed            — Sync engine sends on failure
erp_payment_reminder       — Consigliere sends for subscription
erp_weekly_summary         — Optional: weekly business summary
erp_stock_alert            — When inventory hits reorder level
erp_welcome                — New client onboarding
```

---

## SENDING MESSAGES

### Send template message
```typescript
// src/services/whatsapp.ts
export async function sendTemplate(
  to: string,       // E.164 format: +2348012345678
  templateName: string,
  parameters: string[]
): Promise<{ messageId: string } | { error: string }> {
  const components = parameters.length > 0 ? [{
    type: 'body',
    parameters: parameters.map(p => ({ type: 'text', text: p }))
  }] : []

  const response = await fetch(
    `https://graph.facebook.com/v19.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.WHATSAPP_ACCESS_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to,
        type: 'template',
        template: {
          name: templateName,
          language: { code: 'en' },
          components
        }
      })
    }
  )

  const data = await response.json() as any
  if (!response.ok) {
    console.error('WhatsApp send error:', data)
    return { error: data.error?.message ?? 'Send failed' }
  }

  // Log to Supabase
  await supabase.from('whatsapp_messages').insert({
    to,
    template: templateName,
    status: 'sent',
    message_id: data.messages[0].id
  })

  return { messageId: data.messages[0].id }
}
```

### Send free-form text (within 24hr window only)
```typescript
export async function sendText(
  to: string,
  text: string
): Promise<{ messageId: string } | { error: string }> {
  const response = await fetch(
    `https://graph.facebook.com/v19.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.WHATSAPP_ACCESS_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: { body: text }
      })
    }
  )

  const data = await response.json() as any
  if (!response.ok) return { error: data.error?.message ?? 'Send failed' }
  return { messageId: data.messages[0].id }
}
```

### Normalise Nigerian phone number to E.164
```typescript
export function normaliseNigerianPhone(phone: string): string {
  // Remove spaces, dashes, parentheses
  const cleaned = phone.replace(/[\s\-\(\)]/g, '')

  // Already E.164
  if (cleaned.startsWith('+234')) return cleaned

  // Starts with 234 (no plus)
  if (cleaned.startsWith('234')) return `+${cleaned}`

  // Starts with 0 (local format: 08012345678)
  if (cleaned.startsWith('0')) return `+234${cleaned.slice(1)}`

  // Assume it needs +234 prefix
  return `+234${cleaned}`
}
```

---

## WEBHOOK HANDLER

```typescript
// src/routes/webhooks/whatsapp.ts
import { FastifyPluginAsync } from 'fastify'
import crypto from 'crypto'
import { supabase } from '../../lib/supabase'
import { processIncomingMessage } from '../../services/whatsapp-processor'

interface WhatsAppWebhookBody {
  object: string
  entry: Array<{
    id: string
    changes: Array<{
      value: {
        messaging_product: string
        metadata: { display_phone_number: string; phone_number_id: string }
        messages?: WhatsAppMessage[]
        statuses?: WhatsAppStatus[]
      }
      field: string
    }>
  }>
}

interface WhatsAppMessage {
  from: string
  id: string
  timestamp: string
  text?: { body: string }
  type: string
}

interface WhatsAppStatus {
  id: string
  status: 'sent' | 'delivered' | 'read' | 'failed'
  timestamp: string
  recipient_id: string
}

export const whatsappWebhookRoutes: FastifyPluginAsync = async (fastify) => {
  // Webhook verification
  fastify.get<{
    Querystring: {
      'hub.mode': string
      'hub.verify_token': string
      'hub.challenge': string
    }
  }>('/whatsapp', async (request, reply) => {
    const { 'hub.mode': mode, 'hub.verify_token': token, 'hub.challenge': challenge } = request.query

    if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
      fastify.log.info('WhatsApp webhook verified')
      return reply.send(challenge)
    }

    fastify.log.warn('WhatsApp webhook verification failed')
    return reply.status(403).send('Forbidden')
  })

  // Incoming messages
  fastify.post<{ Body: WhatsAppWebhookBody }>(
    '/whatsapp',
    { config: { rawBody: true } },
    async (request, reply) => {
      // Verify signature
      const signature = request.headers['x-hub-signature-256'] as string
      if (!verifySignature((request as any).rawBody, signature)) {
        fastify.log.warn('Invalid WhatsApp signature — rejected')
        return reply.status(403).send('Forbidden')
      }

      // Always respond 200 quickly — process async
      reply.status(200).send({ status: 'ok' })

      // Process messages
      for (const entry of request.body.entry ?? []) {
        for (const change of entry.changes ?? []) {
          const { messages, statuses } = change.value

          // Incoming messages
          for (const message of messages ?? []) {
            try {
              await processIncomingMessage(message, change.value.metadata)
            } catch (err) {
              fastify.log.error({ err, message }, 'Failed to process message')
            }
          }

          // Message status updates
          for (const status of statuses ?? []) {
            await supabase
              .from('whatsapp_messages')
              .update({ status: status.status })
              .eq('message_id', status.id)
          }
        }
      }
    }
  )
}

function verifySignature(payload: string, signature: string): boolean {
  if (!signature?.startsWith('sha256=')) return false
  const expected = crypto
    .createHmac('sha256', process.env.WHATSAPP_APP_SECRET!)
    .update(payload)
    .digest('hex')
  const received = signature.slice(7) // remove 'sha256='
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(received, 'hex')
  )
}
```

---

## SUPABASE SCHEMA FOR WHATSAPP

```sql
-- Message log
CREATE TABLE whatsapp_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  to_number text NOT NULL,
  from_number text,
  direction text CHECK (direction IN ('outbound', 'inbound')),
  template text,
  content text,
  status text DEFAULT 'pending',
  message_id text UNIQUE,
  client_id uuid REFERENCES clients(id),
  error_message text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- WhatsApp contacts (opt-in tracking)
CREATE TABLE whatsapp_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone text UNIQUE NOT NULL, -- E.164 format
  name text,
  opted_in boolean DEFAULT false,
  opt_in_date timestamptz,
  client_id uuid REFERENCES clients(id),
  created_at timestamptz DEFAULT now()
);

-- Template tracking
CREATE TABLE whatsapp_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  status text DEFAULT 'pending', -- pending, approved, rejected
  category text,
  language text DEFAULT 'en',
  created_at timestamptz DEFAULT now()
);

CREATE INDEX ON whatsapp_messages(to_number);
CREATE INDEX ON whatsapp_messages(message_id);
CREATE INDEX ON whatsapp_messages(client_id);
CREATE INDEX ON whatsapp_contacts(phone);

ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_templates ENABLE ROW LEVEL SECURITY;
```

---

## ERP-SPECIFIC WHATSAPP PATTERNS

### Virgil sends migration complete notification
```typescript
import { sendTemplate, normaliseNigerianPhone } from './whatsapp'

export async function notifyMigrationComplete(
  clientPhone: string,
  clientName: string,
  productsCount: number,
  customersCount: number,
  transactionsCount: number
): Promise<void> {
  const phone = normaliseNigerianPhone(clientPhone)
  await sendTemplate(phone, 'erp_migration_complete', [
    clientName,
    productsCount.toString(),
    customersCount.toString(),
    transactionsCount.toString()
  ])
}
```

### Sync engine sends sync failure alert
```typescript
export async function notifySyncFailed(
  clientPhone: string,
  deviceName: string,
  errorSummary: string
): Promise<void> {
  const phone = normaliseNigerianPhone(clientPhone)
  await sendTemplate(phone, 'erp_sync_failed', [
    deviceName,
    errorSummary
  ])
}
```

### Consigliere sends payment reminder
```typescript
export async function sendPaymentReminder(
  clientPhone: string,
  clientName: string,
  amountNgn: number,
  dueDateStr: string
): Promise<void> {
  const phone = normaliseNigerianPhone(clientPhone)
  await sendTemplate(phone, 'erp_payment_reminder', [
    clientName,
    `₦${amountNgn.toLocaleString()}`,
    dueDateStr
  ])
}
```

---

## LOCAL TESTING WITH NGROK

```bash
# Install ngrok
brew install ngrok

# Authenticate (create account at ngrok.com)
ngrok config add-authtoken [your-token]

# Start tunnel
ngrok http 3000

# Copy HTTPS URL: https://[random].ngrok.io
# Set as webhook URL in Meta WhatsApp dashboard
# Set verify token to match WHATSAPP_VERIFY_TOKEN env var

# Test webhook verification
curl "https://[ngrok-url]/api/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token=[your-token]&hub.challenge=test123"
# Expected response: test123
```

---

## TESTING PATTERNS

### Unit test — phone normalisation
```typescript
import { describe, it, expect } from 'vitest'
import { normaliseNigerianPhone } from '../services/whatsapp'

describe('normaliseNigerianPhone', () => {
  it('handles local format', () => {
    expect(normaliseNigerianPhone('08012345678')).toBe('+2348012345678')
  })
  it('handles E.164 already', () => {
    expect(normaliseNigerianPhone('+2348012345678')).toBe('+2348012345678')
  })
  it('handles 234 prefix without plus', () => {
    expect(normaliseNigerianPhone('2348012345678')).toBe('+2348012345678')
  })
  it('strips spaces', () => {
    expect(normaliseNigerianPhone('080 1234 5678')).toBe('+2348012345678')
  })
})
```

### Unit test — signature verification
```typescript
import { describe, it, expect } from 'vitest'
import crypto from 'crypto'

describe('verifySignature', () => {
  it('returns true for valid signature', () => {
    const secret = 'test-secret'
    const payload = 'test-payload'
    const signature = 'sha256=' + crypto
      .createHmac('sha256', secret)
      .update(payload)
      .digest('hex')
    // test your verifySignature function
    expect(verifySignature(payload, signature, secret)).toBe(true)
  })

  it('returns false for invalid signature', () => {
    expect(verifySignature('payload', 'sha256=invalid', 'secret')).toBe(false)
  })
})
```

---

## STANDARD DIRECTORY STRUCTURE

```
src/
  routes/
    webhooks/
      whatsapp.ts       — webhook handler
  services/
    whatsapp.ts         — sendTemplate, sendText, normalisePhone
    whatsapp-processor.ts — processIncomingMessage logic
  tests/
    unit/
      whatsapp.test.ts
supabase/
  migrations/
    [timestamp]_whatsapp_schema.sql
```

---

## TASK CODE GENERATION GUIDE
*(Michael reads this section when generating CODE for PRD tasks)*

**WhatsApp schema task:**
Use SQL from SUPABASE SCHEMA section above.
RUN: `supabase db push`
VERIFY: `supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'whatsapp_%'"`
Expected: 3 tables.

**Webhook setup task:**
Use whatsappWebhookRoutes pattern.
Write unit tests for verifySignature and phone normalisation.
RUN: `ngrok http 3000` and test with curl.
VERIFY: curl returns hub.challenge value. 403 on bad token.

**Send template task:**
Use sendTemplate function pattern.
Define template in Meta dashboard first (approved templates only).
RUN: Send to test number in Meta sandbox.
VERIFY: Message appears on test phone. Supabase row created.

**Phone normalisation task:**
Use normaliseNigerianPhone function.
Write unit tests for all four input formats.
RUN: `npm test`
VERIFY: all 4 test cases pass.
