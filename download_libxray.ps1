# PowerShell скрипт для скачивания libxray.aar
# Основано на архитектуре v2rayNG

$ErrorActionPreference = "Stop"

Write-Host "=== NeoTUN - Download libxray.aar ===" -ForegroundColor Cyan
Write-Host ""

# Параметры
$GITHUB_REPO = "2dust/AndroidLibXrayLite"
$OUTPUT_DIR = "android/app/libs"
$OUTPUT_FILE = "$OUTPUT_DIR/libxray.aar"

# Создаём директорию если не существует
if (-not (Test-Path $OUTPUT_DIR)) {
    Write-Host "Creating directory: $OUTPUT_DIR" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
}

# Проверяем существующий файл
if (Test-Path $OUTPUT_FILE) {
    Write-Host "libxray.aar already exists at: $OUTPUT_FILE" -ForegroundColor Green
    $response = Read-Host "Do you want to re-download? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Skipping download." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $OUTPUT_FILE -Force
}

Write-Host "Fetching latest release info from GitHub..." -ForegroundColor Yellow

try {
    # Получаем информацию о последнем релизе
    $releaseUrl = "https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{
        "User-Agent" = "NeoTUN-Downloader"
    }
    
    $version = $release.tag_name
    Write-Host "Latest version: $version" -ForegroundColor Green
    
    # Ищем libxray.aar в assets
    $asset = $release.assets | Where-Object { $_.name -eq "libxray.aar" }
    
    if (-not $asset) {
        Write-Host "ERROR: libxray.aar not found in release assets" -ForegroundColor Red
        Write-Host "Available assets:" -ForegroundColor Yellow
        $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
        exit 1
    }
    
    $downloadUrl = $asset.browser_download_url
    $fileSize = [math]::Round($asset.size / 1MB, 2)
    
    Write-Host ""
    Write-Host "Downloading libxray.aar..." -ForegroundColor Yellow
    Write-Host "  URL: $downloadUrl" -ForegroundColor Gray
    Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
    Write-Host "  Output: $OUTPUT_FILE" -ForegroundColor Gray
    Write-Host ""
    
    # Скачиваем файл с прогресс-баром
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $OUTPUT_FILE -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    Write-Host ""
    Write-Host "✓ Successfully downloaded libxray.aar" -ForegroundColor Green
    Write-Host "  Version: $version" -ForegroundColor Gray
    Write-Host "  Location: $OUTPUT_FILE" -ForegroundColor Gray
    
    # Проверяем размер файла
    $downloadedSize = [math]::Round((Get-Item $OUTPUT_FILE).Length / 1MB, 2)
    Write-Host "  Size: $downloadedSize MB" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "You can now build the Android app:" -ForegroundColor Cyan
    Write-Host "  flutter build apk --release" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to download libxray.aar" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download:" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://github.com/$GITHUB_REPO/releases" -ForegroundColor White
    Write-Host "  2. Download libxray.aar from the latest release" -ForegroundColor White
    Write-Host "  3. Place it in: $OUTPUT_DIR" -ForegroundColor White
    exit 1
}
