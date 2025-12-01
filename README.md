# NeoTUN

<div align="center">

![Version](https://img.shields.io/badge/version-v1.2.0--beta.1-blue)
![Beta](https://img.shields.io/badge/beta-testing-orange)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE.txt)

**Кроссплатформенный прокси клиент для Windows и Android**

[Скачать](https://github.com/Kolya-YT/NeoTUN/releases) • [Сообщить об ошибке](https://github.com/Kolya-YT/NeoTUN/issues)

</div>

## Возможности

- **Поддержка ядер:** XRay-core, sing-box, Hysteria2
- **Платформы:** Windows (x64), Android (arm64, arm32, x64)
- **Режимы:** Proxy Mode, TUN Mode (Android)
- **Функции:** Управление конфигурациями, QR сканер, подписки, автообновление ядер
- **Интерфейс:** Material Design 3, темная/светлая тема

## Установка

**Windows:** Скачайте `NeoTUN-Windows-x64.zip` из [релизов](https://github.com/Kolya-YT/NeoTUN/releases), распакуйте и запустите `neotun.exe`

**Android:** Скачайте APK из [релизов](https://github.com/Kolya-YT/NeoTUN/releases) и установите

## Быстрый старт

1. Добавьте конфигурацию (кнопка `+`, QR сканер или импорт)
2. Выберите конфигурацию и нажмите кнопку подключения
3. Проверьте подключение в браузере

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
