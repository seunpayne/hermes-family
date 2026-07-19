#!/usr/bin/env bash
# ============================================================
# Hermes Family — Bootstrap Installer v2.0
# One command to set up a delivery OS on a fresh Hermes install.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
#   GITHUB_TOKEN=ghp_xxx curl -sSL ... | bash
#   GH_TOKEN=ghp_xxx curl -sSL ... | bash
# ============================================================

set -euo pipefail

# ── GitHub Auth ─────────────────────────────────────────────
# Must be provided externally or already set
if [ -z "${GITHUB_TOKEN:-}" ] && [ -z "${GH_TOKEN:-}" ]; then
    # If we have a hermes env, try to source it
    HERMES_ENV=$(command -v hermes &>/dev/null && hermes config env-path 2>/dev/null || echo "${HOME}/.hermes/.env")
    if [ -f "$HERMES_ENV" ]; then
        set -a
        source "$HERMES_ENV" 2>/dev/null || true
        set +a
    fi
fi

TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [ -z "$TOKEN" ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  This installer requires a GitHub token.         ║"
    echo "║                                                  ║"
    echo "║  Pass it as an environment variable:              ║"
    echo "║    GITHUB_TOKEN=ghp_xxx curl ... | bash           ║"
    echo "║    GH_TOKEN=ghp_xxx curl ... | bash               ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

REPO_URL="https://x-access-token:${TOKEN}@github.com/seunpayne/hermes-family.git"
TEMP_DIR=$(mktemp -d)

cleanup() { rm -rf "${TEMP_DIR}"; }
trap cleanup EXIT

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Hermes Family — Delivery OS Installer        ║"
echo "║     v2.0 — Modular Opt-In                       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ----------------------------------------------------------
# Step 1: Check Hermes is installed and find its home
# ----------------------------------------------------------
if ! command -v hermes &> /dev/null; then
    echo "❌ Hermes Agent not found."
    echo ""
    echo "   Install Hermes first:"
    echo "   curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
    echo ""
    exit 1
fi

HERMES_VERSION=$(hermes --version 2>/dev/null || echo "unknown")
echo "✓ Hermes Agent found (${HERMES_VERSION})"

HERMES_CONFIG_DIR=$(dirname "$(hermes config path 2>/dev/null)" || echo "${HOME}/.hermes")
HERMES_ENV_FILE=$(hermes config env-path 2>/dev/null || echo "${HOME}/.hermes/.env")

echo "   Config dir: ${HERMES_CONFIG_DIR}"
echo ""
HERMES_SKILLS_DIR="${HERMES_CONFIG_DIR}/skills"

# ----------------------------------------------------------
# Step 2: Clone or update the family repo
# ----------------------------------------------------------
FAMILY_DIR="${HOME}/hermes-family"

if [ -d "${FAMILY_DIR}/.git" ]; then
    echo "→ Updating existing hermes-family repo..."
    cd "${FAMILY_DIR}"
    git pull origin main 2>/dev/null || echo "   (could not pull — continuing with local copy)"
    cd - > /dev/null
else
    echo "→ Cloning hermes-family repo..."
    if git clone "${REPO_URL}" "${TEMP_DIR}/hermes-family" 2>/dev/null; then
        cp -r "${TEMP_DIR}/hermes-family" "${FAMILY_DIR}"
        echo "   ✓ Cloned to ${FAMILY_DIR}"
    else
        echo "   ⚠ Could not clone from GitHub."
        echo "   Check that your GITHUB_TOKEN has repo scope and is valid."
        exit 1
    fi
fi
echo ""

# ----------------------------------------------------------
# Step 3: Install the installer skill
# ----------------------------------------------------------
echo "→ Installing family-installer skill..."
mkdir -p "${HERMES_SKILLS_DIR}/family/family-installer"
cp -r "${FAMILY_DIR}/family-installer/"* "${HERMES_SKILLS_DIR}/family/family-installer/"
echo "   ✓ Installer skill ready"
echo ""

# ----------------------------------------------------------
# Step 4: Pre-load the Family Skills into the repo
# ----------------------------------------------------------
echo "→ Family Skills available: $(ls -1 ${FAMILY_DIR}/skills/ 2>/dev/null | wc -l) skills"
echo "   (These will be selectively installed based on your agent choices)"
echo ""

# ----------------------------------------------------------
# Step 5: Done — launch
# ----------------------------------------------------------
echo "╔══════════════════════════════════════════════════╗"
echo "║  Setup complete.                                 ║"
echo "║                                                  ║"
echo "║  To start the wizard, type in Hermes:            ║"
echo "║                                                  ║"
echo "║      load family-installer                       ║"
echo "║                                                  ║"
echo "║  The installer will ask who you are, help you    ║"
echo "║  pick your agents, name them, and stamp out      ║"
echo "║  your personalized delivery OS.                  ║"
echo "║                                                  ║"
echo "║  Takes about 15 minutes. No bloat — you only     ║"
echo "║  get the agents and skills you choose.           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
