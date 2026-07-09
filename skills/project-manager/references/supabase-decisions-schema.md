# Supabase Decisions Table Schema

Used when logging project decisions during status checks or handoffs.

## Table: `decisions`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | Auto-generated |
| `project_id` | UUID | FK → projects.id |
| `client_id` | UUID | FK → clients.id (nullable) |
| `made_by` | TEXT | Who decided (e.g., "seunpayne", "Clemenza") |
| `decision` | TEXT | The decision content |
| `rationale` | TEXT | Why the decision was made |
| `affects` | TEXT[] | **Array** — use `["brand", "legal"]` notation |
| `reversible` | BOOLEAN | Can this be reversed later? |
| `reversed` | BOOLEAN | Has it been reversed? |
| `reversed_by` | TEXT | Who reversed it |
| `reversed_at` | TIMESTAMPTZ | When reversed |
| `created_at` | TIMESTAMPTZ | Auto-generated |

## Insert Example

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/decisions" \
  -H "apikey: $SUPABASE_SECRET_KEY" \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "project_id": "fe62da73-...",
    "decision": "RC Number confirmed: RC 1422475",
    "rationale": "Provided by Seun on June 1, 2026",
    "made_by": "seunpayne",
    "affects": ["brand", "legal"],
    "reversible": false
  }'
```

## Common Pitfalls

- **`affects` is an array**, not a string. `"brand, legal"` → error. Use `["brand", "legal"]`.
- **`made_by`**, not `decided_by`. The column is `made_by`.
- **`category` does not exist** on this table. Use `affects` array instead.
- Decisions with `reversible: true` accumulate — audit them periodically. Use `reversed: false` in queries to only see active decisions.
