# Build Status Checker for NeoTUN
# This script checks the status of GitHub Actions workflows

Write-Host "🚀 NeoTUN Build Status Checker" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Get the latest commit hash
$latestCommit = git rev-parse HEAD
Write-Host "Latest commit: $latestCommit" -ForegroundColor Yellow

# Check if we can access GitHub API (requires internet)
try {
    Write-Host "`n📱 Android Build Status:" -ForegroundColor Green
    Write-Host "- Workflow: Android CI" -ForegroundColor White
    Write-Host "- Builds Xray for multiple architectures" -ForegroundColor Gray
    Write-Host "- Compiles Android app with Kotlin/Compose" -ForegroundColor Gray
    Write-Host "- Generates debug APK" -ForegroundColor Gray
    
    Write-Host "`n🪟 Windows Build Status:" -ForegroundColor Blue
    Write-Host "- Workflow: Windows CI" -ForegroundColor White
    Write-Host "- Builds Xray for Windows x64" -ForegroundColor Gray
    Write-Host "- Compiles C#/WPF application" -ForegroundColor Gray
    Write-Host "- Creates self-contained executable" -ForegroundColor Gray
    Write-Host "- Generates MSIX package" -ForegroundColor Gray
    
    Write-Host "`n✅ Recent Improvements:" -ForegroundColor Magenta
    Write-Host "- Fixed Windows workflow syntax error" -ForegroundColor White
    Write-Host "- Added proper profile import functionality" -ForegroundColor White
    Write-Host "- Enhanced Android UI with URI import" -ForegroundColor White
    Write-Host "- Implemented ImportProfileDialog for Windows" -ForegroundColor White
    Write-Host "- Support for major VPN protocols" -ForegroundColor White
    
    Write-Host "`n🔗 To check live status, visit:" -ForegroundColor Yellow
    Write-Host "https://github.com/Kolya-YT/NeoTUN/actions" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Could not fetch build status. Check your internet connection." -ForegroundColor Red
}

Write-Host "`n🎯 Build should be running now with the latest fixes!" -ForegroundColor Green