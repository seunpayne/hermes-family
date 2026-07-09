# Sub-Agent Component Migration: JSX Balance Pitfall

## The Problem

When sub-agents migrate pages from inline styles to reusable UI components (Button, Input, Card), they consistently produce **unbalanced JSX tags**. The most common pattern:

- A `<div>` is replaced with `<Card>` but its closing `</div>` is NOT changed to `</Card>`
- The page renders fine in the sub-agent (they don't run builds) but `next build` fails with:
  ```
  Error: Turbopack build failed: Expected '</', got ')'
  ```

## Detection Pattern

After every sub-agent migration of any page, ALWAYS run:

```bash
echo "Cards:" && grep -c "<Card" <page.tsx> && echo "Close Cards:" && grep -c "</Card" <page.tsx>
```

If the two numbers differ, there's a JSX balance bug. Find the mismatch and fix.

## Root Cause

The `patch` tool has a character limit per operation. Sub-agents edit the file in small chunks. When they replace `<div className="bg-white border...">` with `<Card padding="md">`, the corresponding `</div>` later in the file is often outside the patch's match window and gets missed. The sub-agent never re-reads the full file to verify balance.

## Fix Pattern

The modal pattern is the most common culprit:

```tsx
// Original (balanced)
<div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
  <div className="bg-white border border-[#DDD8CE] rounded-[16px] p-6 max-w-md w-full">
    <h3>Create Compound</h3>
    ...
  </div>     ← this closing tag
</div>       ← and this one

// Sub-agent migration (UNBALANCED)
<div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
  <Card padding="lg" className="max-w-md w-full">
    <h3>Create Compound</h3>
    ...
  </div>     ← STILL div, should be </Card>
</div>       ← OK
```

Fix: change the inner `</div>` to `</Card>`.

## Prevention

When dispatching a component migration to a sub-agent, include in the instructions:

> After each page: grep for `<Card` and `</Card` counts. Fix any mismatches before moving to the next page.

This shifts the detection burden to the sub-agent, reducing parent fix-up time.
