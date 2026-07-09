# JSX nullish coalescing vs logical OR — empty string trap

## The bug

When rendering an avatar initial from a lead's name or email, using `??` for fallback
fails when the value is an **empty string** `""`:

```tsx
// ❌ BAD — empty string "" bypasses ?? and [0] returns undefined
{(lead.name ?? lead.email ?? '?')[0].toUpperCase()}
//  ^^^^^^^^^ if lead.name = "", ""[0] = undefined → .toUpperCase() crashes

// ✅ GOOD — || catches empty strings too
{(lead.name || lead.email || '?')[0].toUpperCase()}
```

## Why

`??` (nullish coalescing) only catches `null` and `undefined`.
`||` (logical OR) catches `null`, `undefined`, `""`, `0`, `false`, `NaN`.

An empty string from the database (`""`) bypasses `??` completely.
The `[0]` accessor on an empty string returns `undefined`.
Calling `.toUpperCase()` on `undefined` throws:
```
Uncaught TypeError: Cannot read properties of undefined (reading 'toUpperCase')
```

## Detection

In production minified JS, this appears as:
```
Cannot read properties of undefined (reading 'toUpperCase')
at Array.map
```

## Rule

When the fallback value could be an **empty string from a database field**
(name, email, description), use `||` not `??`:

```tsx
// Safe pattern for nullable database fields
{(record.name || record.email || '?')[0].toUpperCase()}
{record.name || 'Anonymous'}
{record.description || 'No description'}
```

## Related

- The same bug breaks `String.prototype` methods (`toUpperCase`, `toLowerCase`,
  `trim`, `charAt`) when called on `undefined` from `""[0]`.
- This is distinct from the typical `data?.property ?? fallback` pattern
  which correctly handles null/undefined but NOT empty strings.
