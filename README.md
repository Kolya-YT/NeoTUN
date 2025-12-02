# NeoTUN

<div align="center">

<img src="assets/images/logo.png" alt="NeoTUN Logo" width="120" height="120" />

![Version](https://img.shields.io/badge/version-v1.2.2--beta.7-blue)
![Beta](https://img.shields.io/badge/beta-testing-orange)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE.txt)

**Кроссплатформенный прокси клиент для Windows и Android**

🌐 **Локализация:** Английский, Русский

[Скачать](https://github.com/Kolya-YT/NeoTUN/releases) • [Сообщить об ошибке](https://github.com/Kolya-YT/NeoTUN/issues)

</div>

## 🎨 Что нового в v1.2.2-beta.5

### Новый дизайн
- ✨ **Пользовательский логотип** - ваш логотип теперь в AppBar и Splash Screen
- 🌟 **Splash Screen** - красивый экран загрузки с анимацией
- 🎨 **Улучшенная цветовая схема** - современные градиенты Indigo → Purple
- 💎 **Material Design 3** - более профессиональный вид

### Исправления
- ✅ **Android компиляция** - исправлены все ошибки в MainActivity.kt
- ✅ **Стабильность** - улучшена работа VPN сервиса

## Возможности

### Ядро и протоколы
- **Ядро:** Xray-core (самое надёжное и популярное)
- **Протоколы:** VLESS, VMess, Trojan, Shadowsocks
- **Режимы:** Proxy Mode, TUN Mode (Android)

### Управление конфигурациями
- 📋 **Импорт из буфера обмена** - вставьте конфигурацию или share URL
- 📷 **QR сканер** - импорт через QR код
- 🔗 **Подписки** - автоматическое обновление конфигураций
- 📝 **Ручное редактирование** - JSON редактор с валидацией

### Тестирование и мониторинг
- ⚡ **Тест скорости** - проверка пинга и задержки для каждой конфигурации
- 🔄 **Тест всех конфигураций** - массовое тестирование
- 📊 **Статистика трафика** - отслеживание использования данных
- 🔌 **Автопереподключение** - автоматическое восстановление соединения

### Интерфейс
- 🎨 **Material Design 3** - современный дизайн
- 🌓 **Темы** - светлая, тёмная, системная
- 🌐 **Локализация** - английский, русский
- 📱 **Адаптивный UI** - оптимизирован для всех размеров экранов

### Платформы
- **Windows:** x64
- **Android:** arm64-v8a, armeabi-v7a, x86_64

## Установка

**Windows:** Скачайте `NeoTUN-Windows-x64.zip` из [релизов](https://github.com/Kolya-YT/NeoTUN/releases), распакуйте и запустите `neotun.exe`

**Android:** Скачайте APK из [релизов](https://github.com/Kolya-YT/NeoTUN/releases) и установите

## Быстрый старт

### Добавление конфигурации

**Способ 1: Импорт из буфера обмена**
1. Скопируйте конфигурацию (JSON, share URL или subscription URL)
2. Нажмите `+` → "Импорт из буфера"
3. Конфигурация автоматически распознается и добавляется

**Способ 2: QR сканер**
1. Нажмите `+` → "QR сканер"
2. Отсканируйте QR код с конфигурацией

**Способ 3: Ручное добавление**
1. Нажмите `+` → "Добавить конфигурацию"
2. Введите имя и JSON конфигурацию
3. Сохраните

### Подключение

1. Выберите конфигурацию из списка
2. (Опционально) Нажмите кнопку теста для проверки
3. Нажмите кнопку подключения
4. Проверьте подключение в браузере

### Тестирование

- **Одна конфигурация:** Нажмите иконку ⚡ рядом с конфигурацией
- **Все конфигурации:** Нажмите `+` → "Тест всех конфигураций"

## Сборка

### Требования

- Flutter SDK 3.0+
- Dart SDK 3.0+
- **Android:** Android SDK, NDK 27.0.12077973, libxray.aar
- **Windows:** Visual Studio 2022 Build Tools, xray.exe

### Android

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/Kolya-YT/NeoTUN.git
cd NeoTUN

# 2. Установите зависимости
flutter pub get

# 3. Скачайте libxray.aar (автоматически)
# Windows:
.\download_libxray.ps1
# Linux/Mac:
chmod +x download_libxray.sh
./download_libxray.sh

# 4. Соберите APK
flutter build apk --release --split-per-abi
```

Подробнее: [docs/ANDROID_SETUP.md](docs/ANDROID_SETUP.md)

### Windows

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/Kolya-YT/NeoTUN.git
cd NeoTUN

# 2. Установите зависимости
flutter pub get

# 3. Соберите приложение
flutter build windows --release

# 4. Xray-core скачается автоматически при первом запуске
# Или скачайте вручную в cores/xray.exe
```

Подробнее: [docs/WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md)

## Архитектура

### Android (v2rayNG Architecture)

```
Flutter App
    ↓ MethodChannel
MainActivity.kt
    ↓ Intent
V2rayVpnService.kt (VPN Service)
    ↓ JNI
XrayHelper.kt
    ↓ Native
libxray.so (AndroidLibXrayLite)
```

**Основано на:** [v2rayNG](https://github.com/2dust/v2rayNG)

**Ключевые компоненты:**
- `V2rayVpnService` - VPN сервис с TUN интерфейсом
- `XrayHelper` - JNI обертка для libxray.so
- `libxray.aar` - нативная библиотека Xray-core
- Kotlin Coroutines для асинхронных операций

### Windows (v2rayN Architecture)

```
Flutter App
    ↓
CoreManager
    ↓
XrayWindowsService ──→ xray.exe (Process)
    ↓
WindowsProxy ──→ Windows Registry (System Proxy)
```

**Основано на:** [v2rayN](https://github.com/2dust/v2rayN)

**Ключевые компоненты:**
- `XrayWindowsService` - управление процессом xray.exe
- `WindowsProxy` - системный прокси через WinAPI
- gRPC API для статистики трафика

**Windows:** Flutter → ProcessController → xray.exe / sing-box.exe / hysteria2.exe

## Лицензия

MIT License - см. [LICENSE.txt](LICENSE.txt)

## Благодарности

- [Xray-core](https://github.com/XTLS/Xray-core) - The best proxy core
- [Flutter](https://flutter.dev) - Beautiful cross-platform framework
