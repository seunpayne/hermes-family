# API Response Security — Never Expose Internal Credentials

## Principle

API responses must NEVER return raw tokens, passwords, API keys, or internal identifiers to the client. The only exception is the initial credential generation flow (demo signup), and even then the credential should be delivered via the sandbox URL with the token embedded in the path — never displayed in the UI.

## Failure mode that triggered this reference

**Scenario:** Demo request API returned `accessToken` (hex string), `tempPassword` (hex string), and `sandboxUrl` (relative path) in the response. The frontend rendered all three in a success card:
- "Access Token: a3f8c2..." → exposed to prospect
- "Password: 64ea73c2258830d3" → exposed to prospect  
- "Enter Sandbox" button → linked to `/sandbox` with no token param

**Problems:**
1. Raw credentials visible in browser — anyone shoulder-surfing can see the password
2. Credentials persisted in frontend state (React state = accessible via DevTools)
3. Relative URL (`/sandbox?token=...`) broke when the frontend used `<Link href="/sandbox">` without the token

## Rules

1. **Never return `accessToken`, `tempPassword`, or any secret in a JSON response that reaches the browser.** These values go in the URL query string (for token-based flows) or are emailed to the user. Never in the JSON body.

2. **Always return a full absolute URL** when the frontend needs to navigate to a page with parameters. Relative paths (`/sandbox?token=xxx`) require the frontend to know the origin, which it may not. Use:
   ```typescript
   // Backend
   sandboxUrl: `${configService.get('FRONTEND_URL')}/sandbox?token=${token}`
   
   // Frontend fallback (when backend URL is relative)
   if (result.sandboxUrl && !result.sandboxUrl.startsWith('http')) {
     result.sandboxUrl = `${window.location.origin}${result.sandboxUrl}`;
   }
   ```

3. **The API response shape must NEVER include fields named `accessToken` or `password`** unless the endpoint is specifically designed to generate and return new credentials (and even then, deliver via URL or email, not JSON body).

4. **For "already exists" responses** (user submits the same email twice), return only:
   ```typescript
   {
     message: 'Your access is still active.',
     sandboxUrl: `${FRONTEND_URL}/sandbox?token=${existing.accessToken}`,  // Full URL
     expiresAt: existing.expiresAt.toISOString(),
     alreadyExists: true
   }
   ```
   Never return the raw `accessToken` or `tempPassword` again.

5. **Frontend success state** should show:
   - A checkmark/confirmation icon
   - A brief message
   - A single action button that navigates to the full URL (from the API response)
   - No raw codes, no copy-to-clipboard fields, no "your password is X" text

## Audit pattern

When reviewing an API endpoint that creates or retrieves credentials:
- [ ] Does the response include `accessToken`, `token`, `password`, `secret`, or similar?
- [ ] If yes, is this endpoint consumed by a browser or just server-side?
- [ ] If consumed by browser, is there a way to avoid exposing the credential in the response body?
- [ ] Is the redirect/navigation URL absolute or relative?
- [ ] Can the credential be extracted from the browser's React DevTools state?
