1|#!/usr/bin/env bash
2|# ============================================================
3|# Hermes Family — Bootstrap Installer v2.0
4|# One command to set up a delivery OS on a fresh Hermes install.
5|# Downloads ZIP from GitHub — no git required.
6|#
7|# Usage:
8|#   curl -sSL https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.sh | bash
9|# ============================================================
10|
11|set -euo pipefail
12|
13|OWNER="seunpayne"
14|REPO="hermes-family"
15|BRANCH="main"
16|REPO_URL="https://github.com/${OWNER}/${REPO}.git"
17|ZIP_URL="https://github.com/${OWNER}/${REPO}/archive/refs/heads/${BRANCH}.zip"
18|TEMP_DIR=$(mktemp -d)
19|TEMP_ZIP="${TEMP_DIR}/repo.zip"
20|
21|cleanup() { rm -rf "${TEMP_DIR}"; }
22|trap cleanup EXIT
23|
24|echo ""
25|echo "╔══════════════════════════════════════════════════╗"
26|echo "║     Hermes Family — Delivery OS Installer        ║"
27|echo "║     v2.0 — Modular Opt-In                       ║"
28|echo "╚══════════════════════════════════════════════════╝"
29|echo ""
30|
31|# ----------------------------------------------------------
32|# Step 1: Check Hermes is installed and find its home
33|# ----------------------------------------------------------
34|if ! command -v hermes &> /dev/null; then
35|    echo "❌ Hermes Agent not found."
36|    echo ""
37|    echo "   Install Hermes first:"
38|    echo "   curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
39|    echo ""
40|    exit 1
41|fi
42|
43|HERMES_VERSION=$(hermes --version 2>/dev/null || echo "unknown")
44|echo "✓ Hermes Agent found (${HERMES_VERSION})"
45|
46|HERMES_CONFIG_DIR=$(dirname "$(hermes config path 2>/dev/null)" 2>/dev/null || echo "${HOME}/.hermes")
47|echo "   Config dir: ${HERMES_CONFIG_DIR}"
48|echo ""
49|HERMES_SKILLS_DIR="${HERMES_CONFIG_DIR}/skills"
50|FAMILY_DIR="${HOME}/${REPO}"
51|
52|# ----------------------------------------------------------
53|# Step 2: Download family repo as ZIP and extract
54|# ----------------------------------------------------------
55|if command -v git &>/dev/null && [ -d "${FAMILY_DIR}/.git" ]; then
56|    echo "→ Updating existing repo via git pull..."
57|    cd "${FAMILY_DIR}"
58|    git pull origin main 2>/dev/null || echo "   (could not pull — using local copy)"
59|    cd - > /dev/null
60|else
61|    echo "→ Downloading ${REPO} from GitHub..."
62|    if command -v curl &>/dev/null; then
63|        if curl -sL -o "${TEMP_ZIP}" "${ZIP_URL}"; then
64|            echo "   ✓ Downloaded ($(du -h "${TEMP_ZIP}" | cut -f1))"
65|        else
66|            echo "   ⚠ Download failed. Falling back to git clone..."
67|            if command -v git &>/dev/null; then
68|                git clone "${REPO_URL}" "${FAMILY_DIR}" 2>/dev/null || { echo "   ❌ Git clone also failed."; exit 1; }
69|                echo "   ✓ Cloned via git"
70|            else
71|                echo "   ❌ No git available. Install git or download manually from:"
72|                echo "   ${ZIP_URL}"
73|                exit 1
74|            fi
75|        fi
76|    elif command -v wget &>/dev/null; then
77|        wget -q -O "${TEMP_ZIP}" "${ZIP_URL}" || { echo "   ❌ Download failed."; exit 1; }
78|        echo "   ✓ Downloaded"
79|    else
80|        echo "   ⚠ curl/wget not found. Falling back to git clone..."
81|        if command -v git &>/dev/null; then
82|            git clone "${REPO_URL}" "${FAMILY_DIR}" 2>/dev/null || { echo "   ❌ Git clone failed."; exit 1; }
83|            echo "   ✓ Cloned via git"
84|        else
85|            echo "   ❌ No download method available."
86|            echo "   Download manually from: ${ZIP_URL}"
87|            exit 1
88|        fi
89|    fi
90|
91|    # Extract ZIP if downloaded
92|    if [ -f "${TEMP_ZIP}" ]; then
93|        echo "→ Extracting..."
94|        EXTRACTED_DIR=$(unzip -qql "${TEMP_ZIP}" | head -1 | awk '{print $NF}' | cut -d/ -f1)
95|        unzip -o -q "${TEMP_ZIP}" -d "${TEMP_DIR}" 2>/dev/null || { echo "   ❌ Failed to extract ZIP (unzip required)."; exit 1; }
96|        rm -rf "${FAMILY_DIR}" 2>/dev/null || true
97|        mv "${TEMP_DIR}/${EXTRACTED_DIR}" "${FAMILY_DIR}"
98|        echo "   ✓ Extracted to ${FAMILY_DIR}"
99|    fi
100|fi
101|echo ""
102|
103|# ----------------------------------------------------------
104|# Step 3: Install the installer skill
105|# ----------------------------------------------------------
106|echo "→ Installing family-installer skill..."
107|mkdir -p "${HERMES_SKILLS_DIR}/family/family-installer"
108|cp -r "${FAMILY_DIR}/family-installer/"* "${HERMES_SKILLS_DIR}/family/family-installer/"
109|echo "   ✓ Installer skill ready"
110|echo ""
111|
112|# ----------------------------------------------------------
113|# Step 4: Pre-load the Family Skills into the repo
114|# ----------------------------------------------------------
115|echo "→ Family Skills available: $(ls -1 ${FAMILY_DIR}/skills/ 2>/dev/null | wc -l) skills"
116|echo "   (These will be selectively installed based on your agent choices)"
117|echo ""
118|
119|# ----------------------------------------------------------
120|# Step 5: Done — launch
121|# ----------------------------------------------------------
122|echo "╔══════════════════════════════════════════════════╗"
123|echo "║  Setup complete.                                 ║"
124|echo "║                                                  ║"
125|echo "║  To start the wizard, type in Hermes:            ║"
126|echo "║                                                  ║"
127|echo "║      load family-installer                       ║"
128|echo "║                                                  ║"
129|echo "║  The installer will ask who you are, help you    ║"
130|echo "║  pick your agents, name them, and stamp out      ║"
131|echo "║  your personalized delivery OS.                  ║"
132|echo "║                                                  ║"
133|echo "║  Takes about 15 minutes. No bloat — you only     ║"
134|echo "║  get the agents and skills you choose.           ║"
135|echo "╚══════════════════════════════════════════════════╝"
136|echo ""
137|