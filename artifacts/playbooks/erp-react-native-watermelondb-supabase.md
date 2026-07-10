# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

# STACK PLAYBOOK: ERP — React Native (Expo) + WatermelonDB + Supabase
# Version: 1.0
# Derived from: sync engine prototype build (May 2026)
# Michael reads this before generating task CODE sections
# for any ERP or offline-first mobile project.

---

## STACK IDENTITY

```
Mobile:       React Native (Expo SDK 52+)
Local DB:     WatermelonDB (SQLite via expo-sqlite)
Cloud DB:     Supabase (Postgres + Auth + Realtime)
Language:     TypeScript (strict)
Testing:      Vitest (unit + integration) + Detox (E2E)
CI/CD:        GitHub Actions + EAS Build
Deployment:   EAS (Expo Application Services)
Schema ops:   Supabase CLI (never REST API for DDL)
```

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **Supabase REST API cannot run DDL.**
   CREATE TABLE, ALTER TABLE, DROP TABLE — always via
   Supabase CLI or dashboard SQL editor. Never via
   the `/rest/v1/` endpoint. Tasks that need schema
   changes must use `supabase db execute` or migration files.

2. **WatermelonDB decorators need explicit TypeScript config.**
   Always include in tsconfig.json:
   ```json
   { "experimentalDecorators": true, "useDefineForClassFields": false }
   ```
   And in babel.config.js:
   ```javascript
   plugins: [['@babel/plugin-proposal-decorators', { legacy: true }]]
   ```

3. **baseline_stock must be captured at write time.**
   Never reconstruct from history. Every inventory write
   (IN, OUT, ADJUSTMENT) must store baseline_stock at the
   moment of the write. If missing, semantic merge is impossible
   and the conflict resolver must flag for manual review.

4. **ADJUSTMENT conflicts are never auto-merged.**
   This is a hard rule. The conflict resolver flags ADJUSTMENT
   conflicts for human review and stops. No agent implements
   auto-resolution for ADJUSTMENT type without explicit
   Seun design decision.

5. **WatermelonDB's synchronize() sends all changes at once.**
   For large queues (Scenario 5: 5,000 items), implement a
   chunking wrapper around pushChanges with configurable
   BATCH_SIZE = 500. WatermelonDB does not chunk automatically.

6. **Expo Go vs EAS Build.**
   Prototype and development: Expo Go (fast, no build step).
   Production: EAS Build (full native build, required for
   WatermelonDB JSI in production). Never use Expo Go for
   production performance testing.

7. **Environment variables in Expo.**
   Expo reads from .env files but only variables prefixed
   with EXPO_PUBLIC_ are available in the app bundle.
   Server-side keys (Supabase service role) must NEVER
   be EXPO_PUBLIC_ — they would be exposed in the app bundle.
   Use Supabase anon key (safe) for client. Service role key
   (secret) stays in scripts and edge functions only.

8. **DO NOT USE EXPO TO PROTOTYPE SYNC LOGIC.**
   Expo's Metro bundler, WatermelonDB native modules,
   and Babel preset chains create compounding errors
   that block progress without touching the actual
   logic being tested.

   Prototype the sync engine as Node.js TypeScript.
   Test with Vitest against real Supabase.
   The sync engine is a TypeScript module.
   The mobile app is the container.
   Test the module. Not the container.

   Integration into Expo/React Native happens AFTER
   all sync logic scenarios pass in Node.js.

   See: universal-principles.md Principle 1 and 9.

---

## SCAFFOLD

```bash
# Create Expo project
npx create-expo-app@latest [project-name] --template blank-typescript
cd [project-name]

# Install WatermelonDB
npm install @nozbe/watermelondb @nozbe/with-observables
npx expo install expo-sqlite @expo/vector-icons

# Install decorators support
npm install --save-dev @babel/plugin-proposal-decorators

# Install Supabase client
npm install @supabase/supabase-js

# Install NetInfo for connectivity detection
npx expo install @react-native-community/netinfo

# Install testing
npm install --save-dev vitest @vitest/coverage-v8

# Install dotenv for scripts
npm install dotenv
```

---

## REQUIRED CONFIG FILES

**babel.config.js** (replace existing)
```javascript
module.exports = function (api) {
  api.cache(true)
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      ['@babel/plugin-proposal-decorators', { legacy: true }]
    ]
  }
}
```

**tsconfig.json** (add to compilerOptions)
```json
{
  "compilerOptions": {
    "experimentalDecorators": true,
    "useDefineForClassFields": false,
    "strict": true,
    "esModuleInterop": true
  }
}
```

**vitest.config.ts**
```typescript
import { defineConfig } from 'vitest/config'
export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    coverage: {
      provider: 'v8',
      threshold: { lines: 70, functions: 70 }
    }
  }
})
```

**.env.local** (never commit)
```
EXPO_PUBLIC_SUPABASE_URL=https://[project-ref].supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=[anon key — safe for client]
# Service role key — for scripts only, never EXPO_PUBLIC_
SUPABASE_SERVICE_ROLE_KEY=[service role key]
```

**app.config.js**
```javascript
module.exports = {
  expo: {
    name: '[App Name]',
    slug: '[app-slug]',
    extra: {
      supabaseUrl: process.env.EXPO_PUBLIC_SUPABASE_URL,
      supabaseAnonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
    }
  }
}
```

---

## SUPABASE CLI — ALL SCHEMA OPERATIONS

```bash
# Install CLI (once per machine)
brew install supabase/tap/supabase

# Initialise in project
supabase init

# Link to existing Supabase project
supabase link --project-ref [project-ref]
# Enter database password when prompted

# Create a migration file
supabase migration new [migration-name]
# Creates supabase/migrations/[timestamp]_[name].sql

# Write SQL in the migration file, then push
supabase db push

# Execute raw SQL directly (for one-off operations)
supabase db execute --sql "SELECT * FROM [table] LIMIT 5"

# Execute SQL from a file
supabase db execute --file supabase/migrations/[file].sql

# Verify tables exist
supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"

# Pull remote schema (sync remote changes to local)
supabase db pull

# Generate TypeScript types from schema
supabase gen types typescript --local > src/types/supabase.ts
```

---

## WATERMELONDB STANDARD PATTERNS

### Database initialisation
```typescript
// src/db/index.ts
import { Database } from '@nozbe/watermelondb'
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite'
import { schema } from './schema'
import { Product } from './models/Product'
import { Transaction } from './models/Transaction'

const adapter = new SQLiteAdapter({
  schema,
  dbName: '[app-name]',
  jsi: true,
  onSetUpError: (error) => {
    console.error('WatermelonDB setup error:', error)
  }
})

export const database = new Database({
  adapter,
  modelClasses: [Product, Transaction]
})
```

### Schema definition pattern
```typescript
// src/db/schema.ts
import { appSchema, tableSchema } from '@nozbe/watermelondb'

export const schema = appSchema({
  version: 1,
  tables: [
    tableSchema({
      name: '[table_name]',
      columns: [
        { name: '[field]', type: 'string' },
        { name: '[field]', type: 'number' },
        { name: '[field]', type: 'boolean' },
        { name: '[field]', type: 'string', isOptional: true },
        { name: '[field]', type: 'string', isIndexed: true },
      ]
    })
  ]
})
```

### Model pattern
```typescript
// src/db/models/[Model].ts
import { Model } from '@nozbe/watermelondb'
import { field } from '@nozbe/watermelondb/decorators'

export class [Model] extends Model {
  static table = '[table_name]'
  @field('[field]') [field]!: string
  @field('[number_field]') [number_field]!: number
  @field('[bool_field]') [bool_field]!: boolean
}
```

### Writing to WatermelonDB (always inside database.write())
```typescript
// Create
await database.write(async () => {
  await database.get<Product>('products').create(record => {
    record.name = 'Product Name'
    record.quantity = 100
    record.baseline_stock = 100  // ALWAYS capture baseline
  })
})

// Update
await database.write(async () => {
  await existingRecord.update(record => {
    record.quantity = 90
  })
})

// Delete
await database.write(async () => {
  await record.destroyPermanently()
})
```

### Querying WatermelonDB
```typescript
import { Q } from '@nozbe/watermelondb'

// Fetch all
const all = await database.get('products').query().fetch()

// Filter
const pending = await database
  .get('sync_queue')
  .query(Q.where('status', 'PENDING'))
  .fetch()

// Count
const count = await database
  .get('sync_queue')
  .query(Q.where('status', 'PENDING'))
  .fetchCount()

// Multiple conditions
const items = await database
  .get('transactions')
  .query(
    Q.where('product_id', productId),
    Q.where('type', Q.oneOf(['IN', 'OUT']))
  )
  .fetch()
```

---

## SYNC ENGINE PATTERNS

### Conflict resolution — three paths
```typescript
// Path 1: ADJUSTMENT — always flag, never auto-merge
if (payload.type === 'ADJUSTMENT') {
  return { requiresManualReview: true, reason: 'ADJUSTMENT' }
}

// Path 2: Inventory additive (IN/OUT) — semantic merge
// merged = server_value + (local_value - baseline_stock)
const merged = serverQuantity + (localQuantity - baselineStock)

// Path 3: Non-critical fields — last-write-wins
const winner = serverTimestamp >= localTimestamp ? server : local
```

### Retry pattern with exponential backoff
```typescript
const RETRY_DELAYS = [30_000, 120_000, 600_000] // 30s, 2min, 10min
const MAX_RETRIES = 3

// On failure:
if (retryCount >= MAX_RETRIES) {
  status = 'FAILED'
} else {
  const delay = RETRY_DELAYS[retryCount] ?? 600_000
  // Schedule retry after delay
  status = 'PENDING'
  retryCount++
}
```

### Batch processing pattern (500 items per batch)
```typescript
const BATCH_SIZE = 500
for (let i = 0; i < items.length; i += BATCH_SIZE) {
  const batch = items.slice(i, i + BATCH_SIZE)
  const batchNum = Math.floor(i / BATCH_SIZE) + 1
  const totalBatches = Math.ceil(items.length / BATCH_SIZE)
  console.log(`Batch ${batchNum} of ${totalBatches}`)
  // process batch
}
```

---

## SUPABASE CLIENT PATTERN (CLIENT-SIDE)

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import Constants from 'expo-constants'

const supabaseUrl = Constants.expoConfig?.extra?.supabaseUrl
const supabaseAnonKey = Constants.expoConfig?.extra?.supabaseAnonKey

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

---

## SUPABASE PATTERNS

### Insert
```typescript
const { data, error } = await supabase
  .from('[table]')
  .insert({ field: value })
  .select()
```

### Upsert (idempotent — safe for sync)
```typescript
const { error } = await supabase
  .from('[table]')
  .upsert({ id: record.id, field: value })
```

### Query with filter
```typescript
const { data, error } = await supabase
  .from('[table]')
  .select('*')
  .eq('status', 'active')
  .gt('created_at', lastSyncTimestamp)
  .order('created_at', { ascending: true })
```

### Enable RLS (run via CLI or dashboard)
```sql
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own data" ON [table]
  FOR SELECT USING (auth.uid() = user_id);
```

---

## TESTING PATTERNS

### Unit test (Vitest)
```typescript
// src/tests/unit/[Module].test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'

describe('[Module] — [function]', () => {
  it('[what it should do]', async () => {
    // arrange
    // act
    const result = await fn(input)
    // assert
    expect(result).toBe(expected)
  })
})
```

### Mock Supabase in unit tests
```typescript
vi.mock('@supabase/supabase-js', () => ({
  createClient: () => ({
    from: () => ({
      select: () => ({ data: [], error: null }),
      insert: () => ({ error: null }),
      upsert: () => ({ error: null }),
    })
  })
}))
```

### Run tests
```bash
# Run all tests
npx vitest run

# Run with coverage
npx vitest run --coverage

# Run specific file
npx vitest run src/tests/unit/SyncEngine.test.ts

# Run with verbose output
npx vitest run --reporter=verbose
```

---

## CONNECTIVITY DETECTION

```typescript
import NetInfo from '@react-native-community/netinfo'

// Subscribe to changes
const unsubscribe = NetInfo.addEventListener(state => {
  if (state.isConnected && state.isInternetReachable) {
    // Device came online — trigger sync
    syncEngine.recoverFromOffline(deviceId, lastSyncTimestamp)
  }
})

// One-time check
const state = await NetInfo.fetch()
const isOnline = state.isConnected && state.isInternetReachable
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
      - run: npx vitest run --coverage
      - name: Check coverage threshold
        run: npx vitest run --coverage --coverage.thresholds.lines=70
```

---

## STANDARD DIRECTORY STRUCTURE

```
[project-name]/
  src/
    db/
      index.ts          — database initialisation
      schema.ts         — WatermelonDB schema
      models/           — one file per model
        Product.ts
        Transaction.ts
        SyncQueue.ts
    sync/
      SyncEngine.ts     — processQueue, fetchServerChanges,
                          resolveConflict, recoverFromOffline
      types.ts          — shared TypeScript types
      __tests__/        — unit tests for sync engine
    lib/
      supabase.ts       — Supabase client
    harness/            — test harness UI (prototype only)
    screens/            — app screens
    components/         — reusable components
  supabase/
    migrations/         — SQL migration files
      [timestamp]_initial_schema.sql
  .env.local            — never committed
  app.config.js
  babel.config.js
  tsconfig.json
  vitest.config.ts
```

---

## TASK CODE GENERATION GUIDE
*(Michael reads this section when generating CODE for PRD tasks)*

**Schema task (any CREATE TABLE):**
Use Supabase CLI migration pattern.
Write SQL to `supabase/migrations/[timestamp]_[name].sql`.
RUN: `supabase db push`
VERIFY: `supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_name LIKE '[prefix]%'"`

**WatermelonDB model task:**
Use model pattern above.
Write schema entry + model file + add to database modelClasses.
RUN: `npx expo start --go` and confirm no console errors.
VERIFY: `cat src/db/schema.ts | grep [table_name]`

**Sync engine function task:**
Use SyncEngine patterns above.
Write function + unit tests in __tests__/.
RUN: `npx vitest run src/sync/__tests__/`
VERIFY: all tests pass, 0 failures.

**UI screen task (test harness):**
Use React Native functional component pattern.
Minimal styling — functional only.
RUN: `npx expo start --go` on device or simulator.
VERIFY: screen renders, buttons trigger correct functions.

**Scenario test task:**
Write Vitest test that matches scenario specification exactly.
Include expected values explicitly (e.g., expect(quantity).toBe(75)).
RUN: `npx vitest run src/tests/scenario-[N].test.ts --reporter=verbose`
VERIFY: all assertions pass, expected values confirmed.
