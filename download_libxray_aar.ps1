# Скрипт для загрузки libxray.aar для Android
# Основано на AndroidLibXrayLite от 2dust

$ErrorActionPreference = "Stop"

$LIBS_DIR = "android\app\libs"
$AAR_FILE = "$LIBS_DIR\libxray.aar"

Write-Host "=== Загрузка libxray.aar ===" -ForegroundColor Cyan

# Создаём директорию если её нет
if (!(Test-Path $LIBS_DIR)) {
    New-Item -ItemType Directory -Path $LIBS_DIR -Force | Out-Null
}

# Проверяем существующий файл
if (Test-Path $AAR_FILE) {
    Write-Host "✓ libxray.aar уже существует" -ForegroundColor Green
    $size = (Get-Item $AAR_FILE).Length / 1MB
    Write-Host "  Размер: $([math]::Round($size, 2)) MB"
    
    $response = Read-Host "Перезагрузить? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Пропускаем загрузку" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Получение информации о последнем релизе..." -ForegroundColor Yellow

try {
    # Получаем информацию о последнем релизе
    $releaseUrl = "https://api.github.com/repos/2dust/AndroidLibXrayLite/releases/latest"
    $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{
        "User-Agent" = "NeoTUN-Downloader"
    }
    
    $version = $release.tag_name
    Write-Host "✓ Последняя версия: $version" -ForegroundColor Green
    
    # Ищем libv2ray.aar в assets (AndroidLibXrayLite использует это имя)
    $aarAsset = $release.assets | Where-Object { $_.name -eq "libv2ray.aar" }
    
    if (!$aarAsset) {
        Write-Host "✗ libv2ray.aar не найден в релизе" -ForegroundColor Red
        Write-Host "Доступные файлы:" -ForegroundColor Yellow
        $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
        exit 1
    }
    
    $downloadUrl = $aarAsset.browser_download_url
    $fileSize = [math]::Round($aarAsset.size / 1MB, 2)
    
    Write-Host "Загрузка libxray.aar ($fileSize MB)..." -ForegroundColor Yellow
    Write-Host "URL: $downloadUrl"
    
    # Загружаем файл с прогрессом
    $tempFile = "$AAR_FILE.tmp"
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "NeoTUN-Downloader")
    
    # Регистрируем обработчик прогресса
    Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
        $percent = $EventArgs.ProgressPercentage
        Write-Progress -Activity "Загрузка libxray.aar" -Status "$percent% завершено" -PercentComplete $percent
    } | Out-Null
    
    # Загружаем файл
    $webClient.DownloadFileAsync($downloadUrl, $tempFile)
    
    # Ждём завершения
    while ($webClient.IsBusy) {
        Start-Sleep -Milliseconds 100
    }
    
    # Удаляем обработчик событий
    Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged -ErrorAction SilentlyContinue
    $webClient.Dispose()
    
    Write-Progress -Activity "Загрузка libxray.aar" -Completed
    
    # Проверяем что файл загружен
    if (!(Test-Path $tempFile)) {
        throw "Файл не был загружен"
    }
    
    # Переименовываем временный файл
    if (Test-Path $AAR_FILE) {
        Remove-Item $AAR_FILE -Force
    }
    Move-Item $tempFile $AAR_FILE -Force
    
    $downloadedSize = (Get-Item $AAR_FILE).Length / 1MB
    Write-Host "✓ libxray.aar загружен успешно ($([math]::Round($downloadedSize, 2)) MB)" -ForegroundColor Green
    Write-Host "✓ Версия: $version" -ForegroundColor Green
    Write-Host "✓ Путь: $AAR_FILE" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Ошибка: $_" -ForegroundColor Red
    
    # Удаляем временный файл если есть
    if (Test-Path "$AAR_FILE.tmp") {
        Remove-Item "$AAR_FILE.tmp" -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host ""
Write-Host "=== Готово ===" -ForegroundColor Green
Write-Host "Теперь можно собрать Android приложение с поддержкой VPN"
