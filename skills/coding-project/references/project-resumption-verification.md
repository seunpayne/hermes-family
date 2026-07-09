# Project Resumption Protocol

**When:** Resuming work on an existing coding project where documentation may lag reality.

**Problem:** PRD.md, FEATURES.md, and task checklists often show "Not started" or incomplete status when files have already been created in previous sessions. Relying on documentation alone leads to incorrect status reports and wasted effort re-checking what already exists.

---

## VERIFICATION SEQUENCE

### Step 1: Search for actual files

```bash
# Find all React pages
search_files(path=project_src/app, pattern="page.tsx", target="files")

# Find all TypeScript modules  
search_files(path=project_src/lib, pattern="*.ts", target="files")

# Find all API routes
search_files(path=project_src/app/api, pattern="route.ts", target="files")
```

### Step 2: Read discovered files

Use the **exact absolute paths** returned by `search_files`:

```
/Users/seunpayne/Projects/clients/oryx-v1/src/app/dashboard/page.tsx
/Users/seunpayne/Projects/clients/oryx-v1/src/lib/auth.ts
```

**DO NOT** reconstruct paths with `~` or relative segments — use paths exactly as returned.

### Step 3: Compare against documentation

| Documentation says | Filesystem shows | Report as |
|-------------------|------------------|-----------|
| "Not started" | File exists with content | ✅ Complete (or % based on content) |
| "In progress" | File exists, stub content | 🟡 Partial |
| "Complete" | File missing | ❌ Not done |
| "Complete" | File exists, empty | ❌ Stub only |

### Step 4: Report real state

**Bad report:**
> "Dashboard page is not found. Needs to be created."

**Good report:**
> "Dashboard page EXISTS at [absolute path]. File is 179 lines, fully implemented with:
> - Document list UI
> - Google Drive API integration via /api/documents
> - Auth session handling
> - Error states and loading states
> 
> PRD.md Section 2.2 shows this as 'Not started' — documentation is outdated."

---

## COMMON DISCOVERIES

| Pattern | What it means |
|---------|---------------|
| `page.tsx` exists but empty (0 lines) | Stub created, work not done |
| `route.ts` exists with full implementation | API complete, may just need testing |
| `lib/auth.ts` exists but `middleware.ts` missing | Auth backend done, protected routes not wired |
| Multiple `page.tsx` files in different directories | Feature lanes progressed in parallel |
| `package.json` has scripts but `node_modules` missing | Dependencies need reinstall |

---

## PATH RESOLUTION RULE

When `read_file` fails with "File not found" but `search_files` shows the file exists:

**Wrong:**
```
read_file(path="~/Projects/clients/oryx-v1/src/lib/auth.ts")
read_file(path="src/lib/auth.ts")
```

**Right:**
```
read_file(path="/Users/seunpayne/Projects/clients/oryx-v1/src/lib/auth.ts")
```

The search results contain the exact absolute path. Use it directly.

---

## SESSION CONTEXT

This reference was created during Oryx V1 resumption on 2026-05-24.

**What happened:**
- PRD.md and FEATURES.md showed T-010 (Auth) as "Partial — backend missing"
- `search_files` revealed: `auth.ts`, `route.ts`, `dashboard/page.tsx`, `documents/route.ts` all existed
- Actual state: T-010 was 90% complete, T-011 was 100% complete
- Documentation had not been updated after previous session's work

**Lesson:** Always verify filesystem before reporting status. Trust code, not docs.
