---
name: domain-manager
description: Manages custom domains for Vercel deployments. Handles domain purchase, DNS configuration, SSL verification, and domain health checks. Never purchases or removes domains without explicit approval.
---

# Domain Manager Skill

## Activation

**When activated:**
1. Gatekeeper pre-flight runs automatically
2. Check that Vercel CLI is installed and authenticated
3. Check that the active project has a production deployment URL in Supabase `deployments` table
4. Say: **"domain-manager loaded. What domain are we configuring?"**

---

## COMMAND 1 — Add a Custom Domain to a Project

**When a domain name is received:**

### Step 1: Check Domain Ownership
**Ask:** "Is this domain already purchased, or does it need to be registered?"

### Step 2A: If Domain Needs to be Purchased

1. **Check availability via Vercel:**
   ```bash
   vercel domains buy [domain]
   ```

2. **Display the purchase price and ask for explicit approval before buying**

3. **Never purchase a domain without APPROVE from Seun**

4. **Log the purchase cost to Supabase `billing_events` table**

5. **Log the domain decision to Supabase `decisions` table**

### Step 2B: If Domain is Already Owned

1. **Ask for confirmation of where DNS is currently managed:**
   - Vercel
   - Cloudflare
   - Namecheap
   - GoDaddy
   - Other

2. **Proceed to DNS Configuration**

### Step 3: DNS Configuration

1. **Add the domain to the Vercel project:**
   ```bash
   vercel domains add [domain] --project [project-name]
   ```

2. **Retrieve the DNS records Vercel requires:**
   ```bash
   vercel dns ls
   ```

3. **Display the exact DNS records the client or Seun needs to add:**
   - A record for root domain
   - CNAME record for www subdomain
   - Any additional verification records

4. **If DNS is managed on Vercel:** configure automatically

5. **If DNS is managed elsewhere:**
   - Display the records clearly
   - Say: **"Add these records at your DNS provider. Tell me when done and I will verify."**

### Step 4: Verification

1. **When Seun confirms DNS records are added:**
   ```bash
   vercel domains verify [domain]
   ```

2. **Poll for propagation every 5 minutes for up to 30 minutes**

3. **Confirm SSL certificate is provisioned automatically by Vercel**

4. **When verified:** Say: **"Domain [domain] is live and SSL is active."**

5. **Update Supabase `projects` table with the custom domain**

6. **Update Supabase `deployments` table with the new production URL**

7. **Log domain configuration as a decision in Supabase**

---

## COMMAND 2 — Check Domain Health

**When "check domain" is received:**

1. **Run `vercel domains inspect [domain]` for every domain in the active project**

2. **Check SSL certificate expiry date**

3. **Check DNS propagation status**

4. **Flag any domain where SSL expires within 30 days**

5. **Flag any domain with DNS misconfiguration**

6. **Report status for every domain across all active projects**

---

## COMMAND 3 — Remove a Domain

**When "remove domain" is received:**

1. **State which domain will be removed and confirm it is a destructive action**

2. **Wait for explicit APPROVE from Seun**

3. **Run:**
   ```bash
   vercel domains rm [domain]
   ```

4. **Update Supabase `projects` table to remove the domain**

5. **Log the removal as a decision in Supabase**

---

## COMMAND 4 — List All Domains

**When "list domains" is received:**

```sql
SELECT
 p.name as project_name,
 c.name as client_name,
 d.url as production_url,
 p.updated_at
FROM deployments d
JOIN projects p ON p.id = d.project_id
JOIN clients c ON c.id = p.client_id
WHERE d.environment = 'production'
ORDER BY c.name ASC;
```

**Display as a clean table with project, client, and domain.**

---

## Standing Rules

1. **Never purchase a domain without explicit APPROVE and cost confirmation from Seun**
2. **Never remove a domain without explicit APPROVE from Seun**
3. **Always verify SSL is active before marking a domain as configured**
4. **Always update Supabase after every domain change**
5. **Log every domain action as a decision in Supabase**

---

## Supabase Tables Used

- `projects` — Read/update production URL and domain
- `deployments` — Read/write deployment records with URLs
- `decisions` — Log domain configuration and removal decisions
- `billing_events` — Log domain purchase costs
- `clients` — Read client information

---

## Environment Variables

- `SUPABASE_URL` from `~/.env.openclaw`
- `SUPABASE_SECRET_KEY` from `~/.env.openclaw`
- `VERCEL_CLI_AUTH` (cli_managed) from `~/.env.openclaw`

---

## Error Handling

If domain verification fails:
1. Retry verification up to 6 times (5-minute intervals, 30 minutes total)
2. If still failing after 30 minutes: escalate to Seun with DNS propagation details
3. Do not mark domain as configured until SSL is confirmed active

If domain purchase fails:
1. Log error to `agent_runs`
2. Alert Seun immediately with error details
3. Do not retry without approval
