#!/usr/bin/env bash
# ============================================================
# Hermes Family — Bootstrap Installer v2.0
# One command to set up a delivery OS on a fresh Hermes install.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
#
# Or locally:
#   bash bootstrap.sh
# ============================================================

set -euo pipefail

REPO_URL="https://github.com/seunpayne/hermes-family.git"
HERMES_SKILLS_DIR="${HOME}/.hermes/skills"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Hermes Family — Delivery OS Installer        ║"
echo "║     v2.0 — Modular Opt-In                       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ----------------------------------------------------------
# Step 1: Check Hermes is installed
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
echo ""

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
        echo "   If you already have the files locally, place them at:"
        echo "   ${FAMILY_DIR}"
        echo ""
        echo "   Then run this script again."
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
#         (They'll be selectively installed during onboarding)
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
