# Cloud Commander Security Hardening

Cloud Commander (`coderaiser/cloudcmd`) is a web-based file manager with
terminal access. When deployed without authentication, it exposes the full
filesystem (default root: `/`).

## Detection

Cloud Commander typically runs on port 8000 inside the container, mapped to
a host port (commonly 8084). The HTML response contains `cloudcmd` in CSS/JS
paths: `/dist/cloudcmd.common.css`.

## Enabling Auth via REST API

Cloud Commander has a REST config endpoint at `/api/v1/config`. The config
can be read and written without authentication when auth is disabled (boot
order problem), making it possible to lock the door from inside.

### Step 1: Read current config

```bash
curl -s "http://<host>:<port>/api/v1/config"
```

Key fields: `auth` (bool), `username` (string), `password` (hashed).

### Step 2: Enable auth with a known password

```bash
curl -s -X PATCH "http://<host>:<port>/api/v1/config" \
  -H "Content-Type: application/json" \
  -d '{"auth": true, "username": "admin", "password": "<your-password>"}'
```

Use **PATCH** (not POST or PUT). PATCH is the only method Cloud Commander
accepts for partial config updates.

### Step 3: Verify

```bash
# Without auth — should return 401
curl -s -o /dev/null -w "%{http_code}" "http://<host>:<port>/api/v1/config"

# With auth — should return 200 + config
curl -s -u "admin:<your-password>" "http://<host>:<port>/api/v1/config"
```

### Step 4: Make permanent (Docker)

The API change is in-memory and resets on container restart. To persist:

```bash
docker stop cloudcmd 2>/dev/null; docker rm cloudcmd 2>/dev/null
docker run -d --name cloudcmd --restart unless-stopped \
  -p <host-port>:8000 \
  -e CLOUDCMD_USERNAME=admin \
  -e CLOUDCMD_PASSWORD=<your-password> \
  -e CLOUDCMD_AUTH=*** \
  coderaiser/cloudcmd
```

## Host Filesystem Access (Docker Volume Mount)

Cloud Commander inside a Docker container only sees the container's internal
filesystem by default. To browse and edit the **host server's filesystem**,
mount the host root into the container:

```bash
docker stop cloudcmd 2>/dev/null; docker rm cloudcmd 2>/dev/null
docker run -d --name cloudcmd --restart unless-stopped \
  -p <host-port>:8000 \
  --user 0 \
  -v /:/host \
  coderaiser/cloudcmd
```

**Key flags:**
- `--user 0` — Runs as root inside the container. Required because the host
  filesystem's permissions don't match the container's default user (`node`,
  usually UID 1000). Without this, `/host/home` returns empty even though
  files exist.
- `-v /:/host` — Mounts the host's root at `/host` inside the container.
  **No `:ro`** suffix — `:ro` makes the mount read-only, which defeats the
  purpose of a file manager for users who need full write access. If the
  user asks why they can't write, this is why.
- `-e CLOUDCMD_ROOT=/host` — Sets the default root directory. Without this
  env var, you must PATCH the config after the container starts.

### Post-Start Config

After the container is running with `-v /:/host`, set the root and auth:

```bash
curl -s -X PATCH "http://<host>:<port>/api/v1/config" \
  -H "Content-Type: application/json" \
  -d '{"auth": true, "root": "/host", "username": "admin", "password": "<password>"}'
```

Verify the host filesystem is visible:
```bash
# Should show actual host users (hermeswebui, root, etc.)
curl -s -u "admin:<password>" "http://<host>:<port>/api/v1/fs/host/home"
```

## Pitfalls

- **Send a plaintext password, not a hash.** Cloud Commander hashes it with
  SHA-512 before storing. If you send a pre-hashed string, it gets double-
  hashed and you won't be able to log in.
- **PATCH, not POST.** POST to `/api/v1/config` hangs/times out. Only PATCH
  works for updating individual fields.
- **HTTP, not HTTPS.** Cloud Commander typically runs without TLS (handled
  by a reverse proxy). Test with `http://`, not `https://`.
- **Auth changes are in-memory.** The password change takes effect
  immediately but doesn't persist across container restarts unless the
  Docker env vars are set.
- **Password recovery is impossible** if you change the password via API
  and don't save it. The hash is one-way. Always save the password to
  `.env` under `CLOUDCMD_PASSWORD`.
- **`:ro` kills file manager utility.** If the user says "what's the point
  of a file manager if it's read-only?", remove the `:ro` flag from the
  volume mount and add `--user 0`.
- **Every path returns 22 items when the mount is wrong.** If every
  directory listing returns the same 22-item root (bin, boot, dev, etc, …),
  the volume mount isn't working. Verify with `docker inspect cloudcmd | grep
  Mounts` on the host, or try writing a test file to confirm write access.
  Cloud Commander falls back to root when a path doesn't exist.
