# NeoTUN

<div align="center">

![NeoTUN Logo](https://via.placeholder.com/150x150?text=NeoTUN)

**Современный кроссплатформенный VPN клиент с поддержкой XRay, sing-box и Hysteria2**

[![Build Status](https://github.com/yourusername/neotun/workflows/Build%20and%20Release/badge.svg)](https://github.com/yourusername/neotun/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)

[English](#english) | [Русский](#russian)

</div>

---

## 🌟 Особенности

- **🚀 Кроссплатформенность**: Windows EXE + Android APK из единой кодовой базы
- **⚡ Множественные ядра**: XRay-core, sing-box, hysteria2
- **🎨 Modern UI**: Material Design 3 с темной темой
- **🔄 Автообновления**: Приложения и ядер с проверкой SHA256
- **📡 Подписки**: Импорт/экспорт конфигураций, автообновление подписок
- **🛣️ Маршрутизация**: Smart routing, geosite/geoip, по приложениям (Android)
- **🔧 Редактор конфигов**: Визуальный редактор + JSON режим
- **📊 Статистика**: Мониторинг трафика в реальном времени
- **🔐 Безопасность**: Проверка подписей, изолированные процессы
- **🌐 Системный прокси**: PAC, global, direct режимы

---

## 📋 Содержание

- [Установка](#установка)
- [Быстрый старт](#быстрый-старт)
- [Архитектура](#архитектура)
- [Сборка проекта](#сборка-проекта)
- [Разработка](#разработка)
- [GitHub Actions](#github-actions)
- [Конфигурация](#конфигурация)
- [FAQ](#faq)
- [Лицензия](#лицензия)

---

## 🚀 Установка

### Windows

1. Скачайте последнюю версию `NeoTUN-Windows-x64.zip` из [Releases](https://github.com/yourusername/neotun/releases)
2. Распакуйте архив
3. Запустите `neotun.exe`

### Android

1. Скачайте `app-arm64-v8a-release.apk` из [Releases](https://github.com/yourusername/neotun/releases)
2. Установите APK (разрешите установку из неизвестных источников)
3. Запустите приложение

---

## ⚡ Быстрый старт

### 1. Установка ядер

При первом запуске:
1. Перейдите в **Settings → Cores**
2. Нажмите **Download** для нужного ядра (XRay/sing-box/hysteria2)
3. Дождитесь завершения загрузки

### 2. Добавление конфигурации

**Способ 1: Импорт подписки**
```
Home → + → Import Subscription → Вставьте URL → Import
```

**Способ 2: QR код**
```
Home → + → Scan QR Code → Отсканируйте код
```

**Способ 3: Ручное создание**
```
Home → + → Manual Config → Заполните параметры → Save
```

### 3. Подключение

1. Выберите конфигурацию из списка
2. Нажмите **Connect**
3. Проверьте статус подключения

---

## 🏗️ Архитектура

```
neotun/
├── lib/
│   ├── main.dart                    # Точка входа
│   ├── models/                      # Модели данных
│   │   ├── vpn_config.dart         # Конфигурация VPN
│   │   ├── core_type.dart          # Типы ядер
│   │   ├── core_manifest.dart      # Манифест ядер
│   │   └── update_manifest.dart    # Манифест обновлений
│   ├── services/                    # Бизнес-логика
│   │   ├── core_manager.dart       # Управление ядрами
│   │   ├── process_controller.dart # Контроль процессов
│   │   ├── config_storage.dart     # Хранение конфигов
│   │   ├── update_service.dart     # Обновления
│   │   ├── subscription_parser.dart # Парсинг подписок
│   │   ├── routing_manager.dart    # Маршрутизация
│   │   ├── system_proxy.dart       # Системный прокси
│   │   ├── download_service.dart   # Загрузка файлов
│   │   └── config_templates.dart   # Шаблоны конфигов
│   └── screens/                     # UI экраны
│       ├── home_screen.dart        # Главный экран
│       ├── config_editor_screen.dart # Редактор конфигов
│       ├── cores_screen.dart       # Управление ядрами
│       ├── settings_screen.dart    # Настройки
│       └── qr_scanner_screen.dart  # Сканер QR
├── android/
│   └── app/src/main/kotlin/com/neotun/app/
│       ├── MainActivity.kt         # Главная активность
│       └── VpnService.kt          # Foreground Service
├── windows/                         # Windows специфичный код
├── cores/                          # Бинарные файлы ядер
├── .github/workflows/              # CI/CD
│   ├── build.yml                  # Сборка
│   └── release.yml                # Релиз
├── cores_manifest.json            # Манифест ядер
├── app_update.json               # Манифест обновлений
└── pubspec.yaml                  # Зависимости Flutter
```

### Ключевые компоненты

#### 1. CoreManager
Управляет жизненным циклом ядер:
- Загрузка и обновление
- Проверка версий
- Запуск/остановка процессов
- Health-check

#### 2. ProcessController
Контролирует процессы ядер:
- Кроссплатформенный запуск
- Мониторинг логов
- Graceful shutdown
- Android VPN Service интеграция

#### 3. ConfigStorage
Хранение и управление конфигурациями:
- CRUD операции
- Импорт/экспорт
- Группировка и теги

#### 4. UpdateService
Система обновлений:
- Проверка новых версий
- Загрузка с проверкой SHA256
- Atomic updates с rollback

---

## 🔨 Сборка проекта

### Требования

- **Flutter SDK**: 3.19.0 или выше
- **Dart SDK**: 3.0.0 или выше
- **Android Studio** (для Android)
- **Visual Studio 2022** (для Windows)
- **Git**

### Установка зависимостей

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/neotun.git
cd neotun

# Установите зависимости
flutter pub get
```

### Сборка для Windows

```bash
# Debug сборка
flutter build windows --debug

# Release сборка
flutter build windows --release

# Результат: build/windows/x64/runner/Release/
```

### Сборка для Android

```bash
# Debug APK
flutter build apk --debug

# Release APK (требуется keystore)
flutter build apk --release --split-per-abi

# Результат: build/app/outputs/flutter-apk/
```

### Создание keystore для Android

```bash
keytool -genkey -v -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias neotun

# Создайте android/key.properties:
storePassword=your_password
keyPassword=your_password
keyAlias=neotun
storeFile=keystore.jks
```

---

## 👨‍💻 Разработка

### Запуск в режиме разработки

```bash
# Windows
flutter run -d windows

# Android (подключите устройство или эмулятор)
flutter run -d android

# Список устройств
flutter devices
```

### Структура кода

**Добавление нового ядра:**

1. Обновите `CoreType` enum в `lib/models/core_type.dart`
2. Добавьте шаблон в `lib/services/config_templates.dart`
3. Обновите `cores_manifest.json`

**Добавление нового протокола:**

1. Добавьте парсер в `lib/services/subscription_parser.dart`
2. Создайте шаблон в `lib/services/config_templates.dart`
3. Обновите UI в `lib/screens/config_editor_screen.dart`

### Тестирование

```bash
# Запуск тестов
flutter test

# Анализ кода
flutter analyze

# Форматирование
flutter format lib/
```

---

## 🤖 GitHub Actions

### Workflow структура

#### 1. Build Workflow (`.github/workflows/build.yml`)
Запускается при push в main:
- Сборка Android APK
- Сборка Windows EXE
- Загрузка артефактов

#### 2. Release Workflow (`.github/workflows/release.yml`)
Запускается при создании тега `v*.*.*`:
- Сборка подписанных релизов
- Создание GitHub Release
- Публикация APK и ZIP
- Обновление манифестов

### Настройка Secrets

В GitHub Settings → Secrets добавьте:

```
ANDROID_KEYSTORE_BASE64    # base64 encoded keystore.jks
ANDROID_KEYSTORE_PASSWORD  # Пароль keystore
ANDROID_KEY_ALIAS          # Алиас ключа
```

Создание base64 keystore:
```bash
base64 -i android/app/keystore.jks | pbcopy  # macOS
base64 -w 0 android/app/keystore.jks          # Linux
certutil -encode keystore.jks keystore.txt    # Windows
```

### Создание релиза

```bash
# Обновите версию в pubspec.yaml
version: 1.0.1+2

# Создайте тег
git tag v1.0.1
git push origin v1.0.1

# GitHub Actions автоматически создаст релиз
```

---

## ⚙️ Конфигурация

### Манифест ядер (`cores_manifest.json`)

```json
{
  "platforms": {
    "windows-x64": {
      "xray": {
        "version": "1.8.8",
        "url": "https://github.com/XTLS/Xray-core/releases/download/v1.8.8/Xray-windows-64.zip",
        "sha256": "actual_sha256_hash"
      }
    }
  }
}
```

### Манифест обновлений (`app_update.json`)

```json
{
  "latest_version": "1.0.0",
  "notes": "Initial release",
  "platforms": {
    "windows-x64": {
      "url": "https://github.com/yourusername/neotun/releases/download/v1.0.0/NeoTUN-Windows-x64.zip",
      "sha256": "actual_sha256_hash"
    }
  }
}
```

### Примеры конфигураций

**XRay VLESS:**
```json
{
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "example.com",
        "port": 443,
        "users": [{
          "id": "uuid-here",
          "encryption": "none"
        }]
      }]
    }
  }]
}
```

**sing-box Shadowsocks:**
```json
{
  "outbounds": [{
    "type": "shadowsocks",
    "server": "example.com",
    "server_port": 8388,
    "method": "aes-256-gcm",
    "password": "password"
  }]
}
```

**Hysteria2:**
```json
{
  "server": "example.com:443",
  "auth": "password",
  "tls": {
    "sni": "example.com"
  }
}
```

---

## 📱 Использование

### Импорт подписки

```dart
// Программный импорт
final configs = await SubscriptionParser.instance
    .parseSubscriptionUrl('https://example.com/sub');

for (final config in configs) {
  await ConfigStorage.instance.saveConfig(config);
}
```

### Запуск ядра

```dart
// Выберите конфигурацию
final config = ConfigStorage.instance.getConfigs().first;

// Запустите ядро
await CoreManager.instance.startCore(config);

// Мониторинг логов
CoreManager.instance.logStream.listen((log) {
  print(log);
});

// Остановка
await CoreManager.instance.stopCore();
```

### Обновление ядра

```dart
// Проверка обновлений
final manifest = await CoreManager.instance.fetchManifest();

// Загрузка ядра
await CoreManager.instance.downloadCore(
  CoreType.xray,
  onProgress: (received, total) {
    print('Progress: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);
```

---

## 🔧 Расширенные возможности

### Smart Routing

```dart
// Настройка маршрутизации
await RoutingManager.instance.init();

final rules = ['direct', 'proxy', 'block'];
final routing = RoutingManager.instance.generateXrayRouting(rules);

// Применение к конфигурации
config.config['routing'] = routing;
```

### Системный прокси

```dart
// Включить прокси
await SystemProxy.instance.enableProxy('127.0.0.1', 10808);

// Отключить прокси
await SystemProxy.instance.disableProxy();

// Проверить статус
final isEnabled = await SystemProxy.instance.isProxyEnabled();
```

### Статистика трафика

```dart
// Мониторинг в реальном времени
ProcessController.instance.logStream.listen((log) {
  // Парсинг статистики из логов
  if (log.contains('traffic')) {
    // Обработка данных
  }
});
```

---

## 🐛 Отладка

### Логи

**Windows:**
```
%APPDATA%\neotun\logs\
```

**Android:**
```bash
adb logcat | grep NeoTUN
```

### Проблемы и решения

**Ядро не запускается:**
- Проверьте права на выполнение (Linux/Android)
- Убедитесь, что порты не заняты
- Проверьте логи в UI

**Обновление не работает:**
- Проверьте интернет соединение
- Убедитесь в корректности манифеста
- Проверьте SHA256 хеши

**Android VPN Service не работает:**
- Проверьте разрешения в AndroidManifest.xml
- Убедитесь, что foregroundServiceType установлен
- Проверьте логи через adb

---

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта!

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Стиль кода

- Следуйте [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Используйте `flutter format` перед commit
- Добавляйте комментарии для сложной логики
- Пишите тесты для новых функций

---

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE.txt](LICENSE.txt)

---

## 🙏 Благодарности

- [XRay-core](https://github.com/XTLS/Xray-core)
- [sing-box](https://github.com/SagerNet/sing-box)
- [Hysteria](https://github.com/apernet/hysteria)
- [v2rayN](https://github.com/2dust/v2rayN) - вдохновение для UI/UX
- Flutter Community

---

## 📞 Контакты

- **Issues**: [GitHub Issues](https://github.com/yourusername/neotun/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/neotun/discussions)
- **Email**: your.email@example.com

---

<div align="center">

**Сделано с ❤️ для свободного интернета**

⭐ Поставьте звезду, если проект вам понравился!

</div>
