# install.ps1 - Remote installer for Git-Core Protocol (Windows)
# Usage: irm https://raw.githubusercontent.com/iberi22/ai-git-core-template/main/install.ps1 | iex
#
# Or with parameters:
#   $env:GIT_CORE_ORGANIZE = "1"; irm .../install.ps1 | iex
#   $env:GIT_CORE_AUTO = "1"; irm .../install.ps1 | iex
#
# 🎯 This script can be executed by AI agents to bootstrap any project with Git-Core Protocol

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/iberi22/ai-git-core-template"
$TEMP_DIR = ".git-core-temp"

Write-Host "🧠 Git-Core Protocol - Remote Installer (Windows)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check for environment variable flags
$OrganizeFiles = $env:GIT_CORE_ORGANIZE -eq "1"
$AutoMode = $env:GIT_CORE_AUTO -eq "1"

# Function to organize existing files
function Invoke-OrganizeFiles {
    Write-Host "📂 Organizing existing files..." -ForegroundColor Yellow

    # Create directories
    $dirs = @("docs/archive", "scripts", "tests", "src")
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir -ErrorAction SilentlyContinue | Out-Null
    }

    # Files to keep in root
    $keepInRoot = @("README.md", "AGENTS.md", "CHANGELOG.md", "CONTRIBUTING.md", "LICENSE.md", "LICENSE")

    # Move markdown files to docs/archive
    Get-ChildItem -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notin $keepInRoot) {
            Move-Item $_.FullName -Destination "docs/archive/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to docs/archive/" -ForegroundColor Cyan
        } else {
            Write-Host "  ✓ Keeping $($_.Name) in root" -ForegroundColor Green
        }
    }

    # Move test files
    $testPatterns = @("test_*.py", "*_test.py", "*.test.js", "*.test.ts", "*.spec.js", "*.spec.ts")
    foreach ($pattern in $testPatterns) {
        Get-ChildItem -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
            Move-Item $_.FullName -Destination "tests/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to tests/" -ForegroundColor Cyan
        }
    }

    # Move loose scripts
    Get-ChildItem -Filter "*.bat" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.DirectoryName -eq (Get-Location).Path) {
            Move-Item $_.FullName -Destination "scripts/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to scripts/" -ForegroundColor Cyan
        }
    }

    Write-Host "✅ Files organized" -ForegroundColor Green
}

# Check if should organize
if ($OrganizeFiles) {
    Invoke-OrganizeFiles
}

# Check if directory has files
$hasFiles = (Get-ChildItem -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike ".*" } | Measure-Object).Count -gt 0

if ($hasFiles -and -not $AutoMode) {
    Write-Host "⚠️  Current directory is not empty." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  1) Continue and merge files"
    Write-Host "  2) Organize existing files first (move .md to docs/archive/)"
    Write-Host "  3) Cancel"
    Write-Host ""
    $choice = Read-Host "Select (1/2/3)"

    switch ($choice) {
        "1" { Write-Host "Continuing..." }
        "2" { Invoke-OrganizeFiles }
        "3" { Write-Host "Cancelled."; exit 0 }
        default { Write-Host "Invalid option."; exit 1 }
    }
}

# Download template
Write-Host "`n📥 Downloading Git-Core Protocol template..." -ForegroundColor Cyan

try {
    git clone --depth 1 $REPO_URL $TEMP_DIR 2>$null
} catch {
    Write-Host "❌ Error cloning repository" -ForegroundColor Red
    exit 1
}

# Remove template's git history
Remove-Item -Recurse -Force "$TEMP_DIR/.git" -ErrorAction SilentlyContinue

# Copy files
Write-Host "📦 Installing protocol files..." -ForegroundColor Cyan

# Copy directories
$dirs = @(".ai", ".github", "scripts")
foreach ($dir in $dirs) {
    if (Test-Path "$TEMP_DIR/$dir") {
        if (-not (Test-Path $dir)) {
            Copy-Item -Recurse "$TEMP_DIR/$dir" .
        } else {
            Copy-Item -Recurse -Force "$TEMP_DIR/$dir/*" $dir
        }
        Write-Host "  ✓ $dir/" -ForegroundColor Green
    }
}

# Copy config files (only if they don't exist)
$configFiles = @(".cursorrules", ".windsurfrules", ".gitignore", "AGENTS.md", ".git-core-protocol-version")
foreach ($file in $configFiles) {
    if ((Test-Path "$TEMP_DIR/$file") -and -not (Test-Path $file)) {
        Copy-Item "$TEMP_DIR/$file" .
        Write-Host "  ✓ $file" -ForegroundColor Green
    } elseif (Test-Path $file) {
        Write-Host "  ~ $file (exists, not overwritten)" -ForegroundColor Yellow
    }
}

# Copy README only if it doesn't exist
if (-not (Test-Path "README.md")) {
    Copy-Item "$TEMP_DIR/README.md" .
    Write-Host "  ✓ README.md" -ForegroundColor Green
} else {
    Write-Host "  ~ README.md (exists, not overwritten)" -ForegroundColor Yellow
}

# Cleanup
Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Git-Core Protocol installed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Files installed:"
Write-Host "   .ai/ARCHITECTURE.md    - Document your architecture here"
Write-Host "   .github/               - Copilot rules + workflows + templates"
Write-Host "   scripts/               - Init and update scripts"
Write-Host "   AGENTS.md              - Rules for all AI agents"
Write-Host "   .cursorrules           - Rules for Cursor"
Write-Host "   .windsurfrules         - Rules for Windsurf"
Write-Host "   .git-core-protocol-version - Protocol version (for auto-updates)"
Write-Host ""
Write-Host "🚀 Next step:" -ForegroundColor Yellow
Write-Host "   .\scripts\init_project.ps1"
Write-Host ""
Write-Host "🔄 To check for updates later:" -ForegroundColor Cyan
Write-Host "   .\scripts\check-protocol-update.ps1 -Update"
Write-Host ""
Write-Host "💡 Tip for AI Agents: Use environment variables for non-interactive mode" -ForegroundColor Cyan
Write-Host '   $env:GIT_CORE_AUTO = "1"; $env:GIT_CORE_ORGANIZE = "1"' -ForegroundColor Cyan
