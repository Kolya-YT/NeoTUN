# Скрипт автоматической установки Android SDK для NeoTUN
# Запустите от имени администратора

Write-Host "=== NeoTUN Android SDK Installer ===" -ForegroundColor Cyan
Write-Host ""

$ANDROID_SDK_ROOT = "$env:LOCALAPPDATA\Android\Sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$CMDLINE_TOOLS_ZIP = "$env:TEMP\commandlinetools.zip"

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠ Требуются права администратора!" -ForegroundColor Yellow
    Write-Host "Запустите PowerShell от имени администратора и повторите" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✓ Права администратора подтверждены" -ForegroundColor Green
Write-Host ""

# Создание директории SDK
Write-Host "Создание директории SDK..." -ForegroundColor Cyan
if (-not (Test-Path $ANDROID_SDK_ROOT)) {
    New-Item -ItemType Directory -Path $ANDROID_SDK_ROOT -Force | Out-Null
    Write-Host "✓ Директория создана: $ANDROID_SDK_ROOT" -ForegroundColor Green
} else {
    Write-Host "✓ Директория уже существует: $ANDROID_SDK_ROOT" -ForegroundColor Green
}
Write-Host ""

# Скачивание Command Line Tools
Write-Host "Скачивание Android Command Line Tools..." -ForegroundColor Cyan
Write-Host "URL: $CMDLINE_TOOLS_URL" -ForegroundColor Gray

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $CMDLINE_TOOLS_ZIP -UseBasicParsing
    Write-Host "✓ Скачано: $CMDLINE_TOOLS_ZIP" -ForegroundColor Green
} catch {
    Write-Host "✗ Ошибка скачивания: $_" -ForegroundColor Red
    pause
    exit 1
}
Write-Host ""

# Распаковка
Write-Host "Распаковка Command Line Tools..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $CMDLINE_TOOLS_ZIP -DestinationPath "$ANDROID_SDK_ROOT\cmdline-tools-temp" -Force
    
    # Перемещение в правильную структуру
    $latestDir = "$ANDROID_SDK_ROOT\cmdline-tools\latest"
    if (-not (Test-Path "$ANDROID_SDK_ROOT\cmdline-tools")) {
        New-Item -ItemType Directory -Path "$ANDROID_SDK_ROOT\cmdline-tools" -Force | Out-Null
    }
    
    if (Test-Path $latestDir) {
        Remove-Item -Path $latestDir -Recurse -Force
    }
    
    Move-Item -Path "$ANDROID_SDK_ROOT\cmdline-tools-temp\cmdline-tools" -Destination $latestDir -Force
    Remove-Item -Path "$ANDROID_SDK_ROOT\cmdline-tools-temp" -Recurse -Force
    Remove-Item -Path $CMDLINE_TOOLS_ZIP -Force
    
    Write-Host "✓ Распаковано в: $latestDir" -ForegroundColor Green
} catch {
    Write-Host "✗ Ошибка распаковки: $_" -ForegroundColor Red
    pause
    exit 1
}
Write-Host ""

# Настройка переменных окружения
Write-Host "Настройка переменных окружения..." -ForegroundColor Cyan
$env:ANDROID_HOME = $ANDROID_SDK_ROOT
$env:ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $ANDROID_SDK_ROOT, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $ANDROID_SDK_ROOT, "User")

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathsToAdd = @(
    "$ANDROID_SDK_ROOT\cmdline-tools\latest\bin",
    "$ANDROID_SDK_ROOT\platform-tools",
    "$ANDROID_SDK_ROOT\build-tools\34.0.0"
)

foreach ($pathToAdd in $pathsToAdd) {
    if ($currentPath -notlike "*$pathToAdd*") {
        $currentPath = "$currentPath;$pathToAdd"
    }
}

[Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
$env:Path = $currentPath

Write-Host "✓ Переменные окружения настроены" -ForegroundColor Green
Write-Host ""

# Установка SDK компонентов
Write-Host "Установка SDK компонентов..." -ForegroundColor Cyan
$sdkmanager = "$latestDir\bin\sdkmanager.bat"

Write-Host "Установка platform-tools..." -ForegroundColor Gray
& $sdkmanager "platform-tools" --sdk_root=$ANDROID_SDK_ROOT

Write-Host "Установка build-tools..." -ForegroundColor Gray
& $sdkmanager "build-tools;34.0.0" --sdk_root=$ANDROID_SDK_ROOT

Write-Host "Установка platforms..." -ForegroundColor Gray
& $sdkmanager "platforms;android-34" --sdk_root=$ANDROID_SDK_ROOT

Write-Host "Установка platform-tools..." -ForegroundColor Gray
& $sdkmanager "platform-tools" --sdk_root=$ANDROID_SDK_ROOT

Write-Host ""
Write-Host "✓ SDK компоненты установлены" -ForegroundColor Green
Write-Host ""

# Принятие лицензий
Write-Host "Принятие лицензий Android SDK..." -ForegroundColor Cyan
Write-Host "Нажимайте 'y' для каждой лицензии" -ForegroundColor Yellow
Write-Host ""
& $sdkmanager --licenses --sdk_root=$ANDROID_SDK_ROOT

Write-Host ""
Write-Host "✓ Лицензии приняты" -ForegroundColor Green
Write-Host ""

# Настройка Flutter
Write-Host "Настройка Flutter..." -ForegroundColor Cyan
flutter config --android-sdk $ANDROID_SDK_ROOT
Write-Host "✓ Flutter настроен" -ForegroundColor Green
Write-Host ""

# Проверка установки
Write-Host "Проверка установки..." -ForegroundColor Cyan
flutter doctor -v

Write-Host ""
Write-Host "=== Установка завершена! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Перезапустите PowerShell/Terminal" -ForegroundColor White
Write-Host "2. Выполните: flutter doctor" -ForegroundColor White
Write-Host "3. Соберите APK: flutter build apk --debug" -ForegroundColor White
Write-Host ""
Write-Host "Путь к SDK: $ANDROID_SDK_ROOT" -ForegroundColor Gray
Write-Host ""

pause
