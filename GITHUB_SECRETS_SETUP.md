# Настройка GitHub Secrets для NeoTUN

## Обязательные секреты для CI/CD

Для полноценной работы CI/CD pipeline необходимо настроить следующие секреты в GitHub:

### 🔐 Как добавить секреты

1. Перейдите в ваш репозиторий на GitHub: https://github.com/Kolya-YT/NeoTUN
2. Откройте **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**
4. Введите имя и значение секрета
5. Нажмите **Add secret**

## 📱 Android Signing Secrets

### ANDROID_KEYSTORE_BASE64
**Описание**: Base64-кодированный Android keystore файл  
**Получение**: Создайте keystore с помощью keytool (требует Java)

```bash
# Если у вас установлена Java
keytool -genkey -v -keystore neotun.keystore -alias neotun -keyalg RSA -keysize 2048 -validity 10000

# Конвертация в Base64 (Windows PowerShell)
$keystoreBytes = [System.IO.File]::ReadAllBytes("neotun.keystore")
$keystoreBase64 = [System.Convert]::ToBase64String($keystoreBytes)
Write-Host $keystoreBase64
```

### ANDROID_KEYSTORE_PASSWORD
**Описание**: Пароль для keystore файла  
**Значение**: Пароль, который вы указали при создании keystore

### ANDROID_KEY_ALIAS  
**Описание**: Алиас ключа в keystore  
**Значение**: `neotun` (или тот, который вы указали при создании)

### ANDROID_KEY_PASSWORD
**Описание**: Пароль для ключа  
**Значение**: Пароль ключа (обычно такой же как у keystore)

## 🪟 Windows Signing Secrets

### WINDOWS_CERTIFICATE_BASE64
**Описание**: Base64-кодированный PFX сертификат для подписи  
**Значение**: Уже создан! Используйте эту строку:

```
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
```

### WINDOWS_CERTIFICATE_PASSWORD
**Описание**: Пароль для PFX сертификата  
**Значение**: `NeoTUN2024!`

## ⚠️ Важные замечания

### Безопасность
- **НИКОГДА** не коммитьте секреты в Git репозиторий
- Используйте сложные пароли
- Регулярно обновляйте сертификаты

### Тестирование без секретов
Если вы не настроите секреты:
- ✅ **Android Debug APK** будет собираться (без подписи)
- ❌ **Android Release APK** не будет собираться
- ❌ **Windows MSIX** не будет подписываться

### Альтернативы для Android
Если у вас нет Java для создания keystore:
1. Установите Java: https://adoptium.net/
2. Или используйте Android Studio (включает keytool)
3. Или временно закомментируйте подпись в workflow

## 🚀 После настройки секретов

1. Перейдите в **Actions** в вашем репозитории
2. Запустите workflow вручную или сделайте push
3. Проверьте, что сборка проходит успешно
4. Скачайте артефакты из успешной сборки

## 📋 Проверочный список

- [ ] ANDROID_KEYSTORE_BASE64 добавлен
- [ ] ANDROID_KEYSTORE_PASSWORD добавлен  
- [ ] ANDROID_KEY_ALIAS добавлен
- [ ] ANDROID_KEY_PASSWORD добавлен
- [ ] WINDOWS_CERTIFICATE_BASE64 добавлен
- [ ] WINDOWS_CERTIFICATE_PASSWORD добавлен
- [ ] Запущена тестовая сборка
- [ ] Артефакты успешно созданы

## 🔧 Устранение проблем

### Android сборка падает
- Проверьте правильность всех Android секретов
- Убедитесь, что keystore создан корректно
- Проверьте соответствие алиаса и паролей

### Windows подпись не работает
- Проверьте формат PFX сертификата
- Убедитесь в правильности пароля
- Для production используйте сертификат от CA

### Общие проблемы
- Проверьте логи в Actions
- Убедитесь, что Xray субмодуль инициализирован
- Проверьте актуальность версий actions

Удачи с настройкой! 🎉