# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

# STACK PLAYBOOK: API / Backend Service — Node.js + Fastify + Supabase + Railway
# Version: 1.0
# Michael reads this before generating task CODE sections
# for any API-only, backend service, or webhook handler project.

---

## STACK IDENTITY

```
Runtime:      Node.js 22+
Framework:    Fastify (not Express — faster, better TypeScript)
Database:     Supabase (Postgres + Auth + Realtime)
Language:     TypeScript (strict)
Testing:      Vitest (unit) + Supertest (integration)
Deployment:   Railway (primary) or Render (fallback)
CI/CD:        GitHub Actions
Process mgr:  built-in Railway (no PM2 needed on Railway)
Environment:  dotenv for local, Railway env vars for production
```

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **Fastify not Express.**
   The family uses Fastify. Do not generate Express patterns.
   Fastify registers plugins with `fastify.register()`.
   Routes use `fastify.get()`, `fastify.post()`, etc.
   Request body: `request.body`. Params: `request.params`.

2. **TypeScript strict mode — no `any`.**
   All request/response types must be defined.
   Fastify has generic type parameters for route schemas.
   Use JSON Schema for request validation (Fastify validates automatically).

3. **Supabase service role key is server-side only.**
   Never expose in client code.
   Railway env var: `SUPABASE_SERVICE_ROLE_KEY`.
   Use service role key for server-side operations (full access).
   Use anon key only for operations that should respect RLS.

4. **Webhook signature verification is mandatory.**
   Every webhook endpoint verifies the signature before processing.
   WhatsApp: verify X-Hub-Signature-256 header.
   Stripe: verify Stripe-Signature header.
   Never process a webhook payload without verifying it came from the source.

5. **Railway deployment uses Nixpacks — no Dockerfile needed.**
   Railway auto-detects Node.js and builds automatically.
   Set start command: `node dist/index.js` (after TypeScript compile).
   Or use `ts-node` for development: `npx ts-node src/index.ts`.

6. **Health check endpoint required.**
   Railway health checks `GET /health`.
   Always implement this endpoint.
   Returns: `{ status: 'ok', timestamp: Date.now() }`

7. **CORS must be configured for the specific client origin.**
   Never use `origin: '*'` in production.
   Whitelist the specific Vercel deployment URL(s).

---

## SCAFFOLD

```bash
# Create project
mkdir [project-name] && cd [project-name]
npm init -y

# Install Fastify and core plugins
npm install fastify @fastify/cors @fastify/helmet \
  @fastify/rate-limit @fastify/env

# Install Supabase
npm install @supabase/supabase-js

# Install TypeScript
npm install --save-dev typescript ts-node \
  @types/node tsx

# Install testing
npm install --save-dev vitest @vitest/coverage-v8 \
  supertest @types/supertest

# Install dotenv
npm install dotenv

# Initialise TypeScript
npx tsc --init
```

---

## REQUIRED CONFIG FILES

**tsconfig.json**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

**package.json scripts**
```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage"
  }
}
```

**.env** (never commit)
```
PORT=3000
NODE_ENV=development
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_SERVICE_ROLE_KEY=[service role key]
SUPABASE_ANON_KEY=[anon key]
ALLOWED_ORIGINS=http://localhost:5173,https://[project].vercel.app
```

**.gitignore**
```
.env
.env.local
node_modules
dist
```

---

## FASTIFY SERVER PATTERN

**src/index.ts**
```typescript
import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'
import { routes } from './routes'
import { supabase } from './lib/supabase'

const fastify = Fastify({
  logger: {
    level: process.env.NODE_ENV === 'production' ? 'warn' : 'info'
  }
})

// Security plugins
await fastify.register(helmet)
await fastify.register(cors, {
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? [],
  credentials: true
})
await fastify.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute'
})

// Health check
fastify.get('/health', async () => ({
  status: 'ok',
  timestamp: Date.now()
}))

// Routes
await fastify.register(routes, { prefix: '/api' })

// Start
const port = Number(process.env.PORT) || 3000
await fastify.listen({ port, host: '0.0.0.0' })
console.log(`Server running on port ${port}`)
```

**src/lib/supabase.ts**
```typescript
import { createClient } from '@supabase/supabase-js'

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)
```

---

## FASTIFY ROUTE PATTERNS

**src/routes/index.ts**
```typescript
import { FastifyPluginAsync } from 'fastify'
import { contactRoutes } from './contact'
import { webhookRoutes } from './webhooks'

export const routes: FastifyPluginAsync = async (fastify) => {
  await fastify.register(contactRoutes, { prefix: '/contact' })
  await fastify.register(webhookRoutes, { prefix: '/webhooks' })
}
```

**Typed route with schema validation**
```typescript
import { FastifyPluginAsync, RouteShorthandOptions } from 'fastify'
import { supabase } from '../lib/supabase'

interface ContactBody {
  name: string
  email: string
  message: string
}

const contactSchema: RouteShorthandOptions = {
  schema: {
    body: {
      type: 'object',
      required: ['name', 'email', 'message'],
      properties: {
        name: { type: 'string', minLength: 1 },
        email: { type: 'string', format: 'email' },
        message: { type: 'string', minLength: 1 }
      }
    },
    response: {
      200: {
        type: 'object',
        properties: {
          success: { type: 'boolean' },
          id: { type: 'string' }
        }
      }
    }
  }
}

export const contactRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.post<{ Body: ContactBody }>('/', contactSchema, async (request, reply) => {
    const { name, email, message } = request.body

    const { data, error } = await supabase
      .from('contact_submissions')
      .insert({ name, email, message })
      .select('id')
      .single()

    if (error) {
      fastify.log.error(error)
      return reply.status(500).send({ error: 'Submission failed' })
    }

    return { success: true, id: data.id }
  })
}
```

---

## WEBHOOK PATTERNS

**Webhook signature verification (generic)**
```typescript
import crypto from 'crypto'

function verifySignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex')
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(`sha256=${expected}`)
  )
}
```

**WhatsApp webhook (verification + incoming)**
```typescript
export const whatsappRoutes: FastifyPluginAsync = async (fastify) => {
  // Webhook verification (GET — WhatsApp handshake)
  fastify.get('/whatsapp', async (request: any, reply) => {
    const mode = request.query['hub.mode']
    const token = request.query['hub.verify_token']
    const challenge = request.query['hub.challenge']

    if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
      return reply.send(challenge)
    }
    return reply.status(403).send('Forbidden')
  })

  // Incoming messages (POST)
  fastify.post('/whatsapp', {
    config: { rawBody: true } // needed for signature verification
  }, async (request: any, reply) => {
    // Verify signature
    const signature = request.headers['x-hub-signature-256'] as string
    const isValid = verifySignature(
      request.rawBody,
      signature,
      process.env.WHATSAPP_APP_SECRET!
    )

    if (!isValid) {
      fastify.log.warn('Invalid WhatsApp signature')
      return reply.status(403).send('Forbidden')
    }

    const body = request.body as WhatsAppWebhookBody
    // Process messages
    for (const entry of body.entry ?? []) {
      for (const change of entry.changes ?? []) {
        for (const message of change.value.messages ?? []) {
          await processIncomingMessage(message, change.value.metadata)
        }
      }
    }

    return { status: 'ok' }
  })
}
```

---

## SUPABASE PATTERNS (SERVER-SIDE)

```typescript
// Insert
const { data, error } = await supabase
  .from('[table]')
  .insert({ field: value })
  .select()
  .single()

// Query with filter
const { data, error } = await supabase
  .from('[table]')
  .select('id, name, created_at')
  .eq('status', 'active')
  .order('created_at', { ascending: false })
  .limit(50)

// Update
const { error } = await supabase
  .from('[table]')
  .update({ status: 'processed' })
  .eq('id', id)

// Upsert (idempotent)
const { error } = await supabase
  .from('[table]')
  .upsert({ id, field: value })

// Call Edge Function
const { data, error } = await supabase.functions.invoke('[function-name]', {
  body: { key: value }
})
```

---

## GITHUB ACTIONS CI TEMPLATE

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npm test

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci && npm run build
      - run: ls dist/  # confirm build output exists
```

---

## RAILWAY DEPLOYMENT

```bash
# Install Railway CLI
brew install railway

# Login
railway login

# Initialise project
railway init

# Link to existing project
railway link

# Set environment variables
railway variables set SUPABASE_URL=https://...
railway variables set SUPABASE_SERVICE_ROLE_KEY=...
railway variables set ALLOWED_ORIGINS=https://[client].vercel.app
railway variables set NODE_ENV=production

# Deploy
railway up

# Get deployment URL
railway domain

# View logs
railway logs
```

**Railway service settings (dashboard):**
- Start command: `node dist/index.js`
- Health check path: `/health`
- Health check timeout: 10s
- Restart policy: on-failure

---

## TESTING PATTERNS

**Unit test (Vitest)**
```typescript
// src/tests/[module].test.ts
import { describe, it, expect, vi } from 'vitest'

describe('[function]', () => {
  it('[what it does]', () => {
    const result = fn(input)
    expect(result).toBe(expected)
  })
})
```

**Integration test (Supertest + Fastify)**
```typescript
// src/tests/routes/contact.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import Fastify from 'fastify'
import supertest from 'supertest'
import { routes } from '../../routes'

describe('POST /api/contact', () => {
  let app: ReturnType<typeof Fastify>

  beforeAll(async () => {
    app = Fastify()
    await app.register(routes, { prefix: '/api' })
    await app.ready()
  })

  afterAll(async () => {
    await app.close()
  })

  it('returns 200 with valid body', async () => {
    const response = await supertest(app.server)
      .post('/api/contact')
      .send({ name: 'Test', email: 'test@test.com', message: 'Hello' })
      .expect(200)

    expect(response.body.success).toBe(true)
  })

  it('returns 400 with invalid email', async () => {
    await supertest(app.server)
      .post('/api/contact')
      .send({ name: 'Test', email: 'not-an-email', message: 'Hello' })
      .expect(400)
  })
})
```

**Run tests**
```bash
npm test
npm run test:coverage
```

---

## STANDARD DIRECTORY STRUCTURE

```
[project-name]/
  src/
    index.ts            — server entry point
    lib/
      supabase.ts       — Supabase client
    routes/
      index.ts          — route registry
      contact.ts
      webhooks/
        whatsapp.ts
        stripe.ts
    middleware/
      auth.ts           — JWT verification if needed
      signature.ts      — webhook signature verification
    services/
      [domain].ts       — business logic, not in routes
    tests/
      unit/
      routes/           — integration tests
  dist/                 — compiled output (not committed)
  .env                  — never committed
  .gitignore
  tsconfig.json
  package.json
```

---

## TASK CODE GENERATION GUIDE
*(Michael reads this section when generating CODE for PRD tasks)*

**Server scaffold task:**
Use scaffold commands and src/index.ts pattern above.
RUN: `npm run dev`
VERIFY: `curl http://localhost:3000/health`
Expected: `{"status":"ok","timestamp":[number]}`

**New route task:**
Write route file + register in routes/index.ts.
Include JSON Schema validation.
Write integration test using Supertest pattern.
RUN: `npm test`
VERIFY: all tests pass, route returns correct status codes.

**Webhook endpoint task:**
Always include signature verification.
Always return 200 quickly (process async if heavy work).
Write unit test for signature verification function.
RUN: `npm test`
VERIFY: `curl -X POST http://localhost:3000/api/webhooks/[name]`
with invalid signature returns 403.

**Railway deployment task:**
Set all env vars via `railway variables set`.
RUN: `railway up`
VERIFY: `curl https://[railway-url]/health` returns 200.
REPORT: "API live at [url]. Health check: ok."

**Supabase schema task:**
Use Supabase CLI migration pattern (same as ERP playbook).
Never run DDL via the Supabase JS client or REST API.
RUN: `supabase db push`
VERIFY: `supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_name = '[table]'"`
