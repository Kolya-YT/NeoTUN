# Release Notes - v1.2.1-beta.3

## 🚨 CRITICAL FIX

### Fixed "Connected but No Internet" Issue

**Problem:** VPN showed as connected but internet didn't work.

**Root Cause:** Missing DNS configuration and improper routing rules in generated configurations.

**Solution:**
- ✅ Added proper DNS servers (8.8.8.8, 8.8.4.4, 1.1.1.1)
- ✅ Fixed routing rules for all protocols (VLESS, VMess, Trojan, Shadowsocks, Hysteria2)
- ✅ Added traffic sniffing for better protocol detection
- ✅ Changed domainStrategy to 'AsIs' for better compatibility
- ✅ Added geosite:cn routing for Chinese domains

## 📋 New Features (from beta.2)

### Clipboard Import
- Import VPN configs directly from clipboard
- Supports JSON configs, share URLs, and subscription URLs
- Auto-detection of protocol type

### Connection Testing
- Test individual configurations
- Batch test all configurations
- Shows ping, latency, and connection status

### Localization
- Full English and Russian translations
- 170+ localized strings

### Auto-Reconnection
- Automatic reconnection on connection loss
- Configurable in settings

## 🔧 Technical Changes

### Configuration Templates
All protocol parsers now include:
```json
{
  "dns": {
    "servers": ["8.8.8.8", "8.8.4.4", "1.1.1.1", "localhost"]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {"type": "field", "ip": ["geoip:private"], "outboundTag": "direct"},
      {"type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"}
    ]
  }
}
```

### Inbound Configuration
Added sniffing to all inbounds:
```json
{
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
```

## 📦 Installation

**Windows:**
```bash
# Download and extract
https://github.com/Kolya-YT/NeoTUN/releases/download/v1.2.1-beta.3/NeoTUN-Windows-x64.zip

# Run
neotun.exe
```

**Android:**
```bash
# Download APK
https://github.com/Kolya-YT/NeoTUN/releases/download/v1.2.1-beta.3/app-arm64-v8a-release.apk

# Install and grant VPN permission
```

## 🧪 Testing

### Before Using:
1. Test your configuration first (⚡ icon)
2. Check connection status in logs
3. Verify internet access

### If Issues Persist:
1. Check core is installed (Settings → Cores)
2. Try different connection mode (Proxy/TUN)
3. Verify configuration JSON is valid
4. Check logs for errors

## 📝 Changelog

### v1.2.1-beta.3 (2024-12-02)
- **CRITICAL FIX**: Resolved "Connected but no internet" issue
- Added proper DNS configuration to all protocols
- Fixed routing rules for better traffic handling
- Improved logging and error messages

### v1.2.1-beta.2 (2024-12-02)
- Added clipboard import functionality
- Added connection testing for all configs
- Added speed test improvements
- Fixed localization issues

### v1.2.1-beta.1 (2024-12-01)
- Initial beta release with localization
- Auto-reconnection feature
- Traffic statistics
- Speed indicator widget

## 🐛 Known Issues

1. **Windows TUN Mode**: Requires Wintun driver (not included)
2. **First Connection**: May take 2-3 seconds to establish
3. **Some Configs**: May need manual DNS adjustment for specific networks

## 💡 Tips

1. **Always test configs** before connecting
2. **Use TUN mode** on Android for system-wide VPN
3. **Check logs** if connection fails
4. **Update cores** regularly for best performance

## 🔗 Links

- **GitHub**: https://github.com/Kolya-YT/NeoTUN
- **Issues**: https://github.com/Kolya-YT/NeoTUN/issues
- **Releases**: https://github.com/Kolya-YT/NeoTUN/releases

## 📧 Support

If you encounter issues:
1. Check logs in the app
2. Test configuration
3. Report issue on GitHub with logs

---

**Version**: 1.2.1-beta.3+16  
**Release Date**: December 2, 2024  
**Branch**: beta → main
