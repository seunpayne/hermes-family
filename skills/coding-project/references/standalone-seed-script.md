# Creating a Standalone Seed Script

When the project has a SandboxService or seed logic inside NestJS (relying on DI) but you need a CLI-runnable seed script for deployment provisioning.

## The pattern

Instead of trying to bootstrap the full NestJS app just for seeding, create a standalone `prisma/seed.ts` that:

1. Imports `PrismaClient` directly from `@prisma/client`
2. Wraps all logic in an `async function main()`
3. Uses plain Prisma API calls (no service classes, no DI)
4. Handles the "already seeded" case with an existence check
5. Exits cleanly with `prisma.$disconnect()`

```typescript
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  // Check if already seeded
  const existing = await prisma.community.findUnique({ where: { slug: 'demo' } });
  if (existing) {
    console.log('Demo already exists. Skipping.');
    return;
  }
  
  // Create entities in dependency order
  const community = await prisma.community.create({ data: { ... } });
  const compound = await prisma.compound.create({ data: { communityId: community.id, ... } });
  const resident = await prisma.resident.create({ data: { compoundId: compound.id, ... } });
  // ... etc
}

main().catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
```

## Wiring

### 1. Add to Prisma schema:
```prisma
generator client {
  provider = "prisma-client-js"
  seed     = "npx tsx prisma/seed.ts"
}
```

### 2. Add npm script to package.json:
```json
"db:seed": "npx tsx prisma/seed.ts"
```

### 3. Run:
```bash
npm run db:seed
```

## Why not reuse SandboxService?

SandboxService is an `@Injectable()` NestJS class that depends on `PrismaService` injected via constructor. Running it outside NestJS requires bootstrapping the full app:

```typescript
// DON'T do this — fragile and slow
const app = await NestFactory.create(AppModule);
const sandbox = app.get(SandboxService);
await sandbox.seedDemoData();
```

A standalone seed script is simpler, faster, and deployment-pipeline friendly.

## Pitfalls

- **TypeScript strict mode** will infer empty arrays as `never[]`. Annotate as `any[]`:
  ```typescript
  const compounds: any[] = [];
  ```
- **Prisma seed config** in schema.prisma's `generator` block is optional — the script runs fine without it. The `seed` entry just makes `prisma db seed` work.
- **Don't include NestJS-specific code** (guards, interceptors, config modules) — they won't work outside the app context.
