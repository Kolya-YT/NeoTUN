# Android Build Instructions

## Подготовка к сборке

### 1. Установка AndroidLibXrayLite

Перед сборкой Android APK необходимо установить AndroidLibXrayLite AAR.

#### Вариант A: Автоматическая загрузка (рекомендуется для CI/CD)

Добавьте в `android/build.gradle.kts`:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

И в `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.2dust:AndroidLibXrayLite:1.8.24")
}
```

#### Вариант B: Ручная загрузка

```bash
# Создать директорию
mkdir -p android/app/libs

# Скачать AAR
curl -L -o android/app/libs/AndroidLibXrayLite.aar \
  https://github.com/2dust/AndroidLibXrayLite/releases/download/1.8.24/AndroidLibXrayLite-1.8.24.aar
```

### 2. Проверка установки

```bash
# PowerShell
.\check_xray_aar.ps1

# Bash
ls -lh android/app/libs/AndroidLibXrayLite.aar
```

### 3. Сборка APK

```bash
# Установить зависимости
flutter pub get

# Собрать APK для всех архитектур
flutter build apk --release --split-per-abi

# Или для конкретной архитектуры
flutter build apk --release --target-platform android-arm64
```

## GitHub Actions

Пример workflow для автоматической сборки:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    
    - name: Download AndroidLibXrayLite
      run: |
        mkdir -p android/app/libs
        curl -L -o android/app/libs/AndroidLibXrayLite.aar \
          https://github.com/2dust/AndroidLibXrayLite/releases/download/1.8.24/AndroidLibXrayLite-1.8.24.aar
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release --split-per-abi
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: android-apk
        path: build/app/outputs/flutter-apk/*.apk
```

## Troubleshooting

### Ошибка: "libxray.so not found"

**Причина:** AAR файл не установлен или поврежден

**Решение:**
1. Проверьте наличие файла: `android/app/libs/AndroidLibXrayLite.aar`
2. Проверьте размер файла (должен быть ~15-20 MB)
3. Пересоберите проект: `flutter clean && flutter build apk`

### Ошибка: "Failed to load Xray library"

**Причина:** Несовместимая версия AAR или архитектура

**Решение:**
1. Убедитесь что используете последнюю версию AndroidLibXrayLite
2. Проверьте что собираете для правильной архитектуры (arm64-v8a)
3. Очистите кэш Gradle: `cd android && ./gradlew clean`

### Ошибка: "Build failed. See the log at jitpack.io"

**Причина:** JitPack не может собрать библиотеку

**Решение:**
1. Используйте ручную загрузку AAR вместо JitPack
2. Или используйте другую версию библиотеки

## Размер APK

С AndroidLibXrayLite размер APK увеличивается:

- **Без библиотеки:** ~15 MB
- **С библиотекой:** ~30-35 MB

Для оптимизации используйте split APK:
```bash
flutter build apk --release --split-per-abi
```

Это создаст отдельные APK для каждой архитектуры:
- `app-arm64-v8a-release.apk` (~20 MB) - для современных устройств
- `app-armeabi-v7a-release.apk` (~18 MB) - для старых устройств
- `app-x86_64-release.apk` (~22 MB) - для эмуляторов

## Версии

| Компонент | Версия |
|-----------|--------|
| Flutter | 3.24.0+ |
| Dart | 3.10.0+ |
| Android SDK | 21+ (минимум) |
| Android SDK | 34 (target) |
| Java | 17 |
| Kotlin | 1.9.0+ |
| AndroidLibXrayLite | 1.8.24 |

## Ссылки

- [AndroidLibXrayLite Releases](https://github.com/2dust/AndroidLibXrayLite/releases)
- [Flutter Build APK](https://docs.flutter.dev/deployment/android)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
