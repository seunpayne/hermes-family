# Credential Health Cron Job Pattern

When running credential checks as a scheduled cron job (no user present):

## Do NOT

- Return `[SILENT]` without actually verifying anything — the job should actively test credentials, not just say "I'll check"
- Only check that env vars are SET — verify they WORK via API calls
- Assume credentials are valid because they were valid last week — expired tokens are the most common failure mode
- Assume `.env` values are real tokens — they may be redacted (`***`) with actual values injected via Hermes credential pool at runtime

## DO

1. **Parse `.env` directly** — read it with `read_file` (not `source`) to avoid shell sourcing issues in cron context
2. **Detect redacted values** — if a key's value in `.env` is `***` or contains `...`, the actual token is managed by the Hermes credential pool. Cross-reference `~/.hermes/auth.json` → `credential_pool` section for the real stored token.
3. **Use `auth.json` health signals for pool-managed credentials** — `auth.json` records `last_status`, `last_error_code`, `last_error_message`, and `last_status_at` for each credential in the pool. These are valid health indicators even when the shell can't access the raw token. A `last_status: "exhausted"` with `last_error_code: 401` and `last_error_message: "User not found."` means the credential has been tested recently by the agent and failed.
4. **Test each credential with a lightweight API call** — one curl per service, HTTP 200 = valid. For keys whose actual value is obtainable from `.env` or `auth.json`, test directly. For fully runtime-injected keys (not even stored in `auth.json` with readable values), note the pool status and skip the curl test.
5. **Handle false negatives** — some endpoints look like failures but aren't:
   - Supabase `rest/v1/` root → 401 with anon keys (expected — test against a real table)
   - FAL AI GET → 405 Method Not Allowed (expected — must POST)
   - Supabase empty array `[]` with 200 → key works, just no RLS access to that table
4. **Report only if there are issues** — `[SILENT]` when all pass, full report when any fail
5. **Include the fix** in the report — tell Seun what to do (e.g., "generate a new token at https://...")

## Testing matrix

| Service | Method | Endpoint | Headers | Expected |
|---------|--------|----------|---------|----------|
| Supabase (anon) | GET | `$SUPABASE_URL/rest/v1/decisions?limit=1` | `apikey`, `Authorization: Bearer $SUPABASE_ANON_KEY` | 200 |
| Supabase (service) | GET | `$SUPABASE_URL/rest/v1/decisions?limit=1` | `apikey`, `Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY` | 200 + data |
| Vercel | GET | `https://api.vercel.com/v9/projects` | `Authorization: Bearer $VERCEL_TOKEN` | 200 |
| FAL AI | POST | `https://fal.run/fal-ai/flux-2-pro` | `Authorization: Key $FAL_KEY`, `Content-Type: application/json` | 200 + images |
| Resend | GET | `https://api.resend.com/emails` | `Authorization: Bearer $RESEND_API_KEY` | 200 |
| GitHub | GET | `https://api.github.com/user` | `Authorization: Bearer $GITHUB_TOKEN` | 200 OR 401 (expired) |
| gh CLI | shell | `gh auth status` | n/a | "logged in" message |
| DeepSeek | GET | `https://api.deepseek.com/v1/models` | `Authorization: Bearer $DEEPSEEK_API_KEY` | 200 |
| OpenRouter | GET | `https://openrouter.ai/api/v1/models` | `Authorization: Bearer $OPENROUTER_API_KEY` | 200 |
| Figma | GET | `https://api.figma.com/v1/me` | `Authorization: Bearer $FIGMA_ACCESS_TOKEN` (or `X-Figma-Token:` header) | 200 |
| Tavily | POST | `https://api.tavily.com/search` | `Content-Type: application/json` body includes `api_key` | 200 + results |
| Browser-use | — | Not testable via generic curl (endpoints are internal) | — | — |
