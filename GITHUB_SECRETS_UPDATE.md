# 🔐 Обновление GitHub Secrets

## ✅ Keystore создан успешно!

Keystore создан с правильными параметрами:
- **Алгоритм:** RSA-2048 (совместимый)
- **Подпись:** SHA256withRSA
- **Alias:** neotun
- **Пароль:** neotuns
- **Срок действия:** 27 лет (до 2053 года)

## 📋 Шаги для обновления GitHub Secrets

### 1. Откройте настройки репозитория
Перейдите по ссылке:
```
https://github.com/Kolya-YT/NeoTUN/settings/secrets/actions
```

### 2. Обновите или создайте следующие секреты:

#### ANDROID_KEYSTORE_BASE64
Значение находится в файле `keystore_base64.txt` (уже создан в корне проекта)

**Скопируйте содержимое файла полностью** (это длинная строка base64)

#### ANDROID_KEYSTORE_PASSWORD
```
neotuns
```

#### ANDROID_KEY_ALIAS
```
neotun
```

### 3. Проверьте секреты
После добавления у вас должно быть 3 секрета:
- ✅ ANDROID_KEYSTORE_BASE64
- ✅ ANDROID_KEYSTORE_PASSWORD
- ✅ ANDROID_KEY_ALIAS

## 🚀 Запуск сборки

После обновления секретов пересоздайте тег для запуска GitHub Actions:

```bash
git add .
git commit -m "Update keystore configuration"
git push

# Пересоздайте тег
git tag -d v1.1.0
git push origin :refs/tags/v1.1.0
git tag v1.1.0
git push origin v1.1.0
```

Или создайте новый тег:
```bash
git tag v1.1.1
git push origin v1.1.1
```

## 🧪 Локальная проверка

Перед пушем можно проверить локально:
```bash
flutter build apk --release --split-per-abi
```

APK файлы будут в:
```
build/app/outputs/flutter-apk/
```

## 📝 Что было сделано

1. ✅ Создан новый keystore с RSA-2048
2. ✅ Создан файл `android/key.properties`
3. ✅ Конвертирован keystore в base64
4. ✅ Обновлен `.gitignore` для защиты keystore
5. ✅ Обновлен workflow с проверкой keystore

## ⚠️ Важно

- **НЕ коммитьте** файлы `keystore.jks` и `key.properties` в Git!
- Они уже добавлены в `.gitignore`
- Храните пароль `neotuns` в безопасном месте
- Base64 keystore используется только для GitHub Actions

## 🔍 Проверка keystore

Если нужно проверить keystore:
```bash
keytool -list -v -keystore android\app\keystore.jks -storepass neotuns -alias neotun
```

Должно показать:
```
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
```

## ❓ Проблемы?

Если сборка все еще не работает:
1. Убедитесь, что все 3 секрета добавлены в GitHub
2. Проверьте, что base64 скопирован полностью (без пробелов и переносов)
3. Проверьте логи GitHub Actions для деталей
4. Попробуйте локальную сборку для проверки keystore
