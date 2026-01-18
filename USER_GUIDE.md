# NeoTUN User Guide

## 🚨 Important Notice
**This is a DEMO/SIMULATION version. No real VPN connections are established.**

## 🪟 Windows Application

### Current Status
- ✅ UI loads and displays correctly
- ✅ Profile import functionality works
- ✅ Connect/Disconnect buttons are functional
- ⚠️ **SIMULATION MODE** - No actual VPN tunnel created

### How to Use:
1. **Import Profile**: Click "Import Profile" button
2. **Paste URI**: Enter your vmess://, vless://, trojan://, or ss:// URI
3. **Select Profile**: Click on imported profile in the list
4. **Connect**: Click "Connect" button (simulation only)
5. **View Logs**: Check the logs panel for connection status

### Features Working:
- Profile import from URIs
- Profile selection
- Connection simulation
- Status display
- Logging system

## 📱 Android Application

### Current Status
- ✅ App launches without crashes
- ✅ Profile import works
- ✅ UI is responsive and modern
- ⚠️ **SIMULATION MODE** - No actual VPN service running

### How to Use:
1. **Add Profile**: Tap the "+" button or "Add Profile"
2. **Import URI**: Tap the link icon to show import section
3. **Paste URI**: Enter your VPN configuration URI
4. **Import**: Tap "Import" to parse the URI
5. **Save**: Tap "Save Profile" to add it
6. **Connect**: Tap the power button (simulation only)

### Features Working:
- Profile management (add, delete, select)
- URI import with validation
- Connection simulation
- Modern Material 3 UI
- Navigation between screens
- Logging system

## 🔧 Technical Limitations

### What's NOT Working:
- **No real VPN tunnel creation**
- **No actual network traffic routing**
- **No Xray process management**
- **No system-level VPN integration**

### What IS Working:
- Complete UI/UX experience
- Profile import and management
- Configuration parsing
- Status simulation
- Cross-platform compatibility

## 🚀 Next Steps for Full Implementation

### Android:
1. Implement VpnService integration
2. Add Xray binary execution
3. Create TUN interface management
4. Add traffic routing

### Windows:
1. Implement Wintun driver integration
2. Add Xray process management
3. Create system tray functionality
4. Add auto-start capabilities

## 📝 Testing the Demo

### Profile Import Testing:
Try these sample URIs (replace with real ones):
```
vmess://eyJ2IjoiMiIsInBzIjoidGVzdCIsImFkZCI6InRlc3QuY29tIiwicG9ydCI6IjQ0MyIsImlkIjoidGVzdC1pZCIsImFpZCI6IjAiLCJzY3kiOiJhdXRvIiwibmV0IjoidGNwIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwicGF0aCI6IiIsInRscyI6IiIsInNuaSI6IiJ9

vless://test-id@test.com:443?security=tls&sni=test.com#Test%20VLess

trojan://password@test.com:443?security=tls&sni=test.com#Test%20Trojan
```

### Expected Behavior:
- URIs should parse correctly
- Profile details should populate
- Connection should show "simulation" status
- Logs should indicate demo mode

## 🎯 Demo Objectives Achieved
- ✅ Cross-platform UI implementation
- ✅ Profile import functionality
- ✅ Modern, responsive design
- ✅ Error handling and validation
- ✅ Build system and CI/CD
- ✅ Code architecture demonstration