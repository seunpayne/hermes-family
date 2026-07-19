#!/usr/bin/env bash
# ============================================================
# Hermes Family — Bootstrap Installer v2.0
# One command to set up a delivery OS on a fresh Hermes install.
# Downloads ZIP from GitHub — no git required.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
# ============================================================

set -euo pipefail

OWNER="seunpayne"
REPO="hermes-family"
BRANCH="main"
REPO_URL="https://github.com/${OWNER}/${REPO}.git"
ZIP_URL="https://github.com/${OWNER}/${REPO}/archive/refs/heads/${BRANCH}.zip"
TEMP_DIR=$(mktemp -d)
TEMP_ZIP="${TEMP_DIR}/repo.zip"

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

HERMES_CONFIG_DIR=$(dirname "$(hermes config path 2>/dev/null)" 2>/dev/null || echo "${HOME}/.hermes")
echo "   Config dir: ${HERMES_CONFIG_DIR}"
echo ""
HERMES_SKILLS_DIR="${HERMES_CONFIG_DIR}/skills"
FAMILY_DIR="${HOME}/${REPO}"

# ----------------------------------------------------------
# Step 2: Download family repo as ZIP and extract
# ----------------------------------------------------------
if command -v git &>/dev/null && [ -d "${FAMILY_DIR}/.git" ]; then
    echo "→ Updating existing repo via git pull..."
    cd "${FAMILY_DIR}"
    git pull origin main 2>/dev/null || echo "   (could not pull — using local copy)"
    cd - > /dev/null
else
    echo "→ Downloading ${REPO} from GitHub..."
    if command -v curl &>/dev/null; then
        if curl -sL -o "${TEMP_ZIP}" "${ZIP_URL}"; then
            echo "   ✓ Downloaded ($(du -h "${TEMP_ZIP}" | cut -f1))"
        else
            echo "   ⚠ Download failed. Falling back to git clone..."
            if command -v git &>/dev/null; then
                git clone "${REPO_URL}" "${FAMILY_DIR}" 2>/dev/null || { echo "   ❌ Git clone also failed."; exit 1; }
                echo "   ✓ Cloned via git"
            else
                echo "   ❌ No git available. Install git or download manually from:"
                echo "   ${ZIP_URL}"
                exit 1
            fi
        fi
    elif command -v wget &>/dev/null; then
        wget -q -O "${TEMP_ZIP}" "${ZIP_URL}" || { echo "   ❌ Download failed."; exit 1; }
        echo "   ✓ Downloaded"
    else
        echo "   ⚠ curl/wget not found. Falling back to git clone..."
        if command -v git &>/dev/null; then
            git clone "${REPO_URL}" "${FAMILY_DIR}" 2>/dev/null || { echo "   ❌ Git clone failed."; exit 1; }
            echo "   ✓ Cloned via git"
        else
            echo "   ❌ No download method available."
            echo "   Download manually from: ${ZIP_URL}"
            exit 1
        fi
    fi

    # Extract ZIP if downloaded
    if [ -f "${TEMP_ZIP}" ]; then
        echo "→ Extracting..."
        EXTRACTED_DIR=$(unzip -qql "${TEMP_ZIP}" | head -1 | awk '{print $NF}' | cut -d/ -f1)
        unzip -o -q "${TEMP_ZIP}" -d "${TEMP_DIR}" 2>/dev/null || { echo "   ❌ Failed to extract ZIP (unzip required)."; exit 1; }
        rm -rf "${FAMILY_DIR}" 2>/dev/null || true
        mv "${TEMP_DIR}/${EXTRACTED_DIR}" "${FAMILY_DIR}"
        echo "   ✓ Extracted to ${FAMILY_DIR}"
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
