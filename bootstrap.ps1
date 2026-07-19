<#
.SYNOPSIS
    Hermes Family — Bootstrap Installer v2.0 (PowerShell)
    One command to set up a delivery OS on a fresh Hermes install on Windows.

.DESCRIPTION
    Downloads the family repo as a ZIP (no git needed), detects Hermes config,
    installs the family-installer skill for the interactive wizard.

.USAGE
    irm https://raw.githubusercontent.com/seunpayne/hermes-family/main/bootstrap.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$RepoOwner = "seunpayne"
$RepoName = "hermes-family"
$Branch = "main"
$ZipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"

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

try {
    $ConfigPath = & hermes config path 2>&1 | Out-String
    $ConfigDir = Split-Path ($ConfigPath.Trim()) -Parent
} catch {
    $ConfigDir = Join-Path $env:USERPROFILE ".hermes"
}

$SkillsDir = Join-Path $ConfigDir "skills"
Write-Host "   Config dir: $ConfigDir" -ForegroundColor Gray
Write-Host ""

# ----------------------------------------------------------
# Step 2: Download family repo as ZIP and extract
# ----------------------------------------------------------
$FamilyDir = Join-Path $env:USERPROFILE "$RepoName"
$TempZip = Join-Path $env:TEMP "$RepoName-$Branch.zip"
$ExtractDir = Join-Path $env:TEMP "$RepoName-extract"

Write-Host "→ Downloading $RepoName from GitHub..." -ForegroundColor Yellow

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($ZipUrl, $TempZip)
    Write-Host "   ✓ Downloaded ($((Get-Item $TempZip).Length / 1KB) KB)" -ForegroundColor Green

    Write-Host "→ Extracting..." -ForegroundColor Yellow
    if (Test-Path $ExtractDir) { Remove-Item -Recurse -Force $ExtractDir }
    Expand-Archive -Path $TempZip -DestinationPath $ExtractDir -Force

    # The ZIP contains a folder named <repo>-<branch>
    $SourceDir = (Get-ChildItem $ExtractDir -Directory | Select-Object -First 1).FullName

    if (Test-Path $FamilyDir) { Remove-Item -Recurse -Force $FamilyDir }
    Move-Item -Path $SourceDir -Destination $FamilyDir
    Remove-Item -Force $TempZip
    Remove-Item -Recurse -Force $ExtractDir -ErrorAction SilentlyContinue

    Write-Host "   ✓ Extracted to $FamilyDir" -ForegroundColor Green
} catch {
    Write-Host "   ⚠ Download failed: $_" -ForegroundColor Red
    Write-Host "   Try: git clone https://github.com/$RepoOwner/$RepoName.git $FamilyDir"
    Write-Host ""
    exit 1
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
