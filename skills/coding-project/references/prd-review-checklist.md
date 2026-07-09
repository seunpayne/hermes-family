# PRD Review Checklist — Michael's Blindspot Analysis

## Purpose
Run this checklist when Michael reviews a PRD for blindspots before Phase 2 (Architecture Review). The goal is not to rewrite the PRD but to identify gaps that would be cheaper to fix now than during build.

## Categories

### 1. Member Flow Completeness
- [ ] Authentication exists — but does **registration**?
- [ ] If registration exists: is it self-service, invite-only, or admin-only?
- [ ] Is the onboarding path documented? (visitor → interested → member → logged in)
- [ ] Is the account recovery / password reset flow defined?

Signal: PRD says "member logs in" but never says how they became a member.

### 2. Communication Channel Alignment
- [ ] Where does the user community actually communicate? (WhatsApp, Telegram, Slack, email?)
- [ ] Does the platform publish content that won't be seen because members don't visit the site daily?
- [ ] Is there a push notification path (WhatsApp, email, SMS) for urgent content?
- [ ] If not: is the absence documented as a known limitation?

Signal: PRD assumes members will visit the site to see announcements, but the club lives on WhatsApp.

### 3. Token & Credential Lifecycle
- [ ] Third-party API tokens (Instagram, Strava, Google): how do they refresh?
- [ ] Is auto-refresh built-in, manual-only, or undocumented?
- [ ] What happens when a token expires? Graceful fallback or broken widget?
- [ ] Who gets notified when a refresh fails?
- [ ] For manual refresh: is the process documented and is someone responsible?

Signal: "Calendar reminder" or "admin manually updates" for recurring token maintenance.

### 4. Admin Role & Access Management
- [ ] How are admins created? (Supabase dashboard? GUI panel? SQL?)
- [ ] Is the role stored in user_metadata (client-mutable) or a dedicated table?
- [ ] Can a non-technical admin manage other admins without touching Supabase?
- [ ] What happens when the last admin leaves the project?

Signal: PRD says "admin role" without specifying the mechanism. Check for user_metadata usage.

### 5. Storage & Cost Growth Model
- [ ] User-generated content (photos, files): what's the monthly growth rate?
- [ ] How long until free tier limits are hit? (Supabase 1GB, Vercel 100GB bandwidth, etc.)
- [ ] What happens at the limit? (automatic upgrade? feature break? graceful degradation?)
- [ ] Is there a retention/deletion policy for old content?

Signal: PRD says "admin uploads photos" without estimating monthly storage consumption.

### 6. Security Surface
- [ ] Rich text editors (Tiptap, Quill, etc.): is HTML output sanitized?
- [ ] File uploads: are there size limits, type restrictions, or virus scanning?
- [ ] API endpoints that create/update data: are they protected?
- [ ] Any public endpoints that could be abused (contact forms, webhooks)?
- [ ] Are secrets/tokens stored in env vars only, never in the DB?

Signal: PRD mentions a rich text editor without XSS protection.

### 7. Observability & Alerting
- [ ] When a background job fails (cron sync, webhook handler), who knows?
- [ ] Is there a health endpoint?
- [ ] Is there uptime monitoring?
- [ ] Is there a runbook for common failure modes?
- [ ] Who owns the monitoring setup?

Signal: No health endpoint, no monitoring, no failure notification path.

### 8. Platform Limits Awareness
- [ ] Vercel Hobby: 60 builds/day, 100GB bandwidth, 6K build minutes — sufficient?
- [ ] Supabase Free: 500MB DB, 1GB Storage, 50MB file upload — sufficient for first 6 months?
- [ ] Strava API: 100 req/15min, 1000/day, 200-activity cap — documented?
- [ ] Third-party rate limits documented and mitigated?

Signal: No mention of platform free-tier limits or what happens when they're exceeded.

### 9. SEO & Discovery (if public-facing)
- [ ] Is the primary persona finding the site via search?
- [ ] Structured data (schema.org) for the organization?
- [ ] Open Graph / Twitter Card images for shared content?
- [ ] XML sitemap and robots.txt?
- [ ] Per-page meta descriptions?

Signal: PRD's primary persona is "prospective member" but no SEO strategy documented.

### 10. Test Strategy Practicality
- [ ] Who writes the tests? Who runs them?
- [ ] For volunteer-run projects: is Playwright E2E realistic, or would manual test scripts be better?
- [ ] Is there test infrastructure (test users, seeded data, CI runner)?
- [ ] What's the escape hatch if E2E tests block a non-critical feature?

Signal: PRD requires full automated E2E coverage for a personal/volunteer project.

## Usage Pattern

1. Run through all 10 categories for every PRD
2. For each category with an issue: classify as Critical / High / Medium / Low
3. Three possible dispositions:
   - **Fix in PRD** — Amend the document before build starts
   - **Accept as caveat** — Document the gap as a known limitation with a risk entry
   - **Defer** — Not applicable or out of scope for this project
4. Present findings to Seun as a structured table:

```
| # | Issue | Severity | Disposition |
|---|-------|----------|-------------|
| 1 | No member registration flow | Critical | Fix: add Story 8 |
| 3 | Instagram token auto-refresh | High | Accept: P1 scope, R-03 updated |
```

## Output
A review document (addendum or comment block) attached to the PRD. The review itself is READ-ONLY — Michael never modifies the PRD directly. Clemenza receives the PRD + review as context at build time.
