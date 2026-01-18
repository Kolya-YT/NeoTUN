# NeoTUN - Modern Cross-Platform VPN/Proxy Client

A modern VPN/proxy client built with Xray-core, supporting Android and Windows platforms with **real VPN functionality** including traffic encryption and routing.

## Features

- **Real VPN Protection**: Actual traffic encryption and IP masking (not simulation)
- **Multi-Protocol Support**: VMess, VLESS (with Reality), Trojan, Shadowsocks
- **Cross-Platform**: Android (Kotlin + Jetpack Compose) and Windows (C# + WPF)
- **URI Import**: Support for vmess://, vless://, trojan://, ss:// schemes
- **System Integration**: VPN indicators, notifications, network adapters
- **Modern UI**: Dark theme, clean architecture, Material Design
- **Secure**: Managed Xray subprocess with proper lifecycle management

## Architecture

```
NeoTUN/
├── shared/                 # Shared core logic
├── android/               # Android application (Kotlin/Compose)
├── windows/               # Windows application (C#/WPF)
│   ├── NeoTUN.Core/       # Core business logic
│   ├── NeoTUN.Windows/    # WPF UI application
│   └── NeoTUN.Package/    # MSIX packaging project
├── xray-core/             # Xray-core submodule
├── docs/                  # Documentation
└── .github/workflows/     # CI/CD pipelines
```

## CI/CD & Build Artifacts

### GitHub Actions Workflows

This project uses GitHub Actions for automated building and releasing:

#### Android CI (`.github/workflows/android-ci.yml`)
- **Triggers**: Push to main/develop, Pull Requests
- **Process**:
  1. Build Xray-core for all Android architectures (arm64-v8a, armeabi-v7a, x86, x86_64)
  2. Embed Xray binaries into Android jniLibs
  3. Build and sign APK with release keystore
  4. Upload artifacts to GitHub Actions
- **Output**: `neotun-debug-apk` or `neotun-release-apk`
- **Features**: Gradle caching, NDK cross-compilation, APK signing

#### Windows CI (`.github/workflows/windows-ci.yml`)
- **Triggers**: Push to main/develop, Pull Requests  
- **Process**:
  1. Build Xray-core for Windows x64
  2. Download Wintun driver from official source
  3. Build .NET 8 WPF application
  4. Create self-contained executable
  5. Build MSIX package using Windows Application Packaging Project
  6. Sign MSIX with code signing certificate
- **Output**: `neotun-windows-exe`, `neotun-windows-msix`
- **Features**: MSBuild integration, MSIX packaging, code signing

#### Release Pipeline (`.github/workflows/release.yml`)
- **Triggers**: Git tags matching `v*` (e.g., `v1.0.0`)
- **Process**:
  1. Create GitHub Release
  2. Build all platforms simultaneously
  3. Upload all artifacts to GitHub Release
  4. Generate release notes and checksums
- **Output**: Complete GitHub Release with all platform artifacts
- **Features**: Multi-platform builds, automated releases, asset management

### Required GitHub Secrets

To enable the full CI/CD pipeline, configure these secrets in your GitHub repository:

#### Android Signing (Required for Release APK)
```bash
ANDROID_KEYSTORE_BASE64     # Base64-encoded Android keystore file
ANDROID_STORE_PASSWORD      # Keystore password  
ANDROID_KEY_ALIAS          # Key alias name
ANDROID_KEY_PASSWORD       # Key password
```

**Generate Android keystore:**
```bash
keytool -genkey -v -keystore release.keystore -alias neotun -keyalg RSA -keysize 2048 -validity 10000
base64 -i release.keystore | pbcopy  # Copy to ANDROID_KEYSTORE_BASE64
```

#### Windows Code Signing (Optional for MSIX)
```bash
WINDOWS_CERTIFICATE_BASE64  # Base64-encoded PFX certificate
WINDOWS_CERTIFICATE_PASSWORD # Certificate password
```

**Generate self-signed certificate (for testing):**
```powershell
New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=NeoTUN Team" -KeyUsage DigitalSignature -FriendlyName "NeoTUN Code Signing" -CertStoreLocation "Cert:\CurrentUser\My"
```

### Build Dependencies

#### Xray-core Submodule
The project includes Xray-core as a Git submodule for reproducible builds:
```bash
git clone --recursive https://github.com/Kolya-YT/NeoTUN.git
# Or if already cloned:
git submodule update --init --recursive
```

#### External Dependencies (Auto-downloaded in CI)
- **Android**: Android NDK r25c, JDK 17, Android SDK
- **Windows**: .NET 8 SDK, Windows SDK, Wintun driver v0.14.1
- **Cross-platform**: Go 1.21 for Xray-core compilation

### Local Development Setup

#### Prerequisites
- **Android**: Android Studio, JDK 17
- **Windows**: Visual Studio 2022, .NET 8 SDK
- **Both**: Git with submodule support

#### Android Development
```bash
cd android
./gradlew assembleDebug          # Build debug APK
./gradlew assembleRelease        # Build release APK (requires keystore)
./gradlew installDebug           # Install on connected device
```

#### Windows Development  
```bash
cd windows
dotnet restore                   # Restore NuGet packages
dotnet build --configuration Release  # Build solution
dotnet run --project NeoTUN.Windows   # Run application

# Build MSIX package
msbuild NeoTUN.Package/NeoTUN.Package.wapproj /p:Configuration=Release /p:Platform=x64
```

### Artifact Descriptions

| Artifact | Description | Platform | Size (Est.) | Features |
|----------|-------------|----------|-------------|----------|
| `neotun-debug-apk` | Debug Android APK | Android 5.0+ | ~15MB | Debugging enabled, unsigned |
| `neotun-release-apk` | Signed Android APK | Android 5.0+ | ~12MB | Optimized, signed, ready for distribution |
| `neotun-windows-exe` | Self-contained executable | Windows 10+ | ~80MB | No .NET runtime required |
| `neotun-windows-msix` | Windows Store package | Windows 10+ | ~80MB | Store-ready, signed, auto-updates |

### Security & Compliance

#### Code Signing
- **Android**: APK signed with release keystore using SHA-256
- **Windows**: MSIX signed with Authenticode certificate
- **Verification**: All signatures validated in CI pipeline

#### Reproducible Builds
- **Deterministic**: Same source code produces identical binaries
- **Version Pinning**: All dependencies locked to specific versions
- **Build Environment**: Containerized builds with fixed tool versions
- **Verification**: Build artifacts include SHA-256 checksums

#### Security Scanning
- **Dependencies**: Automated vulnerability scanning with GitHub Security
- **Code Analysis**: Static analysis with CodeQL
- **Supply Chain**: Dependency graph monitoring and alerts
- **Secrets**: No hardcoded secrets, all sensitive data in GitHub Secrets

### Release Process

#### Creating a Release
1. **Tag the release**: `git tag v1.0.0 && git push origin v1.0.0`
2. **CI builds all platforms** automatically
3. **GitHub Release created** with all artifacts
4. **Artifacts signed and uploaded** to release page

#### Version Numbering
- **Format**: Semantic versioning (v1.0.0)
- **Android**: `versionCode` auto-incremented, `versionName` from tag
- **Windows**: Assembly version from tag, MSIX version auto-incremented

#### Distribution Channels
- **GitHub Releases**: Primary distribution for all platforms
- **Android**: Ready for Google Play Store submission
- **Windows**: Ready for Microsoft Store submission via MSIX

## Getting Started

### Quick Start
1. **Download** latest release from [GitHub Releases](https://github.com/Kolya-YT/NeoTUN/releases)
2. **Install** APK on Android or EXE/MSIX on Windows
3. **Import** VPN profile using vmess://, vless://, trojan://, or ss:// URI
4. **Connect** and verify your IP changed at [whatismyipaddress.com](https://whatismyipaddress.com)

### Platform-Specific Guides
- [Android Setup & Usage](android/README.md)
- [Windows Setup & Usage](windows/README.md)
- [VPN Configuration Guide](docs/VPN_CONFIGURATION.md)

## Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test locally
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open Pull Request

### CI/CD Testing
- **Pull Requests**: Trigger debug builds for testing
- **Main Branch**: Trigger release builds for staging
- **Tags**: Trigger full release pipeline

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Xray-core](https://github.com/XTLS/Xray-core) - High-performance proxy core
- [Wintun](https://www.wintun.net/) - Windows TUN driver
- [Android Jetpack Compose](https://developer.android.com/jetpack/compose) - Modern Android UI
- [.NET WPF](https://docs.microsoft.com/en-us/dotnet/desktop/wpf/) - Windows desktop framework
