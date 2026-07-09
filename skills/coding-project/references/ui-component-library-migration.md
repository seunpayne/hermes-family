# UI Component Library Incremental Migration

## When to use
Adopting a new UI component library (8+ components) across 37+ pages without breaking existing pages.

## Pattern

### Phase 1: Merge CSS, don't replace
- Read both existing and new globals.css
- Extract ONLY new animations and utility classes from the new file
- Append to existing file — do NOT remove any existing styles
- If naming conflicts exist, keep the existing class name
- Verify with `npm run build`

### Phase 2: Install components with conflict awareness
- Copy new components to `components/ui/`
- If a component name conflicts with existing (e.g., StatusBadge), install as V2: `StatusBadgeV2.tsx`
- Do NOT delete old components — maintain backward compat
- Import new components with `import Button from '@/components/ui/Button'`
- Verify build after each component addition

### Phase 3: Migrate incrementally by surface
Order: Guard → Resident → Admin → Ops → Marketing
- Replace inline `<button className="bg-[#1B4332]...">` with `<Button variant="primary">`
- Replace inline `<input placeholder="..." className="...">` with `<Input placeholder="..." />`
- Replace inline `<div className="bg-white border...">` with `<Card padding="md">`
- Migrate one page at a time, build after each
- Commit after each surface is complete

## JSX Balance Check Pattern
After every sub-agent migration, run this batch check across ALL changed pages:
```bash
for f in $(git diff --name-only | grep '\.tsx$'); do
  opens=$(grep -c '<Card' "$f" 2>/dev/null || echo 0)
  closes=$(grep -c '</Card' "$f" 2>/dev/null || echo 0)
  if [ "$opens" != "$closes" ]; then
    echo "JSX BALANCE: $f — $opens <Card> vs $closes </Card>"
    grep -n '<Card\|</Card' "$f"
  fi
done
```
If counts don't match, each unclosed `<Card>` was originally a `<div>` whose `</div>` closer wasn't changed to `</Card>`. Find and fix each one before building.

Common failure patterns:
| Pattern | How it manifests | Fix |
|---------|-----------------|-----|
| Modal wrapper | `<div className="fixed inset-0..."><Card>` opens but `</div></div>` closes | Change middle `</div>` to `</Card>` |
| Page content | `<Card>` replaces outer `<div>` but trailing `</div>` doesn't change | Replace first trailing `</div>` with `</Card>`, remove extra |
| Conditional | `{cond && (<Card>)}` — closing brace before `</Card>` | Check for `)}</div>` → `)}</Card>` |

## Known Pitfalls
1. **Sub-agent JSX corruption** — delegate_task migration of pages consistently produces unbalanced Card/div tags. Always run the grep count check after.
2. **Card in modals** — the fixed overlay div container should NOT be converted to Card. Only the inner content wrapper.
3. **Tailwind v4 compatibility** — the new component library may reference v4 utility classes. Verify the project's Tailwind version first.
4. **Sub-agent timeout** — page migration sub-agents consistently time out at 600s. Check `git status` after timeout to see what was completed, then continue manually.
