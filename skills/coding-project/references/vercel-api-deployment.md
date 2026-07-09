# Vercel API Deployment (No CLI)

Use this when the Vercel CLI is not available (Docker, Hermes WebUI, headless) but a `VERCEL_TOKEN` is present in the environment.

## Prerequisites

- `VERCEL_TOKEN` — Vercel authentication token (starts with `vcp_`)
- GitHub repo already pushed
- GitHub repo ID (get via: `GET /repos/{owner}/{repo}` on GitHub API)

### Verify the token works first

```python
import json, urllib.request
req = urllib.request.Request('https://api.vercel.com/v2/user')
req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
resp = urllib.request.urlopen(req, timeout=10)
user = json.loads(resp.read())['user']
print(f"User: {user['name']} ({user['email']})")
```

A 401/403 here means the token is invalid or expired. Get a fresh one.

### If the GitHub repo doesn't exist yet

The GitHub repo MUST exist before creating the Vercel project. Create it via API:

```python
import json, urllib.request
data = json.dumps({
    'name': 'repo-name',
    'description': 'description',
    'private': False
}).encode()
req = urllib.request.Request(
    'https://api.github.com/user/repos',
    data=data, method='POST')
req.add_header('Authorization', 'Bearer ' + GITHUB_TOKEN)
req.add_header('Accept', 'application/vnd.github.v3+json')
resp = urllib.request.urlopen(req, timeout=15)
repo = json.loads(resp.read())
print(f"Created: {repo['full_name']} (ID: {repo['id']})")
```

The `id` field from the response is the `repoId` needed for Vercel deployment.

**PITFALL — The repo may be under a different owner than expected:**
If the token belongs to `seunpayne` but the remote URL references `nous-hermes/chaingang-web`,
the repo will be created under the token owner's namespace, not the org. Check `curl -s -H
"Authorization: Bearer {token}" https://api.github.com/user` to confirm the token owner,
then update the remote URL accordingly.

## Workflow

### 1. Create the project

```python
import json, urllib.request

data = json.dumps({
    'name': 'project-name',
    'framework': 'nextjs',             # or 'nest', 'nuxt', etc.
    'gitRepository': {
        'repo': '{owner}/{repo}',
        'type': 'github'
    }
}).encode()

req = urllib.request.Request(
    'https://api.vercel.com/v10/projects',
    data=data, method='POST')
req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
req.add_header('Content-Type', 'application/json')
resp = urllib.request.urlopen(req, timeout=15)
project = json.loads(resp.read())
project_id = project['id']
```

### 2. Set environment variables

```python
for key, val in [
    ('NEXT_PUBLIC_SUPABASE_URL', supabase_url),
    ('NEXT_PUBLIC_SUPABASE_ANON_KEY', supabase_anon_key),
    ('SUPABASE_SERVICE_ROLE_KEY', supabase_secret),
]:
    data = json.dumps({
        'key': key,
        'value': val,
        'target': ['production', 'preview', 'development'],
        'type': 'encrypted'
    }).encode()
    req = urllib.request.Request(
        f'https://api.vercel.com/v9/projects/{project_id}/env',
        data=data, method='POST')
    req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
    req.add_header('Content-Type', 'application/json')
    urllib.request.urlopen(req, timeout=10)
```

### 3. Trigger a deployment

```python
data = json.dumps({
    'name': 'project-name',
    'gitSource': {
        'type': 'github',
        'repoId': GITHUB_REPO_ID,      # integer, required!
        'ref': 'main'
    }
}).encode()

req = urllib.request.Request(
    'https://api.vercel.com/v13/deployments',
    data=data, method='POST')
req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
resp = urllib.request.urlopen(req, timeout=30)
deployment = json.loads(resp.read())
url = deployment['url']                # e.g. project-xxx.vercel.app
```

### Check deployment status

```python
req = urllib.request.Request(
    'https://api.vercel.com/v13/deployments/get?url=' + url)
req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
resp = urllib.request.urlopen(req, timeout=10)
d = json.loads(resp.read())
state = d.get('readyState')           # 'INITIALIZING' | 'BUILDING' | 'READY'
aliases = d.get('alias', [])          # Production URLs
```

### List recent deployments for a project

```python
req = urllib.request.Request(
    'https://api.vercel.com/v6/deployments?projectId=' + project_id + '&limit=3')
req.add_header('Authorization', 'Bearer ' + VERCEL_TOKEN)
resp = urllib.request.urlopen(req, timeout=10)
d = json.loads(resp.read())
for dep in d.get('deployments', []):
    print(f"{dep['url']} | {dep.get('readyState')} | created: {dep.get('createdAt')}")
```

Note: The endpoint is `v6/deployments` with `?projectId=` query param, NOT
`/v9/projects/{id}/deployments` (which returns 404 for some project IDs).

## Pitfalls

### repoId is required, not optional
The `gitSource` object MUST include `repoId` (the GitHub integer repo ID). Passing `repo` alone returns:
```
"Invalid request: `gitSource` missing required property `repoId`."
```
Get it from `https://api.github.com/repos/{owner}/{name}` (public endpoint, no auth needed for public repos).

### Environment vars don't carry into first deployment
Env vars set after the project is created won't be available to the deployment that's already initializing. You must:
1. Create project
2. Set env vars  
3. Trigger a NEW deployment (step 3 above) — the vars will be picked up

### Re-deployment after env var change
If env vars change on an existing project, trigger a fresh deployment via step 3. The new vars will be injected at build time.

### 500 / MIDDLEWARE_INVOCATION_FAILED
This means the middleware code ran but crashed. Common causes:
- Supabase URL/anon key missing or wrong
- Database tables don't exist — middleware queries `user_roles` or similar table
- Fix: check env vars are set correctly, then check the Supabase schema exists

### Deployment alias assignment
Vercel automatically assigns aliases:
- `{project-name}.vercel.app` — latest production deployment  
- `{project-name}-git-{branch}-{owner}.vercel.app` — per-branch preview
- The production alias takes a few seconds to propagate after deployment is READY
