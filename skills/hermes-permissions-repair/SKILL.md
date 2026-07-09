---
name: hermes-permissions-repair
title: Hermes Permissions Repair
description: Diagnose and fix filesystem permission issues on Hermes directories — particularly skills/ — inside containerized/Docker environments where sudo, docker, and CAP_CHOWN are unavailable.
---

# Hermes Permissions Repair

Fix Hermes directories that are locked by UID mismatches from Docker volume mounts.

## When to use

- `Permission denied` when accessing `~/.hermes/skills/` or other Hermes subdirectories
- `chown: Operation not permitted` because the container lacks CAP_CHOWN
- `sudo: command not found` and no `docker` socket available
- `stat` shows UID 501 (or other unknown owner) — classic Docker volume mount footprint
- `hermes skills list` shows far fewer skills than are actually in the directory
- `patch` tool creates `.hermes-tmp.*` files but fails with "Permission denied"

## Diagnosis

```bash
# Check ownership and permissions
stat ~/.hermes/skills/

# Check if parent dir is writable
stat ~/.hermes/

# Check if sudo is available
which sudo

# Check capabilities
cat /proc/self/status | grep CapEff

# Check for docker socket
ls -la /var/run/docker.sock

# List skills that are actually on disk vs what the CLI sees
ls ~/.hermes/skills/ | head -40

# Check if subdirectories have different ownership
stat -c '%U:%G %n' ~/.hermes/skills/*/
```

## Fix

### Primary Fix: docker-exec from Host (recommended)

The most reliable approach — run ONE command from the Docker host (outside the
container). This works because the host's root user has full filesystem access
to the container's volumes.

**One-shot fix (entire Hermes home, recommended):**
```bash
docker exec -u 0 <container-name> sh -c "chown -R 1024:1024 /home/hermeswebui/.hermes"
```

This recursively chowns every file and directory — skills, config, cron, agent
tools, everything. No future permission issues.

**Targeted fix (skills only, if other dirs need their own ownership):**
```bash
docker exec -u 0 <container-name> sh -c "chown -R 1024:1024 /home/hermeswebui/.hermes/skills"
```

**Finding the container name or ID:**
```bash
docker ps
# Look for the WebUI container (e.g., 'hermes-hermes-webui')
```

**What it fixes:** Recursively chowns every file and directory under the target
path — including nested subdirectories, references, scripts, and templates that
a single-level chown would miss.

**When to use:** Always, whenever the user can run a command on the Docker host.
This is faster and more complete than any inside-container workaround.

### Fallback: Rename + Recreate (inside container)

When docker-exec from the host is unavailable or the user can't reach the host,
use this inside-container workaround. It works because the parent directory is
typically owned by the container user even when its children are root-owned.

```bash
# 1. Rename the locked directory
mv ~/.hermes/skills ~/.hermes/skills.old

# 2. Create a fresh directory (inherits parent ownership)
mkdir ~/.hermes/skills

# 3. Verify
ls -la ~/.hermes/ | grep skills
touch ~/.hermes/skills/.writable && rm ~/.hermes/skills/.writable

# 4. If skills.old/ contained useful skills (from hermes skills list), migrate:
cp -r ~/.hermes/skills.old/* ~/.hermes/skills/ 2>/dev/null || true
```

**Note:** After the rename-recreate, the old skills are preserved in
`skills.old/` as a backup. Never delete them without asking — the user may want
to migrate them first.

### Third Option: Use pexpect for su

If the root password is available but `su` doesn't accept piped input, use
Python's `pexpect` library (pty-based terminal emulation):

```python
import pexpect
child = pexpect.spawn('/bin/su -c "chown ..."')
child.expect('Password:')
child.sendline('<root-password>')
child.expect(pexpect.EOF)
```

**Caveat:** Most Docker images have the root password locked (`!` in shadow),
making this approach unreliable. Prefer the docker-exec-from-host approach
whenever possible.

## Pitfalls

- **chowning files is not enough — the directory itself must also be writable.**
  The `patch` tool creates `.hermes-tmp.*` temp files in the target directory.
  If the directory is root-owned but files inside are hermeswebui-owned, edits
  silently fail with "Permission denied". Always chown both the directory AND
  its contents.
- **After fixing, reload skills** with `hermes skills list` or `/reload-skills`
  in the WebUI to refresh the skills cache.
- **If `~/.hermes/config.yaml` has `skills.external_dirs`**, that's an
  alternative: point to a writable path and skip fixing the default dir.
- **The rename approach loses the old directory's files** until they're
  manually migrated. Always ask before deleting `skills.old/`.
- **Docker images almost never set a root password.** The `!` in `/etc/shadow`
  means root is locked. Attempting `su` from inside the container will fail
  even with the correct host root password. Always try the host-level
  `docker exec -u 0` first.
- **Inside-container chown silently skips root-owned files.** Running
  `chown -R` as a non-root user on a tree that contains root-owned files
  exits with code 0 and produces no error output — but the root-owned files
  are unchanged. Only the files the user already owns are affected. This
  makes it look like the fix worked when it didn't. Always verify with
  `touch <dir>/test_write` afterward.
- **The chown must cover the entire tree, not just one level.** A directory
  may be root-owned while the files inside are also root-owned, or vice
  versa. The `patch` tool creates `.hermes-tmp.*` in the same directory
  as the target file, so both file and directory ownership must be fixed.

## References

- Hermes skills config: `skills.external_dirs` in `~/.hermes/config.yaml`
- Skills are loaded from `~/.hermes/skills/` first, then external dirs in config order
- `skill_manage()` tool handles CRUD on skills
- Full recursive fix: `docker exec -u 0 <container> sh -c "chown -R $(id -u):$(id -g) ~/.hermes"`
