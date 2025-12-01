# Проверка наличия AndroidLibXrayLite AAR

$aarPath = "android/app/libs/AndroidLibXrayLite.aar"

Write-Host "Checking AndroidLibXrayLite AAR..." -ForegroundColor Cyan

if (Test-Path $aarPath) {
    $size = (Get-Item $aarPath).Length / 1MB
    Write-Host "✓ AAR file found: $aarPath" -ForegroundColor Green
    Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    
    # Проверяем что это действительно AAR (ZIP архив)
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($aarPath)
        $entries = $zip.Entries.Count
        $zip.Dispose()
        Write-Host "  Entries: $entries files" -ForegroundColor Gray
        Write-Host ""
        Write-Host "✓ AAR file is valid!" -ForegroundColor Green
    } catch {
        Write-Host "✗ AAR file is corrupted!" -ForegroundColor Red
        Write-Host "  Please re-download the file" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ AAR file not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download AndroidLibXrayLite AAR:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Manual download" -ForegroundColor Cyan
    Write-Host "  1. Visit: https://github.com/2dust/AndroidLibXrayLite/releases" -ForegroundColor Gray
    Write-Host "  2. Download: AndroidLibXrayLite-X.X.XX.aar" -ForegroundColor Gray
    Write-Host "  3. Place in: android/app/libs/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Use Gradle (automatic)" -ForegroundColor Cyan
    Write-Host "  Add to android/build.gradle.kts:" -ForegroundColor Gray
    Write-Host "  maven { url = uri(`"https://jitpack.io`") }" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See ANDROID_XRAY_SETUP.md for details" -ForegroundColor Yellow
}
