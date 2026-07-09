# Orphaned Schema Fields — Migration Detection

## Problem

Sub-agents add fields to `schema.prisma` and regenerate Prisma client locally.
The app builds and deploys — but the production database was never migrated.

Every query touching the new field crashes with:
```
PrismaClientKnownRequestError: P2022
The column `Resident.kycReviewStatus` does not exist in the current database.
```

## Detection script

```bash
# Find migration SQL files
find prisma/migrations -name "migration.sql" | sort

# Find column names from all existing migrations
for f in $(find prisma/migrations -name "migration.sql"); do
  grep "ADD COLUMN" "$f" | sed 's/.*ADD COLUMN "\(.*\)".*/\1/'
done | sort -u > /tmp/existing_columns.txt

# Check schema.prisma for fields NOT in any migration
# Manual step: compare the output against the schema
```

## Recovery

1. Create a new migration directory
2. Write ALTER TABLE SQL for the missing columns
3. Commit and push — Railway runs `prisma migrate deploy` on start

## History

| Addendum | Missing Fields | Date |
|----------|---------------|------|
| ADD-053 | Resident.kycReviewStatus, kycReviewNote, kycReviewAt, kycReviewedBy | 2026-07-07 |
| ADD-042 | Invitation.residentId (fixed in main by Seun) | 2026-07-04 |
| ADD-034 | Notification model (possibly — build passed but DB migration unclear) | 2026-07-02 |
