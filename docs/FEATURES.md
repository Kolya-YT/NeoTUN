# NeoTUN Features Guide

## Version 1.2.1-beta.2

### 📋 Clipboard Import

Import VPN configurations directly from your clipboard without manual typing.

**Supported Formats:**
- **JSON Configs**: Full Xray, sing-box, or Hysteria2 configurations
- **Share URLs**: 
  - `vless://...`
  - `vmess://...`
  - `trojan://...`
  - `ss://...` (Shadowsocks)
  - `hysteria2://...` or `hy2://...`
- **Subscription URLs**: HTTP/HTTPS links to subscription services

**How to Use:**
1. Copy any supported configuration to clipboard
2. Open NeoTUN
3. Tap the `+` button → "Import from Clipboard"
4. Configuration is automatically detected and imported

**Examples:**

```
vless://uuid@server.com:443?security=tls&sni=server.com#MyConfig

vmess://base64encodedconfig

https://subscription.example.com/configs
```

### ⚡ Connection Testing

Test individual or all configurations to find the fastest and most reliable servers.

**Single Config Test:**
- Tap the ⚡ icon next to any configuration
- Shows: Connection status, Ping time, HTTP latency
- Results displayed in a dialog

**Test All Configs:**
- Tap `+` → "Test All Configs"
- Automatically tests each configuration
- Shows results with ping times
- Identifies working vs failed configs

**Test Metrics:**
- **Ping**: Average response time to multiple servers (8.8.8.8, google.com, cloudflare.com)
- **HTTP Latency**: Time to fetch a web page
- **Connection Status**: Success/Failure indicator

**Quality Indicators:**
- 🟢 Green: < 100ms (Excellent/Good)
- 🟠 Orange: 100-300ms (Fair)
- 🔴 Red: > 300ms (Poor)

### 🔄 Auto-Reconnection

Automatically reconnects if the VPN connection is lost.

**Settings:**
- Enable/Disable in Settings → Network
- Monitors connection status every 30 seconds
- Attempts reconnection on failure
- Configurable retry attempts

### 📊 Speed Indicator

Real-time traffic monitoring displayed on the home screen.

**Shows:**
- Upload speed (↑)
- Download speed (↓)
- Current session traffic
- Live updates every second

### 🌐 Localization

Full interface translation support.

**Available Languages:**
- 🇬🇧 English
- 🇷🇺 Russian

**Change Language:**
Settings → Appearance → Language

### 🎨 Themes

Three theme options for comfortable viewing.

**Available Themes:**
- ☀️ Light Theme
- 🌙 Dark Theme
- 🔄 System Theme (follows device settings)

**Change Theme:**
Settings → Appearance → Theme

### 📱 Connection Modes

**Proxy Mode:**
- Routes traffic through SOCKS5/HTTP proxy
- Port 10808 (SOCKS5), 10809 (HTTP)
- Works on all platforms
- Best for specific app proxying

**TUN Mode (Android only):**
- System-wide VPN
- Routes all device traffic
- Requires VPN permission
- Best for complete device protection

**Switch Mode:**
Toggle the switch on the home screen before connecting

### 🔧 Configuration Management

**Add Configuration:**
- Manual entry with JSON editor
- Import from clipboard
- QR code scanner
- Subscription import

**Edit Configuration:**
- Tap configuration → Edit
- JSON syntax validation
- Real-time error checking

**Delete Configuration:**
- Tap trash icon
- Confirmation dialog prevents accidents

**Duplicate Configuration:**
- Long press configuration
- Creates copy for testing variations

### 📈 Statistics

Track your VPN usage over time.

**Available Stats:**
- Current session traffic
- Total upload/download
- Session duration
- Average speed
- Peak speed

**Time Periods:**
- Today
- This Week
- This Month
- All Time

**Reset Statistics:**
Settings → Advanced → Reset Statistics

### 🔐 Protocol Support

**Xray-core:**
- VLESS (with XTLS)
- VMess
- Trojan
- Shadowsocks

**sing-box:**
- All Xray protocols
- Additional optimizations
- Better performance on some networks

**Hysteria2:**
- UDP-based protocol
- Optimized for lossy networks
- High-speed transfers

### 🚀 Performance Tips

1. **Test Before Use**: Always test configurations before connecting
2. **Use TUN Mode**: For system-wide protection on Android
3. **Monitor Speed**: Check the speed indicator for performance
4. **Auto-Reconnect**: Enable for stable connections
5. **Update Cores**: Keep cores updated for best performance

### 🐛 Troubleshooting

**Connection Fails:**
1. Test the configuration first
2. Check if core is installed (Settings → Cores)
3. Try different connection mode (Proxy/TUN)
4. Verify configuration JSON is valid

**Slow Speed:**
1. Test all configs to find fastest
2. Check network conditions
3. Try different protocol/core
4. Disable unnecessary apps

**Import Fails:**
1. Verify clipboard content format
2. Check if URL is accessible
3. Try manual JSON entry
4. Check error message for details

**Auto-Reconnect Not Working:**
1. Enable in Settings → Network
2. Grant necessary permissions
3. Check if config is valid
4. Review connection logs

### 📝 Configuration Examples

**VLESS with TLS:**
```json
{
  "inbounds": [...],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "server.com",
        "port": 443,
        "users": [{
          "id": "uuid-here",
          "encryption": "none"
        }]
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "tls",
      "tlsSettings": {
        "serverName": "server.com"
      }
    }
  }]
}
```

**Hysteria2:**
```json
{
  "server": "server.com:443",
  "auth": "password",
  "tls": {
    "sni": "server.com"
  },
  "socks5": {
    "listen": "127.0.0.1:10808"
  }
}
```

### 🔄 Update Process

**Check for Updates:**
Settings → About → Check for Updates

**Auto-Update:**
Enable in Settings → General → Auto Update

**Manual Update:**
Download from GitHub releases

### 💡 Best Practices

1. **Backup Configs**: Export important configurations
2. **Test Regularly**: Servers may change, test periodically
3. **Use Subscriptions**: Auto-update server lists
4. **Monitor Traffic**: Keep eye on data usage
5. **Update Regularly**: Keep app and cores updated
6. **Secure Storage**: Don't share configurations publicly

