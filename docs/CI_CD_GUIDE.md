# NeoTUN CI/CD Guide

## Overview

NeoTUN uses GitHub Actions for continuous integration and deployment, providing automated builds for Android APK, Windows EXE, and Windows MSIX packages.

## Workflow Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Android CI    │    │   Windows CI    │    │  Release CI     │
│                 │    │                 │    │                 │
│ • Build Xray    │    │ • Build Xray    │    │ • Build All     │
│ • Build APK     │    │ • Build WPF     │    │ • Create Release│
│ • Sign APK      │    │ • Create MSIX   │    │ • Upload Assets │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                    ┌─────────────────┐
                    │  Xray Submodule │
                    │                 │
                    │ • Cross-compile │
                    │ • Multi-arch    │
                    │ • Reproducible  │
                    └─────────────────┘
```

## Workflow Details

### 1. Android CI (`.github/workflows/android.yml`)

#### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

#### Build Matrix
Builds Xray-core for all Android architectures:
- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM)
- `x86` (32-bit Intel)
- `x86_64` (64-bit Intel)

#### Build Process
1. **Setup Environment**
   - Ubuntu latest runner
   - Go 1.21
   - Android NDK r25c
   - JDK 17

2. **Build Xray Binaries**
   - Cross-compile for each architecture
   - Use appropriate Android NDK toolchain
   - Generate optimized binaries with stripped symbols

3. **Prepare Android Project**
   - Download Xray binaries
   - Place in `jniLibs` directories
   - Set executable permissions

4. **Build APK**
   - Debug APK for PRs
   - Signed release APK for main branch pushes
   - Use keystore from GitHub Secrets

#### Artifacts
- `neotun-debug.apk` (Pull Requests)
- `neotun-release.apk` (Main branch)

### 2. Windows CI (`.github/workflows/windows.yml`)

#### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

#### Build Process
1. **Setup Environment**
   - Windows latest runner
   - Go 1.21
   - .NET 8 SDK
   - MSBuild tools

2. **Build Xray Binary**
   - Cross-compile for Windows x64
   - Generate optimized binary

3. **Download Dependencies**
   - Wintun driver from official source
   - Place in Windows project directory

4. **Build .NET Application**
   - Restore NuGet packages
   - Build in Release configuration
   - Publish self-contained executable

5. **Create MSIX Package**
   - Generate Package.appxmanifest
   - Create placeholder assets
   - Use Windows SDK makeappx.exe
   - Sign with certificate from secrets

#### Artifacts
- `neotun-windows.exe` (Self-contained executable)
- `neotun-windows.msix` (Windows Store package)

### 3. Release Pipeline (`.github/workflows/release.yml`)

#### Triggers
- Git tags matching pattern `v*` (e.g., `v1.0.0`, `v2.1.3`)

#### Build Process
1. **Parallel Builds**
   - Android: All architectures in single job
   - Windows: EXE and MSIX in single job

2. **Artifact Collection**
   - Download all build artifacts
   - Prepare for GitHub Release

3. **Release Creation**
   - Create GitHub Release
   - Upload all artifacts
   - Generate release notes

#### Release Assets
- `app-release.apk` - Android application
- `NeoTUN.Windows.exe` - Windows executable
- `NeoTUN.msix` - Windows Store package

## Security Configuration

### Required GitHub Secrets

#### Android Code Signing
```bash
# Generate Android keystore
keytool -genkey -v -keystore neotun.keystore -alias neotun -keyalg RSA -keysize 2048 -validity 10000

# Convert to base64 for GitHub Secret
base64 -i neotun.keystore | pbcopy  # macOS
base64 -w 0 neotun.keystore         # Linux
```

**Secrets to configure:**
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias (e.g., "neotun")
- `ANDROID_KEY_PASSWORD`: Key password

#### Windows Code Signing
```bash
# Create self-signed certificate (for testing)
New-SelfSignedCertificate -Subject "CN=NeoTUN" -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsage DigitalSignature -Type CodeSigning

# Export to PFX
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Where-Object {$_.Subject -eq "CN=NeoTUN"}
Export-PfxCertificate -Cert $cert -FilePath "neotun.pfx" -Password (ConvertTo-SecureString -String "password" -Force -AsPlainText)

# Convert to base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("neotun.pfx"))
```

**Secrets to configure:**
- `WINDOWS_CERTIFICATE_BASE64`: Base64-encoded PFX certificate
- `WINDOWS_CERTIFICATE_PASSWORD`: Certificate password

### Security Best Practices

1. **Reproducible Builds**
   - Pin all dependency versions
   - Use deterministic build flags
   - Verify build reproducibility

2. **Artifact Integrity**
   - Generate SHA256 checksums
   - Sign all release artifacts
   - Verify signatures in CI

3. **Dependency Security**
   - Regular dependency updates
   - Automated vulnerability scanning
   - License compliance checking

## Build Optimization

### Caching Strategy
- **Gradle**: Cache `.gradle` directory
- **Go modules**: Cache `GOMODCACHE`
- **NuGet**: Cache packages directory

### Build Performance
- **Parallel builds**: Use build matrix for multi-arch
- **Incremental builds**: Cache intermediate artifacts
- **Resource limits**: Optimize for GitHub Actions runners

## Troubleshooting

### Common Issues

#### Android Build Failures
```bash
# NDK not found
- name: Set up Android NDK
  uses: nttld/setup-ndk@v1
  with:
    ndk-version: r25c

# Gradle permission denied
chmod +x android/gradlew
```

#### Windows Build Failures
```powershell
# .NET SDK not found
- name: Setup .NET 8
  uses: actions/setup-dotnet@v3
  with:
    dotnet-version: '8.0.x'

# MSBuild not found
- name: Setup MSBuild
  uses: microsoft/setup-msbuild@v1.3
```

#### Xray Build Failures
```bash
# Go version mismatch
- name: Set up Go
  uses: actions/setup-go@v4
  with:
    go-version: '1.21'

# Cross-compilation issues
export CGO_ENABLED=1
export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang
```

### Debug Strategies

1. **Enable Debug Logging**
   ```yaml
   - name: Debug step
     run: |
       echo "Debug information"
       env
       ls -la
   ```

2. **Artifact Inspection**
   ```yaml
   - name: Upload debug artifacts
     uses: actions/upload-artifact@v3
     with:
       name: debug-info
       path: |
         build-logs/
         *.log
   ```

3. **Matrix Debugging**
   ```yaml
   strategy:
     fail-fast: false  # Continue other jobs if one fails
     matrix:
       arch: [arm64-v8a, armeabi-v7a]
   ```

## Local Testing

### Test Android Build
```bash
# Setup environment
export ANDROID_NDK_HOME=/path/to/ndk
export ANDROID_HOME=/path/to/sdk

# Build Xray
cd xray-core
GOOS=android GOARCH=arm64 CGO_ENABLED=1 \
CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang \
go build -o ../android/app/src/main/jniLibs/arm64-v8a/libxray.so ./main

# Build APK
cd android
./gradlew assembleDebug
```

### Test Windows Build
```powershell
# Build Xray
cd xray-core
$env:GOOS="windows"
$env:GOARCH="amd64"
$env:CGO_ENABLED="0"
go build -o ../windows/NeoTUN.Windows/xray.exe ./main

# Build Windows app
cd windows
dotnet restore
dotnet build --configuration Release
```

## Monitoring and Maintenance

### Workflow Monitoring
- Monitor build success rates
- Track build duration trends
- Alert on consecutive failures

### Dependency Updates
- Weekly dependency scans
- Automated security updates
- Version compatibility testing

### Performance Metrics
- Build time optimization
- Artifact size monitoring
- Resource usage tracking