# Frontend Mock Data Audit

When reviewing a frontend codebase to find pages still using hardcoded mock data instead of real API calls, follow this systematic procedure.

## Goal

Identify every `page.tsx` (or component) that:
- Renders from a hardcoded array/object (mock data)
- Uses unauthenticated `fetch()` with wrong URL prefix
- Has a mock-data fallback on API error
- Calls the API but with no auth header

## Procedure

### 1. List all page files

```bash
find frontend/src/app -name "page.tsx" | sort
```

Also check key components:
```bash
find frontend/src/components -name "*.tsx" | sort
```

### 2. Quick triage — mock data vs API usage per file

```bash
for f in frontend/src/app/*/page.tsx; do
  name=$(basename $(dirname $f))
  mock=$(grep -cE "const \w+ = \[|MOCK_" "$f")
  api=$(grep -cE "from.*api|fetch\(|request\(" "$f")
  echo "$name: mock=$mock api=$api"
done
```

- `mock > 0` and `api == 0` → needs API wiring
- `mock > 0` and `api > 0` → may have fallback pattern — check deeper
- `mock == 0` and `api > 0` → likely wired correctly

### 3. Deeper check for specific patterns

```bash
# Check for hardcoded arrays with data shapes
grep -nE "const \w+ = \[\s*$|const \w+ = \[$" page.tsx

# Check for unauthenticated localhost fetch
grep -n "fetch\('http://localhost" page.tsx

# Check for /api/ prefix (no /v1/)
grep -n "fetch\('/api/" page.tsx

# Check for mock fallback on catch
grep -nB1 -A3 "catch\s*\(.*\)\s*{" page.tsx
```

### 4. Classify findings

| Status | Meaning | Action |
|--------|---------|--------|
| **Hardcoded** | `const data = [...]` with no API import | Wire to existing API function or add new endpoint |
| **Wrong prefix** | `fetch('/api/...')` without `/v1/` | Replace with `request()` from `@/lib/api` |
| **No auth** | `fetch('http://host/...')` with no Bearer header | Replace with API client that sends auth token |
| **Mock fallback** | `catch { setData([...hardcoded...]) }` | Remove fallback, show error state instead |
| **Static UI** | Navigation items, settings form with hardcoded defaults | Acceptable — no data to fetch |

### 5. Per-page checklist items

For each page flagged as needing wiring:

- [ ] Add API functions to `lib/api.ts` if they don't exist
- [ ] Import the API function in the page file
- [ ] Add `useEffect` + loading/error states
- [ ] Replace hardcoded array/object with fetched data
- [ ] Map API response fields to component props if shapes differ
- [ ] Keep the same UI structure — only swap the data source
- [ ] Remove mock fallback — show error message instead
- [ ] Verify `npx tsc --noEmit` passes

## Common Patterns

### Pattern: Hardcoded array → API fetch

**Before:**
```tsx
const items = [
  { name: 'Chidi', compound: 'Blk A', status: 'active' },
  // ...
];
export default function Page() { return <Table data={items} />; }
```

**After:**
```tsx
export default function Page() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    getItems().then(setItems).catch(...).finally(() => setLoading(false));
  }, []);
  if (loading) return <Spinner />;
  return <Table data={items} />;
}
```

### Pattern: Unauthenticated fetch → API client

**Before:**
```tsx
const res = await fetch('http://localhost:3001/v1/compounds');
```

**After:**
```tsx
import { getCompounds } from '@/lib/api';
const data = await getCompounds();
```

### Pattern: Mock fallback → Error state

**Before:**
```tsx
try {
  const data = await fetch('/api/levy-bills');
  setLevies(data);
} catch {
  setLevies([{ id: '1', description: 'Mock Levy', ... }]); // ❌
}
```

**After:**
```tsx
try {
  const data = await getMyLevyBills();
  setLevyBills(data);
} catch {
  setError('Failed to load levy information'); // ✅
}
```

## Why This Matters

Every mock data point that reaches production creates a confusing experience — residents see fake levy bills, admins see fake residents, security sees fake visitor logs. A systematic audit before removing `SKIP_AUTH` ensures the entire frontend is live before auth is enforced.
