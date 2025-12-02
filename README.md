# NeoTUN

<div align="center">

![Version](https://img.shields.io/badge/version-v1.2.1--beta.2-blue)
![Beta](https://img.shields.io/badge/beta-testing-orange)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE.txt)

**Кроссплатформенный прокси клиент для Windows и Android**

🌐 **Локализация:** Английский, Русский

[Скачать](https://github.com/Kolya-YT/NeoTUN/releases) • [Сообщить об ошибке](https://github.com/Kolya-YT/NeoTUN/issues)

</div>

## Возможности

### Ядра и протоколы
- **Поддержка ядер:** XRay-core, sing-box, Hysteria2
- **Протоколы:** VLESS, VMess, Trojan, Shadowsocks, Hysteria2
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

```bash
git clone https://github.com/Kolya-YT/NeoTUN.git
cd NeoTUN
flutter pub get

# Windows
flutter build windows --release

# Android
flutter build apk --release --split-per-abi
```

## Архитектура

**Android (Xray):** Flutter → MethodChannel → VpnService.kt → XrayHelper.kt → libxray.so (AndroidLibXrayLite)

**Windows:** Flutter → ProcessController → xray.exe / sing-box.exe / hysteria2.exe

## Лицензия

MIT License - см. [LICENSE.txt](LICENSE.txt)

## Благодарности

- [XRay-core](https://github.com/XTLS/Xray-core)
- [sing-box](https://github.com/SagerNet/sing-box)
- [Hysteria](https://github.com/apernet/hysteria)
- [Flutter](https://flutter.dev)
