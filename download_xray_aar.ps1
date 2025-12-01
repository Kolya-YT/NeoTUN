# Download AndroidLibXrayLite AAR
$version = "1.8.24"
$output = "android/app/libs/AndroidLibXrayLite.aar"

Write-Host "Downloading AndroidLibXrayLite $version..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "android/app/libs" | Out-Null

# Список URL для попытки загрузки
$urls = @(
    "https://github.com/2dust/AndroidLibXrayLite/releases/download/$version/AndroidLibXrayLite-$version.aar",
    "https://jitpack.io/com/github/2dust/AndroidLibXrayLite/$version/AndroidLibXrayLite-$version.aar"
)

$downloaded = $false

foreach ($url in $urls) {
    Write-Host "Trying: $url" -ForegroundColor Gray
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction Stop
        $size = (Get-Item $output).Length / 1MB
        Write-Host "✓ Downloaded successfully!" -ForegroundColor Green
        Write-Host "  Location: $output" -ForegroundColor Gray
        Write-Host "  Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
        $downloaded = $true
        break
    }
    catch {
        Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $downloaded) {
    Write-Host ""
    Write-Host "✗ All download attempts failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://github.com/2dust/AndroidLibXrayLite/releases" -ForegroundColor Gray
    Write-Host "2. Download: AndroidLibXrayLite-$version.aar" -ForegroundColor Gray
    Write-Host "3. Place in: android/app/libs/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or use Gradle automatic download (see ANDROID_XRAY_SETUP.md)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✓ Setup complete! You can now build the Android app." -ForegroundColor Green
