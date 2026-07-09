# Deployment Plan Review

When Seun presents a deployment plan document for review, evaluate it as The Don against these dimensions:

## What to check

1. **Webhook URL accuracy** — Plan often says one thing, code implements another. Cross-reference every webhook URL in the plan against the actual controller routes in the codebase.
2. **Seed script availability** — If the plan references `npm run db:seed`, verify the script exists and is wired in package.json.
3. **Staging URLs defined** — Plan should have explicit staging subdomains, not just production.
4. **Environment table completeness** — Every env var from `.env.example` should be listed in the provisioning steps.
5. **Rollback triggers realistic** — 5 specific conditions that actually could happen, not generic "something breaks."
6. **Solo-ops assumption** — For launch, Seun is the sole operator. Plan should acknowledge this with realistic response times.
7. **CI pipeline existence** — Plan should reference CI workflow, not assume manual deploy verification.
8. **Consigliere integration** — Monitoring, cron, and alerting should be explicitly wired.

## Fix pattern

Issues fall into three categories:

| Type | Fix |
|------|-----|
| **Code gap** (no seed script, wrong webhook route) | Fix code, push to repo |
| **Document gap** (staging URL missing, env var table incomplete) | Write corrections doc to `docs/DEPLOYMENT_CORRECTIONS.md` |
| **Process gap** (rollback not defined, incident response missing) | The plan itself is the authoritative doc — Seun owns updates |

Write corrections as a markdown doc in `docs/` with before/after tables. Push to GitHub.
