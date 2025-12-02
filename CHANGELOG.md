# Changelog

## [1.2.2-beta.5] - 2024-12-02

### Added
- **Automatic Download**: XrayDownloader and LibxrayDownloader for automatic core installation
- **Auto-update**: Background check for Xray-core updates
- **Progress Tracking**: Real-time download progress in UI
- **Version Management**: Check installed versions and available updates

### Fixed
- Removed old VpnService.kt and TunVpnService.kt causing compilation errors
- Fixed Android build issues with unresolved XrayHelper references
- Fixed cores_screen.dart warnings

### Changed
- CoreManager now auto-downloads xray-core on first run
- CoresScreen updated with new download management UI
- Simplified core management - automatic installation

## [1.2.2-beta.4] - 2024-12-02

### Major Refactoring
- **Android Architecture**: Полностью переработано под v2rayNG
  - V2rayVpnService с libxray.so через JNI
  - Kotlin Coroutines для асинхронных операций
  - Правильная работа с VPN интерфейсом и TUN
  - XrayHelper как в AndroidLibXrayLite
  
- **Windows Architecture**: Полностью переработано под v2rayN
  - XrayWindowsService для управления xray.exe
  - WindowsProxy для системного прокси через WinAPI
  - Мониторинг статистики через gRPC API
  - Правильный запуск процесса без shell

### Changed
- CoreManager теперь использует платформо-специфичные сервисы
- Android использует V2rayVpnService вместо TunVpnService
- Windows использует XrayWindowsService + WindowsProxy
- Удалены старые VpnService.kt и TunVpnService.kt

### Added
- download_libxray.ps1 - скрипт для скачивания libxray.aar
- download_libxray.sh - bash версия скрипта
- docs/ANDROID_SETUP.md - подробная документация для Android
- docs/WINDOWS_SETUP.md - подробная документация для Windows
- android/app/libs/README.md - инструкции по установке libxray.aar

### Technical Details
- Основано на v2rayNG: https://github.com/2dust/v2rayNG
- Основано на v2rayN: https://github.com/2dust/v2rayN
- Использует AndroidLibXrayLite для Android
- Использует WinAPI для Windows прокси

## [1.2.2-beta.3] - 2024-12-02

### Changed
- Version bump for new release build

## [1.2.2-beta.2] - 2024-12-02

### Added
- **Comprehensive Logging**: Detailed logs for debugging startup issues
- **Global Error Handlers**: Catch all Flutter and async errors
- **TUN Mode Support**: Full TUN mode integration for Android and Windows

### Fixed
- Startup crash issues with detailed error tracking
- TUN mode not being used on Android
- Missing error handling in initialization

### Improved
- CoreManager initialization with fallback directories
- ConfigStorage initialization with better error messages
- All services now log their initialization status

## [1.2.2-beta.1] - 2024-12-02

### Major Changes
- **BREAKING**: Removed sing-box and Hysteria2 cores
- **Complete Xray rewrite**: New minimal, focused implementation
- Simplified codebase - only Xray-core support

### Added
- **XrayService**: New minimal service for Xray management
- **Automatic config validation**: Ensures configs have required fields
- **Better error handling**: Comprehensive logging and error tracking
- **TUN mode**: Full support for Android VPN and Windows Wintun

### Changed
- Simplified CoreType enum to only Xray
- Updated subscription parser to generate only Xray configs
- Removed all sing-box and hysteria2 references
- Updated localization files

### Fixed
- Config validation issues
- Missing DNS and routing in configs
- Android VPN startup problems

## [1.2.0] - 2024-11-30

### Stable Release
- First stable release with Xray, sing-box, and Hysteria2 support
- Multi-core architecture
- Subscription management
- QR code scanner
- Traffic statistics
- Auto-reconnect
- Localization (EN, RU)
