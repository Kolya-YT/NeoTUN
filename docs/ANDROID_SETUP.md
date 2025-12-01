# Android Setup Guide

## Overview

NeoTUN uses **AndroidLibXrayLite** native library for Xray on Android, which solves SELinux permission issues and works without root access.

## Quick Start

### 1. Download AAR (for developers)

```powershell
.\download_xray_aar.ps1
```

Or download manually from [AndroidLibXrayLite Releases](https://github.com/2dust/AndroidLibXrayLite/releases) and place in `android/app/libs/`

### 2. Build APK

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

### 3. Install

APK files will be in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` - for modern devices (recommended)
- `app-armeabi-v7a-release.apk` - for older devices
- `app-x86_64-release.apk` - for emulators

## Architecture

### Android - Xray (Native)
```
Flutter → MethodChannel → VpnService → XrayHelper → libxray.so
```
✅ Works without root  
✅ No SELinux issues  
✅ Same library as v2rayNG

### Android - sing-box/Hysteria2
```
Flutter → MethodChannel → VpnService → Process
```
⚠️ Requires TUN mode or root

### Windows - All cores
```
Flutter → ProcessController → Process.start() → .exe files
```
✅ Works as expected

## Troubleshooting

### "libxray.so not found"
1. Check AAR file exists: `android/app/libs/AndroidLibXrayLite.aar`
2. Clean and rebuild: `flutter clean && flutter build apk`

### TUN mode fails
1. Check logs: `adb logcat | grep TunVpnService`
2. Ensure VPN permission is granted
3. Try Proxy mode instead

## CI/CD

GitHub Actions automatically:
1. Downloads AndroidLibXrayLite AAR
2. Builds APK for all architectures
3. Creates GitHub Release

See `.github/workflows/build.yml` for details.

## Links

- [AndroidLibXrayLite](https://github.com/2dust/AndroidLibXrayLite)
- [v2rayNG](https://github.com/2dust/v2rayNG) - reference implementation
- [Xray-core](https://github.com/XTLS/Xray-core)
