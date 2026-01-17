# NeoTUN - Modern Cross-Platform VPN/Proxy Client

A modern VPN/proxy client built with Xray-core, supporting Android and Windows platforms.

## Features

- **Multi-Protocol Support**: VMess, VLESS (with Reality), Trojan, Shadowsocks
- **Cross-Platform**: Android (Kotlin + Jetpack Compose) and Windows (C# + WPF)
- **URI Import**: Support for vmess://, vless://, trojan://, ss:// schemes
- **Modern UI**: Dark theme, clean architecture
- **Secure**: Managed Xray subprocess with proper lifecycle management

## Architecture

```
NeoTUN/
├── shared/                 # Shared core logic
├── android/               # Android application
├── windows/               # Windows application
├── docs/                  # Documentation
└── tools/                 # Build tools and scripts
```

## CI/CD & Build Artifacts

### GitHub Actions Workflows

This project uses GitHub Actions for automated building and releasing:

#### Android CI (`.github/workflows/android.yml`)
- **Triggers**: Push to main/develop, Pull Requests
- **Builds**: Xray-core for all Android architectures (arm64-v8a, armeabi-v7a, x86, x86_64)
- **Output**: Signed release APK or debug APK
- **Artifacts**: `neotun-release.apk` or `neotun-debug.apk`

#### Windows CI (`.github/workflows/windows.yml`)
- **Triggers**: Push to main/develop, Pull Requests
- **Builds**: Xray-core for Windows, .NET 8 WPF application, MSIX package
- **Output**: Self-contained EXE and signed MSIX package
- **Artifacts**: `neotun-windows.exe`, `neotun-windows.msix`

#### Release Pipeline (`.github/workflows/release.yml`)
- **Triggers**: Git tags matching `v*` (e.g., `v1.0.0`)
- **Builds**: All platforms simultaneously
- **Output**: GitHub Release with all artifacts
- **Artifacts**: APK, Windows EXE, Windows MSIX

### Required GitHub Secrets

To enable the full CI/CD pipeline, configure these secrets in your GitHub repository:

#### Android Signing
```
ANDROID_KEYSTORE_BASE64     # Base64-encoded Android keystore file
ANDROID_KEYSTORE_PASSWORD   # Keystore password
ANDROID_KEY_ALIAS          # Key alias name
ANDROID_KEY_PASSWORD       # Key password
```

#### Windows Code Signing
```
WINDOWS_CERTIFICATE_BASE64  # Base64-encoded PFX certificate
WINDOWS_CERTIFICATE_PASSWORD # Certificate password
```

### Build Dependencies

#### Xray-core Submodule
The project includes Xray-core as a Git submodule:
```bash
git submodule update --init --recursive
```

#### External Dependencies
- **Android**: Android NDK r25c (automatically downloaded in CI)
- **Windows**: Wintun driver (automatically downloaded from official source)

### Local Development Setup

#### Android
```bash
cd android
./gradlew assembleDebug
```

#### Windows
```bash
cd windows
dotnet restore
dotnet build --configuration Release
```

### Artifact Descriptions

| Artifact | Description | Platform | Size (Est.) |
|----------|-------------|----------|-------------|
| `neotun-release.apk` | Signed Android APK | Android 5.0+ | ~15MB |
| `neotun-windows.exe` | Self-contained executable | Windows 10+ | ~80MB |
| `neotun-windows.msix` | Windows Store package | Windows 10+ | ~80MB |

### Security Features

- **Code Signing**: All release artifacts are digitally signed
- **Reproducible Builds**: Deterministic build process with version pinning
- **Dependency Verification**: Automated security scanning of dependencies
- **Artifact Integrity**: SHA256 checksums for all release artifacts

## Getting Started

See platform-specific README files:
- [Android Setup](android/README.md)
- [Windows Setup](windows/README.md)

## License

MIT License - See LICENSE file for details
