# Инструкции по настройке и загрузке NeoTUN на GitHub

## Шаг 1: Установка необходимых инструментов

### 1.1 Установка Git
1. Скачайте Git с официального сайта: https://git-scm.com/download/win
2. Запустите установщик и следуйте инструкциям
3. После установки перезапустите PowerShell/Command Prompt

### 1.2 Проверка установки Git
```powershell
git --version
```

## Шаг 2: Создание репозитория на GitHub

### 2.1 Создание репозитория
1. Перейдите на https://github.com
2. Войдите в свой аккаунт или создайте новый
3. Нажмите "New repository"
4. Заполните данные:
   - **Repository name**: `NeoTUN`
   - **Description**: `Modern Cross-Platform VPN/Proxy Client`
   - **Visibility**: Public (или Private по желанию)
   - **НЕ** добавляйте README, .gitignore или лицензию (у нас уже есть файлы)
5. Нажмите "Create repository"

### 2.2 Скопируйте URL репозитория
После создания GitHub покажет URL вида:
```
https://github.com/ВАШ_USERNAME/NeoTUN.git
```

## Шаг 3: Инициализация локального репозитория

Откройте PowerShell в папке проекта и выполните:

```powershell
# Инициализация Git репозитория
git init

# Добавление удаленного репозитория (замените URL на ваш)
git remote add origin https://github.com/ВАШ_USERNAME/NeoTUN.git

# Настройка пользователя (если не настроено)
git config user.name "Ваше Имя"
git config user.email "ваш@email.com"

# Создание .gitignore файла
@"
# Build outputs
**/bin/
**/obj/
**/build/
**/out/

# IDE files
.vs/
.vscode/
*.user
*.suo
*.userosscache
*.sln.docstates

# OS files
.DS_Store
Thumbs.db

# Logs
*.log

# Temporary files
*.tmp
*.temp

# Android
*.apk
*.aab
local.properties
.gradle/
.idea/

# Windows
*.exe
*.dll
*.pdb

# Secrets (важно!)
keystore.jks
*.pfx
*.p12
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# Добавление всех файлов
git add .

# Первый коммит
git commit -m "Initial commit: NeoTUN CI/CD implementation

- Complete GitHub Actions workflows for Android and Windows
- Multi-architecture Xray-core integration
- Android APK build with signing support
- Windows EXE and MSIX packaging
- Comprehensive documentation and security features"

# Отправка на GitHub
git branch -M main
git push -u origin main
```

## Шаг 4: Настройка GitHub Secrets для подписи

### 4.1 Создание Android Keystore (для подписи APK)

```powershell
# Создание keystore (выполните в папке проекта)
keytool -genkey -v -keystore neotun.keystore -alias neotun -keyalg RSA -keysize 2048 -validity 10000

# Конвертация в Base64
$keystoreBytes = [System.IO.File]::ReadAllBytes("neotun.keystore")
$keystoreBase64 = [System.Convert]::ToBase64String($keystoreBytes)
Write-Host "ANDROID_KEYSTORE_BASE64:"
Write-Host $keystoreBase64
```

### 4.2 Создание Windows Certificate (для подписи EXE/MSIX)

```powershell
# Создание самоподписанного сертификата для тестирования
$cert = New-SelfSignedCertificate -Subject "CN=NeoTUN" -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsage DigitalSignature -Type CodeSigning

# Экспорт в PFX
$password = ConvertTo-SecureString -String "YourPassword123!" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "neotun.pfx" -Password $password

# Конвертация в Base64
$certBytes = [System.IO.File]::ReadAllBytes("neotun.pfx")
$certBase64 = [System.Convert]::ToBase64String($certBytes)
Write-Host "WINDOWS_CERTIFICATE_BASE64:"
Write-Host $certBase64
```

### 4.3 Добавление Secrets в GitHub

1. Перейдите в ваш репозиторий на GitHub
2. Откройте **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret** и добавьте:

**Android Secrets:**
- `ANDROID_KEYSTORE_BASE64` - Base64 строка из шага 4.1
- `ANDROID_KEYSTORE_PASSWORD` - пароль keystore
- `ANDROID_KEY_ALIAS` - `neotun`
- `ANDROID_KEY_PASSWORD` - пароль ключа

**Windows Secrets:**
- `WINDOWS_CERTIFICATE_BASE64` - Base64 строка из шага 4.2
- `WINDOWS_CERTIFICATE_PASSWORD` - `YourPassword123!`

## Шаг 5: Инициализация Xray-core субмодуля

```powershell
# Добавление Xray-core как субмодуль
git submodule add https://github.com/XTLS/Xray-core.git xray-core

# Инициализация субмодуля
git submodule update --init --recursive

# Коммит изменений
git add .
git commit -m "Add Xray-core submodule"
git push
```

## Шаг 6: Запуск первой сборки

### 6.1 Автоматический запуск
После push в main ветку CI автоматически запустится.

### 6.2 Ручной запуск
1. Перейдите в **Actions** в вашем GitHub репозитории
2. Выберите workflow (Android CI или Windows CI)
3. Нажмите **Run workflow**

### 6.3 Создание релиза
```powershell
# Создание тега для релиза
git tag v1.0.0
git push origin v1.0.0
```

## Шаг 7: Проверка результатов

### 7.1 Мониторинг сборки
- Перейдите в **Actions** для просмотра прогресса
- Зеленая галочка = успешная сборка
- Красный крестик = ошибка (проверьте логи)

### 7.2 Скачивание артефактов
После успешной сборки:
- **Android**: `neotun-release.apk` или `neotun-debug.apk`
- **Windows**: `neotun-windows.exe` и `neotun-windows.msix`

### 7.3 Релизы
При создании тега автоматически создается GitHub Release со всеми артефактами.

## Устранение проблем

### Ошибки сборки Android
- Проверьте правильность Android Secrets
- Убедитесь, что Xray субмодуль инициализирован

### Ошибки сборки Windows
- Проверьте правильность Windows Certificate Secrets
- Убедитесь, что .NET 8 доступен в CI

### Ошибки Xray
- Проверьте статус субмодуля: `git submodule status`
- Обновите субмодуль: `git submodule update --remote`

## Полезные команды

```powershell
# Проверка статуса
git status

# Просмотр логов
git log --oneline

# Проверка субмодулей
git submodule status

# Обновление субмодулей
git submodule update --remote

# Создание нового релиза
git tag v1.0.1
git push origin v1.0.1
```

## Следующие шаги

1. ✅ Загрузка проекта на GitHub
2. ✅ Настройка Secrets
3. ✅ Инициализация Xray субмодуля
4. ✅ Первая успешная сборка
5. 🎯 Тестирование артефактов
6. 🎯 Создание первого релиза
7. 🎯 Настройка автоматических обновлений

Удачи с запуском NeoTUN! 🚀