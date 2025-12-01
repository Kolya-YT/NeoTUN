# 🔧 Быстрое исправление ошибки сборки

## Проблема
```
KeytoolException: Failed to read key from store: Tag number over 30 is not supported
```

## ⚡ Быстрое решение (5 минут)

### Шаг 1: Создайте новый keystore
```powershell
# Запустите скрипт
.\create_keystore.ps1
```

Или вручную:
```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias neotun
```

**ВАЖНО:** Запомните пароль! Используйте ОДИНАКОВЫЙ пароль для keystore и ключа.

### Шаг 2: Создайте key.properties
Создайте файл `android/key.properties`:
```properties
storePassword=ваш_пароль_из_шага_1
keyPassword=ваш_пароль_из_шага_1
keyAlias=neotun
storeFile=keystore.jks
```

### Шаг 3: Обновите GitHub Secrets

#### 3.1 Конвертируйте keystore в base64:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/keystore.jks")) | Set-Clipboard
```

#### 3.2 Обновите секреты:
1. Откройте: https://github.com/ваш-username/NeoTUN/settings/secrets/actions
2. Обновите или создайте:
   - `ANDROID_KEYSTORE_BASE64` → вставьте из буфера обмена
   - `ANDROID_KEYSTORE_PASSWORD` → ваш пароль
   - `ANDROID_KEY_ALIAS` → `neotun`

### Шаг 4: Пересоберите
```bash
# Локально
flutter build apk --release --split-per-abi

# Или создайте новый тег для GitHub Actions
git tag -d v1.1.0
git push origin :refs/tags/v1.1.0
git tag v1.1.0
git push origin v1.1.0
```

## 🎯 Проверка

После создания keystore проверьте его:
```bash
keytool -list -v -keystore android/app/keystore.jks -alias neotun
```

Должно быть:
- ✅ Signature algorithm: SHA256withRSA
- ✅ Key algorithm: RSA
- ❌ НЕ EdDSA или другие новые алгоритмы

## 🚀 Альтернатива: Debug сборка (для тестирования)

Если нужно быстро протестировать без подписи:
```bash
flutter build apk --debug
```

Debug APK будет подписан автоматически отладочным ключом.

## 📝 Что пошло не так?

Старый keystore был создан с новым алгоритмом EdDSA, который не поддерживается Android Gradle Plugin. Новый keystore использует проверенный RSA-2048, который работает везде.

## ❓ Нужна помощь?

Если что-то не работает:
1. Проверьте, что Java JDK установлен: `keytool -help`
2. Убедитесь, что пароли совпадают в key.properties и при создании keystore
3. Проверьте, что base64 скопирован полностью (без переносов строк)
4. Посмотрите логи GitHub Actions для деталей ошибки
