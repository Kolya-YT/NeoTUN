# Исправление проблемы с Keystore

## Проблема
```
KeytoolException: Failed to read key from store: Tag number over 30 is not supported
```

Это означает, что keystore создан с новыми алгоритмами (например, EdDSA), которые не поддерживаются в Android Gradle Plugin.

## Решение

### 1. Удалите старый keystore (если есть)
```bash
rm android/app/keystore.jks
```

### 2. Создайте новый keystore с совместимыми параметрами
```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias neotun
```

**ВАЖНО:** Используйте параметры:
- `-keyalg RSA` (не EdDSA или другие новые алгоритмы)
- `-keysize 2048` (стандартный размер)

### 3. Заполните данные при создании
```
Enter keystore password: [ваш пароль]
Re-enter new password: [ваш пароль]
What is your first and last name? [ваше имя]
What is the name of your organizational unit? [название]
What is the name of your organization? [организация]
What is the name of your City or Locality? [город]
What is the name of your State or Province? [регион]
What is the two-letter country code for this unit? [RU]
Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct? [yes]
```

### 4. Обновите GitHub Secrets

#### Конвертируйте keystore в base64:
```bash
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/keystore.jks")) | Set-Clipboard

# Linux/Mac
base64 android/app/keystore.jks | pbcopy
```

#### Обновите секреты в GitHub:
1. Перейдите в Settings → Secrets and variables → Actions
2. Обновите или создайте секреты:
   - `ANDROID_KEYSTORE_BASE64` - base64 содержимое keystore.jks
   - `ANDROID_KEYSTORE_PASSWORD` - пароль keystore
   - `ANDROID_KEY_ALIAS` - alias ключа (neotun)

### 5. Создайте key.properties локально
```bash
cat > android/key.properties << EOF
storePassword=ваш_пароль
keyPassword=ваш_пароль
keyAlias=neotun
storeFile=keystore.jks
EOF
```

### 6. Добавьте в .gitignore (если еще нет)
```
android/app/keystore.jks
android/key.properties
```

### 7. Пересоберите APK
```bash
flutter build apk --release --split-per-abi
```

## Проверка keystore
```bash
keytool -list -v -keystore android/app/keystore.jks -alias neotun
```

Должно показать:
- Signature algorithm name: SHA256withRSA (не EdDSA)
- Key algorithm: RSA
- Key size: 2048

## Альтернатива: Сборка без подписи (для тестирования)

Если нужно быстро собрать APK для тестирования, можно временно отключить подпись:

1. Закомментируйте в `android/app/build.gradle`:
```gradle
// signingConfigs {
//     release {
//         ...
//     }
// }

buildTypes {
    release {
        // signingConfig signingConfigs.release
        ...
    }
}
```

2. Соберите debug APK:
```bash
flutter build apk --debug
```
