# Supabase + Google OAuth Configuration

## Redirect URI Format

When configuring Google OAuth for Supabase authentication, the **Authorized redirect URI** in Google Cloud Console MUST match this exact format:

```
https://[PROJECT_REF].supabase.co/auth/v1/callback
```

Where `[PROJECT_REF]` is your Supabase project reference (the first part of your project URL).

### Example

For project `https://tqacwivrwfsdsjdnxblp.supabase.co`:

**Correct redirect URI:**
```
https://tqacwivrwfsdsjdnxblp.supabase.co/auth/v1/callback
```

**Wrong (common mistakes):**
```
❌ http://localhost:5173/auth/callback
❌ https://myapp.com/auth/callback
❌ https://nukylczmqquhrwszpiei.supabase.co/auth/v1/callback  (old/wrong project)
❌ https://tqacwivrwfsdsjdnxblp.supabase.co/auth/v1/callback/  (trailing slash)
```

## Error: `redirect_uri_mismatch`

**Symptom:** Google shows "Error 400: redirect_uri_mismatch" when user clicks "Sign in with Google"

**Cause:** The redirect URI registered in Google Cloud Console does not match what Supabase is sending.

**Fix:**

1. Go to https://console.cloud.google.com/apis/credentials
2. Click your **OAuth 2.0 Client ID**
3. Under **Authorized redirect URIs**:
   - **Add** the correct Supabase callback URI (see format above)
   - **Remove** any old/incorrect URIs (especially from previous projects)
4. Click **Save**
5. Wait 2-5 minutes for Google to propagate changes
6. Test again

## Supabase Dashboard Configuration

In addition to Google Cloud Console, verify Supabase is configured:

1. Go to Supabase Dashboard → Your project
2. Navigate to **Authentication** → **Providers**
3. Enable **Google**
4. Paste:
   - **Client ID** (from Google Cloud Console)
   - **Client Secret** (from Google Cloud Console)
5. Click **Save**

## Finding Your Supabase Project Ref

If you don't know your project reference:

1. Go to Supabase Dashboard
2. Click your project
3. Look at the URL: `https://app.supabase.com/project/[PROJECT_REF]`
4. Or check `~/.hermes/.env`:
   ```bash
   grep SUPABASE_URL ~/.hermes/.env
   # Output: SUPABASE_URL=https://tqacwivrwfsdsjdnxblp.supabase.co
   # Project ref: tqacwivrwfsdsjdnxblp
   ```

## Multi-Environment Setup

If you have multiple environments (dev, staging, production) with different Supabase projects:

**Each environment needs its own Google OAuth client** with the correct redirect URI:

| Environment | Supabase Project | Redirect URI |
|-------------|-----------------|--------------|
| Development | `dev-project-ref` | `https://dev-project-ref.supabase.co/auth/v1/callback` |
| Staging | `staging-project-ref` | `https://staging-project-ref.supabase.co/auth/v1/callback` |
| Production | `prod-project-ref` | `https://prod-project-ref.supabase.co/auth/v1/callback` |

**Alternative:** Use a single Google OAuth client with **multiple redirect URIs** (all three listed above).

## Testing the Flow

After configuration:

1. Start your dev server
2. Navigate to `/auth` or trigger login
3. Click "Sign in with Google"
4. Should redirect to Google login → consent → back to your app's `/dashboard` (or post-login redirect)

If you see the Google login page but get an error after authentication, check:
- Supabase Provider is enabled and credentials are correct
- Your app's post-login redirect path exists and is accessible

## Credentials Storage

Store Google OAuth credentials in `~/.hermes/.env`:

```bash
# Google OAuth (for Supabase auth)
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxx
```

**Note:** Supabase stores these credentials server-side in their dashboard. The local env vars are for your application's reference or documentation.

---

**Session Reference:** Omayoza OAuth setup, 2026-05-19
**Error Resolved:** `redirect_uri_mismatch` after switching from Lovable's Supabase project to user's project
