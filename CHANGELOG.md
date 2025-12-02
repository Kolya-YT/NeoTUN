# Changelog

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
- Better reliability and performance

### Added
- New `XrayService` - minimal, clean Xray implementation
- Automatic configuration validation and enhancement
- Better error messages and logging
- Proper DNS and routing in all configurations

### Removed
- sing-box core support
- Hysteria2 core support
- Complex multi-core management code

### Fixed
- Xray not working on PC and Android
- Configuration issues causing connection failures
- Over-complicated core management

### Why This Change?
- Xray is the most widely used and reliable core
- Simpler codebase = fewer bugs
- Easier to maintain and debug
- Better focus on making one thing work perfectly

## [1.2.1-beta.3] - 2024-12-02

### Fixed
- **CRITICAL**: Resolved "Connected but no internet" issue
- Added proper DNS configuration (8.8.8.8, 8.8.4.4, 1.1.1.1)
- Fixed routing rules for all protocols
- Added sniffing for better traffic detection

### Improved
- Better logging (reduced to 'warning' level)
- Enhanced configuration templates for all protocols

## [1.2.1-beta.2] - 2024-12-02

### Added
- Clipboard import functionality
- Connection testing for all configs
- Speed test improvements
- 20+ new translation keys

### Fixed
- Duplicate "connectionSpeed" key in localization
- JSON config parsing for clipboard import

## [1.2.1-beta.1] - 2024-12-01

### Added
- Comprehensive localization support (English/Russian)
- Auto-reconnection functionality
- Connection testing service
- Speed indicator widget
- Pull-to-refresh functionality

### Fixed
- VPN connection issues on Android (TUN mode)
- DNS server type definitions
- Protocol support for VLESS, VMess, Trojan, Shadowsocks

