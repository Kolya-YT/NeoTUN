# Инструкции по сборке NeoTUN

## 🎯 Быстрый старт

### Windows

```bash
# 1. Установить зависимости
flutter pub get

# 2. Собрать
flutter build windows --release

# 3. Найти результат
# build/windows/x64/runner/Release/
```

### Android

```bash
# 1. Установить AndroidLibXrayLite AAR
.\download_xray_aar.ps1

# 2. Проверить установку
.\check_xray_aar.ps1

# 3. Установить зависимости
flutter pub get

# 4. Собрать APK
flutter build apk --release --split-per-abi

# 5. Найти результат
# build/app/outputs/flutter-apk/
```

## 📋 Детальные инструкции

### Требования

**Общее:**
- Flutter 3.24.0+
- Dart 3.10.0+
- Git

**Для Windows:**
- Visual Studio 2022 с C++ workload
- Windows 10/11

**Для Android:**
- Android SDK (API 21+)
- Java JDK 17
- Android Studio (опционально)

### Установка Flutter

```bash
# Проверить установку
flutter doctor

# Должно показать:
# [✓] Flutter (Channel stable, 3.24.0)
# [✓] Windows Version (Windows 10 or later)
# [✓] Android toolchain
# [✓] Visual Studio
```

### Клонирование проекта

```bash
git clone https://github.com/Kolya-YT/NeoTUN.git
cd NeoTUN
flutter pub get
```

## 🪟 Сборка для Windows

### Вариант 1: Release сборка

```bash
flutter build windows --release
```

Результат: `build/windows/x64/runner/Release/`

### Вариант 2: Debug сборка

```bash
flutter build windows --debug
```

### Вариант 3: Запуск без сборки

```bash
flutter run -d windows
```

### Создание portable версии

```bash
# 1. Собрать
flutter build windows --release

# 2. Скопировать ядра
mkdir build/windows/x64/runner/Release/cores

# 3. Создать ZIP
# Упаковать папку build/windows/x64/runner/Release/
# в NeoTUN-Windows-x64.zip
```

## 📱 Сборка для Android

### Шаг 1: Установка AndroidLibXrayLite

**Автоматически (рекомендуется):**
```powershell
.\download_xray_aar.ps1
```

**Вручную:**
1. Скачать с https://github.com/2dust/AndroidLibXrayLite/releases
2. Поместить в `android/app/libs/AndroidLibXrayLite.aar`

**Проверка:**
```powershell
.\check_xray_aar.ps1
```

### Шаг 2: Сборка APK

**Все архитектуры (split APK):**
```bash
flutter build apk --release --split-per-abi
```

Результат:
- `app-arm64-v8a-release.apk` (~20 MB) - современные устройства
- `app-armeabi-v7a-release.apk` (~18 MB) - старые устройства
- `app-x86_64-release.apk` (~22 MB) - эмуляторы

**Одна архитектура:**
```bash
# Только arm64 (рекомендуется)
flutter build apk --release --target-platform android-arm64

# Только arm32
flutter build apk --release --target-platform android-arm

# Только x64
flutter build apk --release --target-platform android-x64
```

**Fat APK (все архитектуры в одном файле):**
```bash
flutter build apk --release
```

Результат: `app-release.apk` (~50 MB)

### Шаг 3: Подписание APK (опционально)

Для публикации в Google Play или для production:

1. Создать keystore:
```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias neotun
```

2. Создать `android/key.properties`:
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=neotun
storeFile=keystore.jks
```

3. Собрать подписанный APK:
```bash
flutter build apk --release --split-per-abi
```

### Шаг 4: Установка на устройство

**Через ADB:**
```bash
# Подключить устройство
adb devices

# Установить APK
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

**Вручную:**
1. Скопировать APK на устройство
2. Открыть файл
3. Разрешить установку из неизвестных источников
4. Установить

## 🧪 Тестирование

### Windows

```bash
# Запустить в debug режиме
flutter run -d windows

# Проверить логи
# Логи отображаются в консоли
```

### Android

```bash
# Запустить на подключенном устройстве
flutter run -d <device_id>

# Проверить логи
adb logcat | grep -E "XrayHelper|VpnService|Flutter"

# Проверить нативную библиотеку
adb logcat | grep XrayHelper
# Должно быть: I/XrayHelper: ✓ Xray native library loaded
```

## 🐛 Troubleshooting

### Windows

**Проблема:** "Visual Studio not found"
```bash
# Установить Visual Studio 2022 Community
# Включить "Desktop development with C++"
```

**Проблема:** "CMake not found"
```bash
# Установить через Visual Studio Installer
# Individual components → CMake tools for Windows
```

### Android

**Проблема:** "libxray.so not found"
```bash
# Проверить AAR
.\check_xray_aar.ps1

# Пересобрать
flutter clean
flutter pub get
flutter build apk --release
```

**Проблема:** "SDK not found"
```bash
# Установить Android SDK
flutter doctor --android-licenses
```

**Проблема:** "Gradle build failed"
```bash
# Очистить кэш
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## 📦 Размеры сборок

### Windows
- Release: ~25 MB (без ядер)
- С ядрами: ~50-70 MB
- Portable ZIP: ~60-80 MB

### Android
- Split APK (arm64): ~20 MB
- Split APK (arm32): ~18 MB
- Split APK (x64): ~22 MB
- Fat APK: ~50 MB

## 🚀 CI/CD

Для автоматической сборки см.:
- `.github/workflows/build.yml` - автоматическая сборка
- `.github/workflows/release.yml` - создание релизов
- `.github/ANDROID_BUILD.md` - детали Android CI/CD

## 📚 Дополнительная информация

- [ANDROID_XRAY_SETUP.md](ANDROID_XRAY_SETUP.md) - настройка Android
- [QUICK_START_ANDROID.md](QUICK_START_ANDROID.md) - быстрый старт Android
- [README.md](README.md) - общая информация
- [CHANGELOG.md](CHANGELOG.md) - история изменений

## 💡 Советы

1. **Используйте split APK** для уменьшения размера
2. **Тестируйте на реальных устройствах** перед релизом
3. **Проверяйте логи** при возникновении проблем
4. **Обновляйте зависимости** регулярно
5. **Делайте backup** keystore файла

## 📞 Поддержка

При возникновении проблем:
1. Проверьте документацию
2. Проверьте логи
3. Создайте issue на GitHub
4. Приложите логи и описание проблемы

---

**Удачной сборки! 🚀**
