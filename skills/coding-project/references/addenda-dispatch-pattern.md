# Addenda-Based Development Pattern

## Format
Seun delivers requirements as numbered addenda with a consistent structure:
- **Title** and **applies-to** declaration
- **CONTEXT**: one-sentence summary of why this addendum exists
- **CHANGE** blocks: explicit code/configuration with file paths
- **DO NOT CHANGE**: boundary markers — explicit lists of what to preserve
- **AFTER IMPLEMENTING**: verification steps (what to test, what to check)
- **Commit message**: exact format to use

## Dispatch Pattern
When Seun provides an addendum, dispatch it to the appropriate sub-agent via delegate_task:
```typescript
delegate_task(
  goal="Execute ADD-XXX: [title from addendum]",
  context="[full addendum content, workspace path, all constraints]",
  toolsets=["terminal", "file", "search"]
)
```

## Key Rules
- The addendum IS the spec — don't ask clarifying questions unless truly ambiguous
- Execute ALL steps in the addendum before reporting back
- Present build verification results (npm run build exit code) after completion
- Commit with the exact message specified in the addendum

## Review-First Gate
When Seun says "Review first, if there is a better approach, notify me, if not, execute":
1. Read the full addendum
2. Check for conflicts with existing code, architecture, or recently merged changes
3. If approach is sound: say "Approach is sound. Proceeding." and execute
4. If one improvement: say "One improvement: [specific]. Otherwise proceed." and execute
5. If multiple issues: list them and ask for confirmation before executing
Never silently execute without reviewing when this gate is active.

## Prisma Enum Mapping Pitfall
When a frontend-facing plan/tier name differs from the Prisma enum:
```prisma
enum SubscriptionTier { free starter growth enterprise }
```
But the DTO/frontend uses `'estate'` for the top tier. Always map:
```typescript
const tierMap: Record<string, SubscriptionTier> = {
  starter: 'starter', growth: 'growth', estate: 'enterprise'
};
planTier: tierMap[dto.plan]
```
Common in: subscription creation, demo conversion, plan assignment.

## Package-lock CI Failure
When `npm install` modifies `package-lock.json` (new dep like Playwright, svix, twilio):
CI uses `npm ci` which requires exact lock file match. Before pushing:
```bash
git status --short | grep package-lock.json
```
If modified but unstaged: `git add package-lock.json` and commit. This applies to BOTH backend and frontend. The fix is always one commit: "fix: commit [backend|frontend] package-lock.json".

## Migration Commands
⚠️ Provide SQL statements for manual Supabase SQL Editor execution.
NEVER use `npx prisma migrate deploy` — Seun runs migrations himself via the dashboard.
Format:
```sql
ALTER TABLE "Community" ADD COLUMN IF NOT EXISTS "ownerClerkId" TEXT;

INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'baseline', NOW(), 'migration_name', NULL, NULL, NOW(), 1);
```
Also generate the Prisma migration file (`npx prisma migrate dev --name xxx --create-only`) and check the generated SQL into `prisma/migrations/` for reference.
