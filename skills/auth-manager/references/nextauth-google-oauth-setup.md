# NextAuth.js + Google OAuth + Supabase Setup Pattern

**Session:** 2026-05-22 — Oryx V1 T-010 (Authentication)

---

## Task Sequence

**T-001:** Google Cloud OAuth credentials  
**T-002:** Scaffold + environment setup  
**T-003:** Supabase migration  
**T-010:** NextAuth.js integration (this reference)

---

## Required Packages

```bash
npm install next-auth @auth/supabase-adapter --legacy-peer-deps
```

**Note:** `--legacy-peer-deps` is required due to `@auth/core` version mismatch between `next-auth@4.24.x` and `@auth/supabase-adapter`. This is a known issue and safe to bypass.

---

## File Structure

```
src/
├── app/
│   ├── signin/
│   │   └── page.tsx          # Sign-in UI
│   ├── layout.tsx            # Root layout (required for app router)
│   └── globals.css           # Tailwind imports
├── pages/
│   └── api/
│       └── auth/
│           └── [...nextauth].ts  # NextAuth API route
└── types/
    └── next-auth.d.ts        # TypeScript type extensions
```

---

## NextAuth Configuration (`[...nextauth].ts`)

```typescript
import NextAuth, { NextAuthOptions } from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'
import { SupabaseAdapter } from '@auth/supabase-adapter'

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          scope: [
            'openid',
            'email',
            'profile',
            'https://www.googleapis.com/auth/drive.readonly',
            'https://www.googleapis.com/auth/drive.activity.readonly',
          ].join(' '),
        },
      },
    }),
  ],
  adapter: SupabaseAdapter({
    url: process.env.NEXT_PUBLIC_SUPABASE_URL!,
    secret: process.env.SUPABASE_SERVICE_ROLE_KEY!,
  }),
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  pages: {
    signIn: '/signin',
    signOut: '/signin',
  },
  callbacks: {
    async jwt({ token, account, profile }) {
      if (account) {
        token.accessToken = account.access_token
        token.googleId = profile?.sub
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken as string
      session.user.googleId = token.googleId as string
      return session
    },
  },
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
```

---

## TypeScript Type Extensions (`next-auth.d.ts`)

```typescript
import 'next-auth'
import 'next-auth/jwt'

declare module 'next-auth' {
  interface Session {
    accessToken?: string
    user: {
      name?: string | null
      email?: string | null
      image?: string | null
      googleId?: string
    }
  }

  interface User {
    googleId?: string
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    accessToken?: string
    googleId?: string
  }
}
```

---

## Environment Variables (Vercel)

Set these via Vercel CLI or dashboard:

```bash
NEXTAUTH_URL=https://oryx-v1.vercel.app
GOOGLE_CLIENT_ID=<from Google Cloud Console>
GOOGLE_CLIENT_SECRET=<from Google Cloud Console>
SUPABASE_SERVICE_ROLE_KEY=<from Supabase API settings>
```

**Local development:** Use `.env.local` with `NEXTAUTH_URL=http://localhost:3000`

---

## Google Cloud Console Setup

### Required Scopes

For Drive document proof generation:

```
openid
email
profile
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/drive.activity.readonly
```

### OAuth Consent Screen

- **User Type:** External
- **App Name:** Oryx
- **Support Email:** Your email
- **Test Users:** Add your email during development (app is in "Testing" mode until verified)

### Authorized Redirect URIs

```
http://localhost:3000/api/auth/callback/google
https://staging.projectoryx.com/api/auth/callback/google
https://projectoryx.com/api/auth/callback/google
https://oryx-v1.vercel.app/api/auth/callback/google
```

---

## Supabase Schema Requirements

The Supabase adapter requires these tables (auto-created by adapter, or run manually):

```sql
-- Users table (for session management)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  google_id text UNIQUE,
  email text UNIQUE NOT NULL,
  name text,
  image text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Accounts table (OAuth linkage)
CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  type text NOT NULL,
  provider text NOT NULL,
  provider_account_id text NOT NULL,
  access_token text,
  refresh_token text,
  expires_at bigint,
  token_type text,
  scope text,
  id_token text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(provider, provider_account_id)
);

-- Sessions table (JWT not used, but adapter requires)
CREATE TABLE IF NOT EXISTS sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_token text UNIQUE NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Verification tokens (optional, for email verification)
CREATE TABLE IF NOT EXISTS verification_tokens (
  identifier text NOT NULL,
  token text UNIQUE NOT NULL,
  expires_at timestamptz NOT NULL,
  PRIMARY KEY(identifier, token)
);
```

**Note:** The Oryx project uses custom `users` and `proofs` tables (from T-003 migration). The adapter tables (`accounts`, `sessions`, `verification_tokens`) are separate and auto-created by the adapter on first sign-in.

---

## Common Errors

### 1. `@auth/supabase-adapter` not found

```bash
npm install @auth/supabase-adapter --legacy-peer-deps
```

### 2. Peer dependency conflicts

```bash
npm install --legacy-peer-deps
```

Add `.npmrc` with `legacy-peer-deps=true` to persist.

### 3. TypeScript errors in `node_modules`

Errors like:
- `Module '"../../types.js"' has no exported member 'RequestInternal'`
- `Private identifiers are only available when targeting ECMAScript 2015`

**These are in library type definitions, not your code.** Next.js build skips type checking in `node_modules`. Ignore unless your own code has errors.

### 4. `signin/page.tsx doesn't have a root layout`

Create `src/app/layout.tsx`:

```typescript
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Oryx — Document Work Proof',
  description: 'Generate verifiable work proofs from your Google Drive documents',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
```

### 5. `redirect_uri_mismatch`

Ensure the exact callback URL is registered in Google Cloud Console:
- Include protocol (`https://`)
- Include full path (`/api/auth/callback/google`)
- Match subdomain exactly (e.g., `oryx-v1.vercel.app` not `vercel.app`)

---

## Testing Flow

1. Deploy to Vercel with environment variables set
2. Visit `/signin` page
3. Click "Sign in with Google"
4. Authorize OAuth scopes
5. Redirect to `/dashboard` (or configured `callbackUrl`)
6. Check Supabase `users` and `accounts` tables for new records

---

## Security Notes

- **NEVER** commit `.env.local` or `.env.production` to git
- **ALWAYS** use `SUPABASE_SERVICE_ROLE_KEY` server-side only (never expose to client)
- **JWT strategy** recommended over database sessions for Next.js app router
- **30-day session expiry** is standard; adjust `maxAge` as needed

---

## Vercel Environment Variable Setup

Use CLI (recommended over dashboard for scripting):

```bash
cd ~/Projects/clients/oryx-v1
echo "value" | vercel env add VARIABLE_NAME production --yes
```

Variables to set:
- `NEXTAUTH_URL` (production URL)
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `SUPABASE_SERVICE_ROLE_KEY`

Then redeploy:
```bash
vercel --prod --yes
```
