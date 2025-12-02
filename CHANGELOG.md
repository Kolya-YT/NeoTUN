# Changelog

## [1.2.1-beta.2] - 2024-12-02

### Added
- **Clipboard Import**: Import VPN configurations directly from clipboard
  - Support for JSON configs (Xray, sing-box, Hysteria2)
  - Support for share URLs (vless://, vmess://, trojan://, ss://, hysteria2://)
  - Support for subscription URLs
  - Automatic protocol detection and parsing
- **Connection Testing**: Test all configurations at once
  - Batch testing with progress indicator
  - Results display with ping times
  - Quick identification of working configs
- **Enhanced Speed Testing**: Individual config testing with detailed metrics
  - Ping test to multiple servers
  - HTTP latency measurement
  - Connection quality indicators

### Improved
- **Localization**: Fixed duplicate keys and added missing translations
  - Added 20+ new translation keys for new features
  - Complete English and Russian translations
  - Better error messages
- **UI/UX**: Enhanced configuration management
  - New menu for adding configs (manual, clipboard, test all)
  - Better visual feedback during testing
  - Improved error handling and user notifications

### Fixed
- Duplicate "connectionSpeed" key in localization files
- JSON config parsing for clipboard import
- Connection test result handling

### Technical
- Updated version to 1.2.1-beta.2+15
- Enhanced SubscriptionParser with parseShareUrl method
- Improved error handling in clipboard operations
- Better async operation management

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
- Protocol support for VLESS, VMess, Trojan, Shadowsocks, Hysteria2

## [1.2.0-beta.1] - 2024-11-30

### Added
- Initial beta release with core functionality
- Support for Xray, sing-box, and Hysteria2 cores
- Basic configuration management
- Traffic statistics
- Theme support (light/dark/system)

