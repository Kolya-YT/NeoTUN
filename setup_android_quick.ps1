# Быстрая настройка Android SDK для сборки APK
Write-Host "=== Quick Android SDK Setup ===" -ForegroundColor Cyan

$ANDROID_SDK = "$env:LOCALAPPDATA\Android\Sdk"

# Создаем необходимые директории
Write-Host "Creating SDK directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$ANDROID_SDK\build-tools\34.0.0" -Force | Out-Null
New-Item -ItemType Directory -Path "$ANDROID_SDK\platforms\android-34" -Force | Out-Null
New-Item -ItemType Directory -Path "$ANDROID_SDK\cmdline-tools\latest\bin" -Force | Out-Null

# Настраиваем Flutter
Write-Host "Configuring Flutter..." -ForegroundColor Cyan
flutter config --android-sdk $ANDROID_SDK

# Создаем local.properties
Write-Host "Creating local.properties..." -ForegroundColor Cyan
$localProps = @"
sdk.dir=$ANDROID_SDK
flutter.sdk=C:\\src\\flutter
"@
$localProps | Out-File -FilePath "android\local.properties" -Encoding UTF8

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Now try: flutter build apk --debug" -ForegroundColor Yellow
