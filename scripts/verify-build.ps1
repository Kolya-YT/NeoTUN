# NeoTUN Build Verification Script (PowerShell)
param([switch]$Detailed)

Write-Host "🔍 NeoTUN Build Verification" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$HasErrors = $false

function Write-Success($Message) {
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error($Message) {
    Write-Host "✗ $Message" -ForegroundColor Red
    $script:HasErrors = $true
}

function Write-Warning($Message) {
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Check project structure
Write-Host "`n📁 Checking project structure..." -ForegroundColor White

if (Test-Path ".github\workflows") { Write-Success "GitHub Actions workflows directory exists" } else { Write-Error "Missing .github\workflows directory" }
if (Test-Path "android") { Write-Success "Android project directory exists" } else { Write-Error "Missing android directory" }
if (Test-Path "windows") { Write-Success "Windows project directory exists" } else { Write-Error "Missing windows directory" }
if (Test-Path "shared") { Write-Success "Shared code directory exists" } else { Write-Error "Missing shared directory" }

# Check for required files
if (Test-Path ".gitmodules") { Write-Success "Git submodules configuration exists" } else { Write-Error "Missing .gitmodules file" }
if (Test-Path "android\build.gradle.kts") { Write-Success "Android build configuration exists" } else { Write-Error "Missing android\build.gradle.kts" }
if (Test-Path "windows\NeoTUN.sln") { Write-Success "Windows solution file exists" } else { Write-Error "Missing windows\NeoTUN.sln" }

# Check GitHub Actions workflows
Write-Host "`n🔧 Checking GitHub Actions workflows..." -ForegroundColor White

if (Test-Path ".github\workflows\android.yml") { Write-Success "Android CI workflow exists" } else { Write-Error "Missing Android CI workflow" }
if (Test-Path ".github\workflows\windows.yml") { Write-Success "Windows CI workflow exists" } else { Write-Error "Missing Windows CI workflow" }
if (Test-Path ".github\workflows\release.yml") { Write-Success "Release workflow exists" } else { Write-Error "Missing Release workflow" }

# Summary
Write-Host "`n📋 Build Verification Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

if (-not $HasErrors) {
    Write-Host "`n✅ Project structure is ready for CI/CD" -ForegroundColor Green
    Write-Host "🚀 GitHub Actions workflows are configured" -ForegroundColor Green
} else {
    Write-Host "`n❌ Some issues were found that need to be addressed" -ForegroundColor Red
}

Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Configure GitHub Secrets for code signing" -ForegroundColor Gray
Write-Host "2. Initialize Xray-core submodule: git submodule update --init --recursive" -ForegroundColor Gray
Write-Host "3. Test local builds before pushing to main branch" -ForegroundColor Gray
Write-Host "4. Create a release tag (v1.0.0) to trigger release pipeline" -ForegroundColor Gray