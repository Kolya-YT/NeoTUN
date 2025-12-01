# Быстрый старт - Android сборка

## Шаг 1: Установка AndroidLibXrayLite

Выберите один из вариантов:

### Вариант A: Автоматическая загрузка (рекомендуется)

```powershell
.\download_xray_aar.ps1
```

### Вариант B: Ручная загрузка

1. Перейдите на https://github.com/2dust/AndroidLibXrayLite/releases
2. Скачайте `AndroidLibXrayLite-1.8.24.aar`
3. Поместите в `android/app/libs/`

### Вариант C: Gradle (автоматически при сборке)

Уже настроено в `android/app/build.gradle.kts` - ничего делать не нужно!

## Шаг 2: Проверка

```powershell
.\check_xray_aar.ps1
```

Должно показать:
```
✓ AAR file found: android/app/libs/AndroidLibXrayLite.aar
  Size: ~15-20 MB
✓ AAR file is valid!
```

## Шаг 3: Сборка APK

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## Шаг 4: Установка на устройство

APK файлы будут в `build/app/outputs/flutter-apk/`:

- `app-arm64-v8a-release.apk` - для современных устройств (рекомендуется)
- `app-armeabi-v7a-release.apk` - для старых устройств
- `app-x86_64-release.apk` - для эмуляторов

## Проверка работы

После установки и запуска приложения проверьте логи:

```bash
adb logcat | grep -E "XrayHelper|VpnService"
```

Должно быть:
```
I/XrayHelper: ✓ Xray native library loaded
I/VpnService: Using native AndroidLibXrayLite
I/VpnService: ✓ Native Xray started successfully
I/VpnService: Xray version: 1.8.24
```

## Troubleshooting

### Проблема: "libxray.so not found"

**Решение:**
```bash
# Проверьте наличие AAR
ls -lh android/app/libs/AndroidLibXrayLite.aar

# Пересоберите
flutter clean
flutter pub get
flutter build apk --release
```

### Проблема: "Failed to load Xray library"

**Решение:**
1. Убедитесь что AAR файл не поврежден (размер ~15-20 MB)
2. Очистите кэш Gradle:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```
3. Пересоберите проект

### Проблема: Приложение крашится при запуске Xray

**Решение:**
1. Проверьте логи: `adb logcat`
2. Убедитесь что конфигурация валидна
3. Попробуйте TUN режим вместо Proxy

## Дополнительная информация

- [Подробная документация](ANDROID_XRAY_SETUP.md)
- [История проблем](ANDROID_ISSUE.md)
- [CI/CD инструкции](.github/ANDROID_BUILD.md)

## Что дальше?

После успешной сборки:

1. Протестируйте на реальном устройстве
2. Проверьте работу Xray подключения
3. Проверьте TUN режим
4. Создайте release на GitHub

## Важно!

- **Windows версия** использует обычный `xray.exe` - никаких изменений не требуется
- **Android версия** использует `AndroidLibXrayLite` (libxray.so) - требует AAR файл
- Для sing-box и Hysteria2 на Android пока используется старый метод (требует TUN или root)
