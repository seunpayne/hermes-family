<#
.SYNOPSIS
    Hermes Family — Bootstrap Installer v2.0 (PowerShell)
    One command to set up a delivery OS on a fresh Hermes install on Windows.

.DESCRIPTION
    Detects Hermes config location, clones the family repo,
    installs the family-installer skill. Then you're ready to
    "load family-installer" in Hermes.

.USAGE
    irm https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.ps1 | iex

    Or save locally and run:
    .\bootstrap.ps1
#>

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/seunpayne/hermes-family.git"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Hermes Family — Delivery OS Installer        ║" -ForegroundColor Cyan
Write-Host "║     v2.0 — Modular Opt-In                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# Step 1: Check Hermes is installed and find its home
# ----------------------------------------------------------
try {
    $HermesVersion = & hermes --version 2>&1 | Out-String
    Write-Host "✓ Hermes Agent found ($($HermesVersion.Trim()))" -ForegroundColor Green
} catch {
    Write-Host "❌ Hermes Agent not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "   Install Hermes first: https://hermes-agent.nousresearch.com/docs"
    Write-Host ""
    exit 1
}

# Use hermes CLI to find the real config path
try {
    $ConfigPath = & hermes config path 2>&1 | Out-String
    $ConfigPath = $ConfigPath.Trim()
    $ConfigDir = Split-Path $ConfigPath -Parent
} catch {
    $ConfigDir = Join-Path $env:USERPROFILE ".hermes"
}

$EnvPath = try { (& hermes config env-path 2>&1 | Out-String).Trim() } catch { Join-Path $ConfigDir ".env" }
$SkillsDir = Join-Path $ConfigDir "skills"

Write-Host "   Config dir: $ConfigDir" -ForegroundColor Gray
Write-Host ""

# ----------------------------------------------------------
# Step 2: Clone or update the family repo
# ----------------------------------------------------------
$FamilyDir = Join-Path $env:USERPROFILE "hermes-family"

if (Test-Path (Join-Path $FamilyDir ".git")) {
    Write-Host "→ Updating existing hermes-family repo..." -ForegroundColor Yellow
    Push-Location $FamilyDir
    try {
        & git pull origin main 2>&1 | Out-Null
    } catch {
        Write-Host "   (could not pull — continuing with local copy)"
    }
    Pop-Location
} else {
    Write-Host "→ Cloning hermes-family repo..." -ForegroundColor Yellow
    $TempDir = Join-Path $env:TEMP "hermes-family-$(Get-Random)"
    try {
        & git clone $RepoUrl $TempDir 2>&1 | Out-Null
        if (Test-Path $TempDir) {
            # Remove old if exists
            if (Test-Path $FamilyDir) { Remove-Item -Recurse -Force $FamilyDir }
            Copy-Item -Recurse $TempDir $FamilyDir
            Remove-Item -Recurse -Force $TempDir
            Write-Host "   ✓ Cloned to $FamilyDir" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠ Could not clone from GitHub." -ForegroundColor Yellow
        Write-Host "   If you already have the files locally, place them at:"
        Write-Host "   $FamilyDir"
        Write-Host ""
        exit 1
    }
}
Write-Host ""

# ----------------------------------------------------------
# Step 3: Install the installer skill
# ----------------------------------------------------------
Write-Host "→ Installing family-installer skill..." -ForegroundColor Yellow
$InstallerTarget = Join-Path $SkillsDir "family" "family-installer"
New-Item -ItemType Directory -Force -Path $InstallerTarget | Out-Null
$InstallerSource = Join-Path $FamilyDir "family-installer"
Copy-Item -Recurse -Force (Join-Path $InstallerSource "*") $InstallerTarget
Write-Host "   ✓ Installer skill ready" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------
# Step 4: Pre-load the Family Skills into the repo
# ----------------------------------------------------------
$SkillCount = (Get-ChildItem (Join-Path $FamilyDir "skills") -Directory).Count
Write-Host "→ Family Skills available: $SkillCount skills" -ForegroundColor Gray
Write-Host "   (These will be selectively installed based on your agent choices)"
Write-Host ""

# ----------------------------------------------------------
# Step 5: Done — launch
# ----------------------------------------------------------
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Setup complete.                                 ║" -ForegroundColor Cyan
Write-Host "║                                                  ║" -ForegroundColor Cyan
Write-Host "║  To start the wizard, type in Hermes:            ║" -ForegroundColor Cyan
Write-Host "║                                                  ║" -ForegroundColor Cyan
Write-Host "║      load family-installer                       ║" -ForegroundColor Cyan
Write-Host "║                                                  ║" -ForegroundColor Cyan
Write-Host "║  The installer will ask who you are, help you    ║" -ForegroundColor Cyan
Write-Host "║  pick your agents, name them, and stamp out      ║" -ForegroundColor Cyan
Write-Host "║  your personalized delivery OS.                  ║" -ForegroundColor Cyan
Write-Host "║                                                  ║" -ForegroundColor Cyan
Write-Host "║  Takes about 15 minutes. No bloat — you only     ║" -ForegroundColor Cyan
Write-Host "║  get the agents and skills you choose.           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
