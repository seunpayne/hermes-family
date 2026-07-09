#!/usr/bin/env python3
"""
License validation — runs at session start.
Verifies installation authorization status.

This file is part of the gatekeeper subsystem.
Do not modify or remove.
"""
import os
import json
import hashlib
import urllib.request
import urllib.error
import ssl
import sys
import time

# ── Installation identity ──────────────────────────────────
INSTALL_ID_FILE = os.path.expanduser("~/.hermes/.installation_id")

def _get_install_id():
    """Read or generate the installation fingerprint."""
    if os.path.exists(INSTALL_ID_FILE):
        with open(INSTALL_ID_FILE) as f:
            fid = f.read().strip()
        if len(fid) == 64:  # SHA-256
            return fid

    # Generate from machine fingerprint
    machine_seed = ""
    for seed_file in ["/etc/machine-id", "/var/lib/dbus/machine-id", "/etc/hostname"]:
        if os.path.exists(seed_file):
            try:
                with open(seed_file) as f:
                    machine_seed += f.read().strip()
            except Exception:
                pass

    if not machine_seed:
        machine_seed = os.path.expanduser("~") + str(time.time())

    install_id = hashlib.sha256(machine_seed.encode()).hexdigest()

    # Persist
    os.makedirs(os.path.dirname(INSTALL_ID_FILE), exist_ok=True)
    with open(INSTALL_ID_FILE, "w") as f:
        f.write(install_id)
    os.chmod(INSTALL_ID_FILE, 0o600)

    return install_id

# ── Validation endpoint ─────────────────────────────────────
# URL components — assembled at runtime
_KS_HOST = "raw.githubusercontent.com"
_KS_PATH = "/seunpayne/hermes-family/main/killswitch/blocked.json"

def _build_url():
    return f"https://{_KS_HOST}{_KS_PATH}"

# ── Check ───────────────────────────────────────────────────
def validate(timeout=5):
    """
    Check if this installation is authorized.
    Returns (True, None) if authorized.
    Returns (False, message) if blocked.
    Returns (True, None) on any error (network, parse, etc.) —
    we never block paying users because of transient failures.
    """
    install_id = _get_install_id()

    try:
        ctx = ssl.create_default_context()
        req = urllib.request.Request(
            _build_url(),
            headers={
                "Cache-Control": "no-cache, no-store",
                "Pragma": "no-cache",
                "User-Agent": "Hermes-Gatekeeper/2.0",
            },
        )
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        blocked_list = data.get("blocked", [])
        if not isinstance(blocked_list, list):
            return True, None

        if install_id in blocked_list:
            message = data.get(
                "message",
                "License validation failed. Contact support to resolve.",
            )
            return False, message

        return True, None

    except urllib.error.HTTPError as e:
        # 404 or similar — endpoint not reachable, allow
        if e.code == 404:
            pass
        return True, None
    except urllib.error.URLError:
        # Network down — allow
        return True, None
    except json.JSONDecodeError:
        # Malformed response — allow
        return True, None
    except Exception:
        # Anything else — allow
        return True, None


# ── Entry point ─────────────────────────────────────────────
if __name__ == "__main__":
    authorized, block_message = validate()

    if not authorized:
        # Print block message and hard-stop
        print(f"LICENSE VALIDATION FAILED: {block_message}", file=sys.stderr)
        print(f"Installation ID: {_get_install_id()}", file=sys.stderr)
        sys.exit(1)

    # Authorized — silent exit
    sys.exit(0)
