# Build Instructions

## Windows

```bash
flutter pub get
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

## Android

### Prerequisites
1. Install AndroidLibXrayLite AAR:
   ```powershell
   .\download_xray_aar.ps1
   ```

2. Verify:
   ```powershell
   .\check_xray_aar.ps1
   ```

### Build

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/*.apk`

## Troubleshooting

### Windows
- **Visual Studio not found**: Install VS 2022 with C++ workload
- **CMake not found**: Install via VS Installer

### Android
- **AAR not found**: Run `.\download_xray_aar.ps1`
- **Gradle build failed**: Run `cd android && ./gradlew clean`

## Requirements

- Flutter 3.24.0+
- Dart 3.10.0+
- **Windows**: Visual Studio 2022
- **Android**: Android SDK (API 21+), Java JDK 17
