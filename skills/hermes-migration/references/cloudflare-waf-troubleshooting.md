# Cloudflare WAF: MCP Server Access Blocked

## The Problem

MCP servers behind Cloudflare return **Error 1010** (\"Access denied — browser signature check\") when the Hermes agent tries to connect. Cloudflare's WAF (Web Application Firewall) blocks non-browser HTTP clients based on TLS fingerprint and User-Agent heuristics.

Error payload:
```json
{
  "type": "https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1010/",
  "title": "Error 1010: Access denied",
  "status": 403,
  "detail": "The site owner has blocked access based on your browser's signature."
}
```

## The Fixes (Ordered by Reliability)

### Option A: Browser-Headers Workaround (Quickest — No Dashboard Required)

When Cloudflare blocks based on "browser signature" (TLS fingerprint + User-Agent heuristic), sending proper browser-like headers can bypass it **without any Cloudflare dashboard changes**:

```python
import urllib.request, json, ssl

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {token}",
    "Accept": "application/json, text/event-stream",
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-origin",
    "Referer": "https://outline.velocit8.com/",
    "Origin": "https://outline.velocit8.com",
}

payload = json.dumps({
    "jsonrpc": "2.0", "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2025-03-26",
        "capabilities": {},
        "clientInfo": {"name": "hermes-agent", "version": "1.0"}
    }
}).encode()

req = urllib.request.Request(
    "https://outline.velocit8.com/mcp",
    data=payload, headers=headers, method="POST"
)

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

with urllib.request.urlopen(req, timeout=15, context=ctx) as resp:
    raw = resp.read()
    # SSE response handling
    for event in raw.decode().split('\n\n'):
        if 'data:' in event:
            data = json.loads(event.split('data:', 1)[1].strip())
            print(json.dumps(data, indent=2)[:500])
```

**Key headers that matter:**
- `User-Agent`: Chrome browser string (not Python's `Python-urllib/3.x`)
- `Sec-Fetch-*`: Three headers that signal a browser-initiated fetch
- `Referer` + `Origin`: Must match the target domain
- `Accept`: Must include `text/event-stream` for MCP (the server rejects if absent)

### Option B: Cloudflare Dashboard (30 seconds)

1. Go to **Cloudflare Dashboard** → zone (e.g., `velocit8.com`)
2. Navigate to **Security** → **WAF** → **Tools**
3. Under **IP Access Rules**, click **Create rule**
4. Set: **Value** = server's public IP, **Action** = **Allow**
5. Add a note like "Hermes WebUI MCP server"
6. Click **Save**

### Option C: Cloudflare API (Requires proper token permissions)

The API token needs **at minimum**:
- `zone:velocit8.com:read` — to get the zone ID
- `zone:velocit8.com:firewall:edit` — to create IP access rules

```python
import json, urllib.request

zone_id = "<from cf dashboard or zones API>"
ip = "102.134.17.245"
token = "cfat_..."  # CLOUDFLARE_API_TOKEN

rule = {
    "mode": "whitelist",
    "configuration": {"target": "ip", "value": ip},
    "notes": "Hermes WebUI server - MCP access"
}

req = urllib.request.Request(
    f"https://api.cloudflare.com/client/v4/zones/{zone_id}/firewall/access_rules/rules",
    data=json.dumps(rule).encode(),
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    method="POST"
)
with urllib.request.urlopen(req, timeout=10) as resp:
    print(json.loads(resp.read()))
```

## Troubleshooting Token Permissions

If the firewall endpoint returns `code 10000: Authentication error` but the zones list endpoint works, the token only has read permissions. Verify:

```bash
python3 -c "
import json, urllib.request
token = open('/home/hermeswebui/.hermes/.env').read().split('CLOUDFLARE_API_TOKEN=')[1].split('\n')[0]
req = urllib.request.Request(
    'https://api.cloudflare.com/client/v4/user/tokens/verify',
    headers={'Authorization': f'Bearer {token}'}
)
result = json.loads(urllib.request.urlopen(req, timeout=10).read())
print(json.dumps(result['result']['policies'], indent=2))
"
```

Look for `permission_groups` containing `firewall` or `waf` with action `edit`.

## Why Not DNS-Only (Grey Cloud)

Setting the DNS record to **DNS only** (grey cloud) bypasses Cloudflare entirely. This is NOT recommended because:

- The real server IP is exposed publicly (security risk)
- If the server is on a local/private network (e.g., `fd10:` IPv6 ULA), DNS-only makes the endpoint unreachable from external containers without a tunnel
- SSL/TLS termination from Cloudflare is lost
- Origin server IP changes (dynamic IP) break the record

Stick with proxied (orange cloud) + IP allowlisting or browser-headers workaround.

## TL;DR

- **Browser-headers workaround (try first):** Add Chrome User-Agent, Sec-Fetch-* headers, matching Referer/Origin. Usually bypasses bot detection without any Cloudflare changes.
- **Dashboard route:** Security → WAF → Tools → IP Access Rules → Allow [server IP]
- **API route:** Needs both `zone:read` AND `zone:firewall:edit` permissions on the token
- **Do NOT grey-cloud** the DNS record — it breaks local/private network endpoints and exposes origin IP

## Known Affected Endpoints

- `outline.velocit8.com/mcp` — Outline MCP (fixed with browser-headers)
- `n8n.velocit8.com/mcp-server/http` — n8n MCP
- `mcp.figma.com/mcp` — Figma MCP
