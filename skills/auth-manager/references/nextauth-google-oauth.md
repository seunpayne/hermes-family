# NextAuth Google OAuth Configuration

## Standard Setup Pattern

Used for Next.js projects with NextAuth.js and Google OAuth provider.

## Required Environment Variables

```bash
# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=<generate with: openssl rand -base64 32>

# Google OAuth
GOOGLE_CLIENT_ID=<client_id>.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-<secret>
```

## Google Cloud Console Configuration

### Step 1: Create Project
- Go to: https://console.cloud.google.com
- Create new project (e.g., "oryx-497107")
- Note the Project ID

### Step 2: Enable APIs
1. Google Drive API v3 (if Drive integration needed)
2. Google Drive Activity API v2 (if activity tracking needed)
3. Google+ API (for basic profile - usually auto-enabled)

### Step 3: OAuth Consent Screen
- User Type: **External** (unless Workspace only)
- App Name: [Project name]
- Support Email: your email
- Developer contact: your email

**Scopes** (minimum for auth):
- `openid`
- `email`
- `profile`

**Additional scopes** (as needed):
- `https://www.googleapis.com/auth/drive.readonly` (Drive file access)
- `https://www.googleapis.com/auth/drive.activity.readonly` (Activity tracking)

**Test Users**: Add your email for testing during verification wait period.

**IMPORTANT**: Submit for verification immediately after creation. Takes 7-10 business days. You can develop in Testing mode with up to 100 test users while waiting.

### Step 4: OAuth 2.0 Credentials
- Type: **Web application**
- Name: [Project name] OAuth

**Authorized JavaScript Origins**:
```
http://localhost:3000
https://staging.[domain].com
https://[domain].com
```

**Authorized Redirect URIs** (NextAuth pattern):
```
http://localhost:3000/api/auth/callback/google
https://staging.[domain].com/api/auth/callback/google
https://[domain].com/api/auth/callback/google
```

**Note**: The redirect URI must match exactly what NextAuth expects: `/api/auth/callback/[provider]`

### Step 5: Download Credentials
- Download JSON file
- Extract:
  - `client_id` → `GOOGLE_CLIENT_ID`
  - `client_secret` → `GOOGLE_CLIENT_SECRET`

## Common Errors

### redirect_uri_mismatch
**Cause**: Redirect URI in Google Console doesn't match NextAuth configuration.

**Fix**:
1. Check your NextAuth config for the exact callback path
2. Add that exact path to Google Console → Authorized redirect URIs
3. Wait 2-3 minutes for Google to propagate changes

### OAuth consent screen not published
**Cause**: App is in "Testing" mode and user is not in test users list.

**Fix**:
1. Add your email to Test Users in OAuth consent screen
2. OR publish the app (requires verification for External user type)

### Invalid scope
**Cause**: Requesting a scope not configured in consent screen.

**Fix**:
1. Add the scope to OAuth consent screen → Scopes
2. Save and wait for propagation
3. Re-run OAuth flow

## Security Notes

- **NEVER** commit `GOOGLE_CLIENT_SECRET` to git
- Add `.env.local` to `.gitignore`
- Use environment-specific redirect URIs (localhost, staging, production)
- Google OAuth credentials are project-specific — don't share across projects

## Task Sequencing Pattern

For projects requiring Google OAuth:

```
T-001: Google Cloud Console setup (credentials)
  ↓
T-002: Scaffold + environment setup (uses T-001 credentials)
  ↓
T-003: Additional services (Supabase, etc.) — can run in parallel
```

**T-001 deliverables**:
- `client_secret_*.json` file OR
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` values

**T-002 execution requires**:
- `GOOGLE_CLIENT_ID` ✓
- `GOOGLE_CLIENT_SECRET` ✓
- `NEXTAUTH_SECRET` (generate locally)
- Supabase credentials (if using Supabase auth)

## File Storage

Store OAuth credential JSON files in:
- `~/.hermes/cache/documents/` (temporary, session cache)
- `~/.hermes/credentials/[project-name]/` (permanent, secure)

**NEVER** store in:
- Project directory (risk of git commit)
- Shared folders
- Plain text notes

## Testing OAuth Flow

After setup, test with:

```bash
# Start dev server
npm run dev

# Visit
http://localhost:3000/api/auth/signin

# Click "Sign in with Google"
# Should redirect to Google → back to app
```

If successful, you'll see the callback URL in browser with `?code=` parameter.
