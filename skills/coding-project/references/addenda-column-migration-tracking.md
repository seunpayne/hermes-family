# Addendum Column Migration Tracking

## The problem

When addenda introduce new database columns (e.g. ADD-028's `Compound.isSeedData`,
`Resident.isSeedData`), the migration SQL for those columns may not be created by the
sub-agent. The columns appear in `schema.prisma` (because the sub-agent adds the model
field), but the corresponding `ALTER TABLE ADD COLUMN` SQL never gets written to a
migration file.

Later, when Prisma queries those columns at runtime, it throws:
```
PrismaClientKnownRequestError: column 'Compound.isSeedData' does not exist
```

## Detection after every addendum with DB changes

```bash
python3 -c "
import re, os

with open('prisma/schema.prisma') as f:
    schema = f.read()

models = {}
current = None
for line in schema.split('\n'):
    if line.strip().startswith('model '):
        current = line.split()[1]
        models[current] = []
    elif current and line.strip() and not line.strip().startswith('}') and not line.strip().startswith('//'):
        field = line.strip().split()[0]
        if field and not field.startswith('@@'):
            models[current].append(field)

for root, dirs, files in os.walk('prisma/migrations'):
    for f in files:
        if f == 'migration.sql':
            with open(os.path.join(root, f)) as mf:
                mig = mf.read()
            for model, fields in list(models.items()):
                for field in list(fields):
                    if f'\"{field}\"' in mig:
                        models[model].remove(field)

for model, fields in models.items():
    for f in fields:
        print(f'MISSING MIGRATION: {model}.{field}')
"
```

## Example: ADD-028

The addendum specified:
```sql
ALTER TABLE "Compound" ADD COLUMN IF NOT EXISTS "isSeedData" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Resident" ADD COLUMN IF NOT EXISTS "isSeedData" BOOLEAN NOT NULL DEFAULT false;
```

The sub-agent added the field to `schema.prisma` but never wrote the migration SQL.
Railway logs showed the error 24 hours later on first query.

## Prevention

After every addendum that mentions new columns, grep the addendum for `ALTER TABLE`
or `CREATE TABLE`. For each statement found, verify a corresponding migration SQL file
exists under `prisma/migrations/`. Do NOT trust that the sub-agent created them.
