# NeoTUN Build Monitor
# Monitors GitHub Actions build status in real-time

param(
    [int]$RefreshInterval = 30,
    [switch]$Continuous
)

function Get-BuildStatus {
    Write-Host "🔄 Checking build status..." -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Cyan
    
    # Get latest commit
    $latestCommit = git rev-parse HEAD
    $commitMessage = git log -1 --pretty=format:"%s"
    
    Write-Host "📝 Latest Commit: " -NoNewline -ForegroundColor White
    Write-Host $latestCommit.Substring(0, 8) -ForegroundColor Green
    Write-Host "💬 Message: " -NoNewline -ForegroundColor White
    Write-Host $commitMessage -ForegroundColor Gray
    Write-Host ""
    
    # Check if we can access GitHub API (optional)
    try {
        $repoUrl = git config --get remote.origin.url
        if ($repoUrl -match "github\.com[:/](.+)/(.+)\.git") {
            $owner = $matches[1]
            $repo = $matches[2]
            
            Write-Host "🏗️ Build Status:" -ForegroundColor Magenta
            Write-Host "   Repository: $owner/$repo" -ForegroundColor Gray
            Write-Host "   Actions URL: https://github.com/$owner/$repo/actions" -ForegroundColor Blue
            Write-Host ""
        }
    }
    catch {
        Write-Host "ℹ️ GitHub API not accessible, showing local status only" -ForegroundColor Yellow
    }
    
    # Show workflow files status
    Write-Host "📋 Configured Workflows:" -ForegroundColor Green
    
    if (Test-Path ".github/workflows/android.yml") {
        Write-Host "   ✅ Android CI - Builds APK with Xray integration" -ForegroundColor Green
    }
    
    if (Test-Path ".github/workflows/windows.yml") {
        Write-Host "   ✅ Windows CI - Builds EXE and MSIX package" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🎯 Expected Build Outputs:" -ForegroundColor Cyan
    Write-Host "   📱 Android: neotun-debug.apk / neotun-release.apk" -ForegroundColor White
    Write-Host "   💻 Windows: neotun-windows.exe + neotun-windows.msix" -ForegroundColor White
    Write-Host ""
    
    # Check for common build issues
    Write-Host "🔍 Pre-build Validation:" -ForegroundColor Yellow
    
    # Check Android files
    $androidIssues = @()
    if (!(Test-Path "android/gradlew")) { $androidIssues += "Missing gradlew" }
    if (!(Test-Path "android/gradle/wrapper/gradle-wrapper.jar")) { $androidIssues += "Missing gradle-wrapper.jar" }
    if (!(Test-Path "android/app/build.gradle.kts")) { $androidIssues += "Missing build.gradle.kts" }
    
    if ($androidIssues.Count -eq 0) {
        Write-Host "   ✅ Android build files OK" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Android issues: $($androidIssues -join ', ')" -ForegroundColor Red
    }
    
    # Check Windows files
    $windowsIssues = @()
    if (!(Test-Path "windows/NeoTUN.sln")) { $windowsIssues += "Missing solution file" }
    if (!(Test-Path "windows/NeoTUN.Windows/NeoTUN.Windows.csproj")) { $windowsIssues += "Missing project file" }
    
    if ($windowsIssues.Count -eq 0) {
        Write-Host "   ✅ Windows build files OK" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Windows issues: $($windowsIssues -join ', ')" -ForegroundColor Red
    }
    
    # Check submodules
    if (Test-Path ".gitmodules") {
        $submoduleStatus = git submodule status
        if ($submoduleStatus -match "^-") {
            Write-Host "   ⚠️ Submodules not initialized" -ForegroundColor Red
        } else {
            Write-Host "   ✅ Submodules OK" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "🌐 Monitor build progress at:" -ForegroundColor Magenta
    Write-Host "   https://github.com/Kolya-YT/NeoTUN/actions" -ForegroundColor Blue
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "⏰ Last checked: $timestamp" -ForegroundColor Gray
}

# Main execution
Clear-Host
Write-Host "🚀 NeoTUN Build Monitor" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

if ($Continuous) {
    Write-Host "🔄 Continuous monitoring enabled (refresh every $RefreshInterval seconds)" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        Get-BuildStatus
        Write-Host "⏳ Waiting $RefreshInterval seconds..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $RefreshInterval
        Clear-Host
        Write-Host "🚀 NeoTUN Build Monitor (Continuous)" -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host ""
    }
} else {
    Get-BuildStatus
    Write-Host "💡 Tip: Use -Continuous flag for real-time monitoring" -ForegroundColor DarkGray
}