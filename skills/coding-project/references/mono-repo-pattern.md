# Mono-Repo Pattern — Backend + Frontend Side-by-Side

## When to use
- Full-stack web application with separate API (NestJS) and UI (Next.js)
- Same GitHub repo, independent build pipelines
- Each directory has its own `package.json`, `tsconfig`, build script
- Shared root `.gitignore` and project docs at root level

## Directory structure
```
project-root/
├── .gitignore          # Combined: node_modules, dist, .next, .env, *.log
├── docs/               # Shared project docs (copy reference, etc.)
├── design-visual-spec.md  # Apollonia's design spec (root level)
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── prisma/
│   ├── src/
│   ├── test/
│   ├── .env.example
│   └── Procfile / vercel.json
├── frontend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts
│   ├── src/app/
│   ├── src/components/
│   └── public/
```

## Key decisions

### Shared root `.gitignore`
A single `.gitignore` at root covers both directories:
```
node_modules/
dist/
.next/
.env
.env.local
.env.production
*.log
.DS_Store
coverage/
uploads/
```
Each subdirectory CAN have its OWN `.gitignore` for subdirectory-specific
exclusions, but the root one catches everything.

### Build independence
Each directory builds independently with its own commands:
```bash
cd backend && npm run build
cd frontend && npm run build
```
CI pipeline (GitHub Actions) should add a matrix or separate jobs for each.

### Environment isolation
Each service has its own `.env.example`:
- `backend/.env.example` — DATABASE_URL, JWT_SECRET, PAYSTACK_*, REDIS_URL
- Frontend uses Next.js `NEXT_PUBLIC_*` vars or runtime config

Never share `.env` files between directories.

### Deployment independence
- **Backend (NestJS):** Railway via Procfile, or Vercel via `vercel.json`
- **Frontend (Next.js):** Vercel natively

Or both on Railway with separate services.

## Pitfalls
- **Shared API client:** The frontend `src/lib/api.ts` hardcodes `localhost:3001`
  (or whatever the backend port is). In production this must point to the
  deployed API URL, not localhost. Use `NEXT_PUBLIC_API_URL` env var.
- **CORS:** The backend must enable CORS (in `main.ts`) for the frontend's
  deployed origin. In dev, this is often `*`; in production, lock it down.
- **Build timing:** The frontend doesn't depend on the backend at build time
  (API calls are client-side). This means both can build independently and
  deploy on different schedules.
- **Import paths across directories:** Never import from `backend/` into
  `frontend/` or vice versa at build time. The API client is the only
  contract between them.
