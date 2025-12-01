# Настройка AndroidLibXrayLite

## Обзор

Для работы Xray на Android используется нативная библиотека **AndroidLibXrayLite** вместо исполняемых файлов. Это решает проблему с SELinux permissions на Android.

## Почему AndroidLibXrayLite?

- ✅ Работает без root доступа
- ✅ Нет проблем с SELinux
- ✅ Используется в v2rayNG и других популярных приложениях
- ✅ Официальная библиотека от разработчиков Xray

## Установка AAR файла

### Вариант 1: Автоматическая загрузка через Gradle (Рекомендуется)

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

Затем в `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.2dust:AndroidLibXrayLite:1.8.24")
}
```

### Вариант 2: Ручная загрузка AAR

1. Скачайте AAR файл с GitHub:
   - Перейдите на https://github.com/2dust/AndroidLibXrayLite/releases
   - Скачайте последнюю версию `AndroidLibXrayLite-X.X.XX.aar`

2. Поместите файл в `android/app/libs/AndroidLibXrayLite.aar`

3. Убедитесь что в `android/app/build.gradle.kts` есть:
   ```kotlin
   dependencies {
       implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
   }
   ```

### Вариант 3: Использование PowerShell скрипта

```powershell
# Запустите из корня проекта
.\download_xray_aar.ps1
```

## Проверка установки

После установки AAR файла:

1. Синхронизируйте Gradle:
   ```bash
   cd android
   ./gradlew clean
   ./gradlew build
   ```

2. Проверьте логи при запуске приложения:
   ```
   I/XrayHelper: ✓ Xray native library loaded
   I/VpnService: Using native AndroidLibXrayLite
   I/VpnService: ✓ Native Xray started successfully
   ```

## Архитектура

### Android (с AndroidLibXrayLite)
```
Flutter App
    ↓
MethodChannel
    ↓
VpnService.kt / TunVpnService.kt
    ↓
XrayHelper.kt (wrapper)
    ↓
libxray.so (AndroidLibXrayLite)
```

### Windows (обычный Xray)
```
Flutter App
    ↓
ProcessController
    ↓
Process.start()
    ↓
xray.exe
```

## Поддерживаемые ядра

| Ядро | Android | Windows |
|------|---------|---------|
| Xray | ✅ AndroidLibXrayLite (native) | ✅ xray.exe |
| sing-box | ⚠️ Process (требует root) | ✅ sing-box.exe |
| Hysteria2 | ⚠️ Process (требует root) | ✅ hysteria2.exe |

## Известные проблемы

1. **sing-box и Hysteria2 на Android**: Пока используют старый метод через Process, требуют root или TUN режим
2. **Размер APK**: AndroidLibXrayLite добавляет ~15-20 MB к размеру APK

## Будущие улучшения

- [ ] Интегрировать sing-box native library
- [ ] Интегрировать Hysteria2 native library
- [ ] Оптимизировать размер APK (использовать splits для разных архитектур)

## Ссылки

- [AndroidLibXrayLite GitHub](https://github.com/2dust/AndroidLibXrayLite)
- [v2rayNG (пример использования)](https://github.com/2dust/v2rayNG)
- [Xray-core](https://github.com/XTLS/Xray-core)
