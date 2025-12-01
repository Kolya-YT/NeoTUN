# Скрипт для создания keystore с правильными параметрами

Write-Host "=== Создание Android Keystore ===" -ForegroundColor Cyan
Write-Host ""

# Проверка наличия keytool
try {
    $null = keytool -help 2>&1
} catch {
    Write-Host "ОШИБКА: keytool не найден!" -ForegroundColor Red
    Write-Host "Установите Java JDK и добавьте его в PATH" -ForegroundColor Yellow
    exit 1
}

# Параметры
$keystorePath = "android\app\keystore.jks"
$keyAlias = "neotun"

# Удаление старого keystore если есть
if (Test-Path $keystorePath) {
    Write-Host "Найден существующий keystore. Удалить? (y/n): " -NoNewline
    $response = Read-Host
    if ($response -eq 'y') {
        Remove-Item $keystorePath -Force
        Write-Host "Старый keystore удален" -ForegroundColor Green
    } else {
        Write-Host "Отменено" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Создание нового keystore..." -ForegroundColor Cyan
Write-Host "ВАЖНО: Используйте ОДИНАКОВЫЙ пароль для keystore и ключа!" -ForegroundColor Yellow
Write-Host ""

# Создание keystore с совместимыми параметрами
keytool -genkey -v `
    -keystore $keystorePath `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias $keyAlias

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Keystore успешно создан!" -ForegroundColor Green
    Write-Host ""
    
    # Проверка keystore
    Write-Host "Проверка keystore..." -ForegroundColor Cyan
    keytool -list -v -keystore $keystorePath -alias $keyAlias
    
    Write-Host ""
    Write-Host "=== Следующие шаги ===" -ForegroundColor Cyan
    Write-Host "1. Создайте файл android/key.properties:" -ForegroundColor Yellow
    Write-Host "   storePassword=ваш_пароль"
    Write-Host "   keyPassword=ваш_пароль"
    Write-Host "   keyAlias=$keyAlias"
    Write-Host "   storeFile=keystore.jks"
    Write-Host ""
    Write-Host "2. Для GitHub Actions конвертируйте keystore в base64:" -ForegroundColor Yellow
    Write-Host "   [Convert]::ToBase64String([IO.File]::ReadAllBytes('$keystorePath')) | Set-Clipboard"
    Write-Host ""
    Write-Host "3. Обновите GitHub Secrets:" -ForegroundColor Yellow
    Write-Host "   - ANDROID_KEYSTORE_BASE64"
    Write-Host "   - ANDROID_KEYSTORE_PASSWORD"
    Write-Host "   - ANDROID_KEY_ALIAS (значение: $keyAlias)"
    Write-Host ""
    
    # Предложение создать key.properties
    Write-Host "Создать android/key.properties сейчас? (y/n): " -NoNewline
    $response = Read-Host
    if ($response -eq 'y') {
        Write-Host "Введите пароль keystore: " -NoNewline
        $password = Read-Host -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        )
        
        $keyPropertiesContent = @"
storePassword=$passwordPlain
keyPassword=$passwordPlain
keyAlias=$keyAlias
storeFile=keystore.jks
"@
        
        $keyPropertiesPath = "android\key.properties"
        $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8
        Write-Host "✓ Файл $keyPropertiesPath создан" -ForegroundColor Green
        
        # Предложение скопировать base64
        Write-Host ""
        Write-Host "Скопировать base64 keystore в буфер обмена? (y/n): " -NoNewline
        $response = Read-Host
        if ($response -eq 'y') {
            $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))
            Set-Clipboard -Value $base64
            Write-Host "✓ Base64 keystore скопирован в буфер обмена" -ForegroundColor Green
            Write-Host "Теперь вставьте его в GitHub Secret ANDROID_KEYSTORE_BASE64" -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host ""
    Write-Host "✗ Ошибка при создании keystore" -ForegroundColor Red
    exit 1
}
