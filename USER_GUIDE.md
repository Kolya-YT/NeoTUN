# NeoTUN VPN Client - User Guide

## 🚀 Quick Start

NeoTUN is a **real VPN client** that provides secure, encrypted internet access through various protocols. This is **NOT a simulation** - it creates actual VPN tunnels that encrypt and route all your device traffic.

## 📱 Android Usage

### Installation
1. Download and install the NeoTUN APK
2. Grant VPN permission when prompted (required for real VPN functionality)
3. The app will request to create VPN connections - tap "OK"

### Adding VPN Profiles
1. **Tap "Add Profile"** on the main screen
2. **Choose import method**:
   - **URI Import**: Paste vmess://, vless://, trojan://, or ss:// link
   - **Manual Entry**: Fill in server details manually
3. **Tap "Save"** to add the profile

### Connecting to VPN
1. **Select a profile** from the list
2. **Tap "Connect"** button
3. **Grant VPN permission** if prompted (first time only)
4. **Wait for connection** - status will show "Connected"
5. **VPN key icon** appears in status bar when connected
6. **All traffic** is now encrypted and routed through VPN

### Verifying Connection
- Visit [whatismyipaddress.com](https://whatismyipaddress.com) - should show VPN server IP
- Check status bar for VPN key icon
- View logs in app for connection details

## 💻 Windows Usage

### Installation
1. Download and extract NeoTUN Windows application
2. **Run as Administrator** (required for network adapter creation)
3. Windows may prompt about network changes - allow them

### Adding VPN Profiles  
1. **Click "Add Profile"** button
2. **Import Profile Dialog** opens:
   - **Paste VPN URI** in the text field
   - **Click "Import"** to parse the configuration
3. **Profile appears** in the main list

### Connecting to VPN
1. **Select profile** from the dropdown
2. **Click "Connect"** button  
3. **Wait for connection** - status shows "Connected to [Profile Name]"
4. **New network adapter** "NeoTUN" appears in Network Connections
5. **All applications** now route traffic through VPN

### Verifying Connection
- Check external IP address - should match VPN server
- Look for "NeoTUN" adapter in Network and Sharing Center
- Monitor connection logs in the application

## 🔧 Supported Protocols

### VMess (V2Ray)
- **Format**: `vmess://[base64-encoded-config]`
- **Features**: High security, traffic obfuscation
- **Best for**: Bypassing censorship

### VLess (Lightweight V2Ray)
- **Format**: `vless://[uuid]@[server]:[port]?[parameters]`
- **Features**: Lower overhead than VMess
- **Best for**: High-performance connections

### Trojan
- **Format**: `trojan://[password]@[server]:[port]?[parameters]`
- **Features**: TLS-based, looks like HTTPS traffic
- **Best for**: Stealth and reliability

### Shadowsocks
- **Format**: `ss://[method:password@server:port]`
- **Features**: Lightweight, fast
- **Best for**: Speed and simplicity

## 🛡️ Security Features

### Real VPN Protection
- ✅ **All traffic encrypted** using military-grade protocols
- ✅ **DNS leak protection** - DNS queries routed through VPN
- ✅ **IP address masking** - your real IP is hidden
- ✅ **Traffic obfuscation** - VPN traffic looks like normal HTTPS

### Privacy Features
- ✅ **No logging** - connection logs stay on your device
- ✅ **Local processing** - profiles stored locally only
- ✅ **Open source** - code is auditable

## 📊 Connection Status

### Status Indicators
- **🔴 Disconnected**: No VPN connection
- **🟡 Connecting**: Establishing VPN tunnel
- **🟢 Connected**: VPN active, traffic encrypted
- **🔴 Error**: Connection failed, check logs

### Android Status Bar
- **VPN Key Icon**: Appears when VPN is active
- **Notification**: Shows connected profile name
- **No Icon**: VPN is disconnected

### Windows Network Adapter
- **NeoTUN Adapter**: Visible in Network Connections when connected
- **IP Address**: Shows 10.0.0.2 when active
- **Status**: "Connected" in Network and Sharing Center

## 🔍 Troubleshooting

### Android Issues

**App Crashes on Import**
- ✅ **Fixed**: Improved error handling and validation
- Make sure URI format is correct
- Check internet connection

**VPN Won't Connect**
- Grant VPN permission in Android settings
- Check if profile configuration is valid
- Ensure server is reachable
- Try different server/profile

**No Internet After Connecting**
- Check server credentials are correct
- Verify server is online and accessible
- Try disconnecting and reconnecting
- Check logs for error messages

### Windows Issues

**"Access Denied" Error**
- **Run as Administrator** - required for network adapter
- Check Windows Defender/antivirus isn't blocking
- Ensure Wintun.dll is present

**Connection Fails**
- Verify profile configuration is correct
- Check Windows Firewall settings
- Ensure xray.exe is not blocked by antivirus
- Try different server/profile

**No Traffic Through VPN**
- Check if NeoTUN adapter is active
- Verify routing table (run `route print`)
- Restart application as Administrator
- Check server connectivity

## 📋 System Requirements

### Android
- **OS**: Android 5.0+ (API 21+)
- **RAM**: 2GB+ recommended
- **Storage**: 50MB free space
- **Permissions**: VPN permission required

### Windows  
- **OS**: Windows 10+ (64-bit recommended)
- **RAM**: 4GB+ recommended
- **Storage**: 100MB free space
- **Privileges**: Administrator access required

## ⚡ Performance Tips

### Android Optimization
- Close unnecessary apps to save battery
- Use Wi-Fi when possible (faster than mobile data)
- Choose servers geographically closer to you
- Monitor battery usage in Android settings

### Windows Optimization
- Close bandwidth-heavy applications when not needed
- Choose servers with low latency
- Monitor network usage in Task Manager
- Use wired connection for best performance

## 🌐 Server Selection

### Choosing the Best Server
1. **Geographic Location**: Closer servers = lower latency
2. **Server Load**: Less crowded servers = better speed
3. **Protocol**: VLess/Shadowsocks for speed, VMess/Trojan for security
4. **Network**: Choose servers on fast networks

### Testing Server Performance
- Use built-in connection logs to monitor speed
- Test different servers with same provider
- Check ping times to server locations
- Monitor connection stability over time

## 🔒 Privacy Best Practices

### Secure Usage
- Always verify your IP changed after connecting
- Use HTTPS websites when possible
- Don't save sensitive passwords in browsers while on VPN
- Regularly update VPN profiles/credentials

### Profile Management
- Don't share VPN profiles with others
- Use unique profiles for different purposes
- Regularly test profile connectivity
- Keep backup of working profiles

## 📞 Support

### Getting Help
- Check connection logs in the application
- Verify server credentials with your VPN provider
- Test with different profiles/servers
- Check system requirements are met

### Common Solutions
- **Restart the application** - fixes most temporary issues
- **Try different server** - current server may be down
- **Check internet connection** - ensure base connectivity works
- **Update profiles** - credentials may have changed

---

**Remember**: NeoTUN provides **REAL VPN protection** - all your internet traffic is encrypted and routed through the VPN server when connected. This is not a simulation or demo - it's a fully functional VPN client.