# NeoTUN Implementation Guide

## Overview

This guide provides detailed implementation instructions for building NeoTUN, a cross-platform VPN/proxy client using Xray-core.

## Project Structure

```
NeoTUN/
├── shared/
│   └── core/
│       ├── models/           # Data models
│       ├── config/           # Configuration parsing & generation
│       ├── services/         # Core business logic
│       └── interfaces/       # Abstractions
├── android/
│   └── app/src/main/java/com/neotun/android/
│       ├── service/          # VpnService implementation
│       ├── ui/              # Jetpack Compose UI
│       └── data/            # Room database
├── windows/
│   └── NeoTUN.Windows/
│       ├── Services/        # Wintun integration
│       ├── ViewModels/      # MVVM pattern
│       └── Views/           # WPF UI
└── docs/                    # Documentation
```

## Key Implementation Details

### 1. URI Parsing

The `UriParser` class handles multiple URI schemes:

- **VMess**: Base64-encoded JSON format
- **VLess**: Standard URI with query parameters
- **Trojan**: Simple URI with password in userinfo
- **Shadowsocks**: Base64-encoded method:password

### 2. Xray Configuration Generation

The `XrayConfigGenerator` creates valid Xray JSON configs with:

- Inbound SOCKS/HTTP proxies
- Outbound configurations for each protocol
- Stream settings (TCP, WebSocket, TLS, Reality)
- Routing rules for local traffic

### 3. Platform-Specific Tunneling

#### Android VpnService
- Uses Android's VpnService API
- Requires BIND_VPN_SERVICE permission
- Implements packet capture and forwarding
- Integrates with Xray via SOCKS proxy

#### Windows Wintun
- Uses Wintun TUN driver
- Requires administrator privileges
- Implements TUN interface management
- Handles IP configuration via netsh

### 4. Process Management

The `XrayProcessManager` handles:
- Xray binary execution
- Configuration file management
- Process monitoring and logging
- Graceful shutdown

## Security Considerations

### 1. Process Isolation
- Xray runs in separate process
- Limited file system access
- Proper cleanup on exit

### 2. Configuration Security
- Temporary config files
- Secure credential storage
- Input validation

### 3. Network Security
- Certificate validation
- DNS leak prevention
- Traffic routing verification

## Development Setup

### Android Requirements
- Android Studio Arctic Fox+
- Android SDK 21+
- Kotlin 1.8+
- Jetpack Compose BOM 2023.10.01

### Windows Requirements
- Visual Studio 2022
- .NET 6.0+
- Wintun driver
- Administrator privileges for testing

## Build Instructions

### Android
```bash
cd android
./gradlew assembleDebug
```

### Windows
```bash
cd windows
dotnet build NeoTUN.Windows.sln
```

## Testing Strategy

### Unit Tests
- URI parsing validation
- Configuration generation
- Model serialization

### Integration Tests
- Xray process management
- Network connectivity
- Platform-specific tunneling

### Manual Testing
- Connection establishment
- Traffic routing
- Error handling
- UI responsiveness

## Deployment

### Android
- APK signing
- Play Store guidelines
- Permission handling

### Windows
- Code signing
- Installer creation
- Driver installation

## Performance Optimization

### Memory Management
- Efficient packet processing
- Resource cleanup
- Memory leak prevention

### Network Performance
- Buffer sizing
- Connection pooling
- Latency optimization

## Troubleshooting

### Common Issues
1. **Xray process fails to start**
   - Check binary permissions
   - Validate configuration
   - Review logs

2. **Connection timeouts**
   - Verify server settings
   - Check network connectivity
   - Test with different protocols

3. **Permission errors**
   - Android: VPN permission
   - Windows: Administrator rights
   - Driver installation

### Debug Logging
- Enable verbose Xray logging
- Capture network traffic
- Monitor system resources

## Future Enhancements

### Phase 1 (MVP)
- Basic protocol support
- Simple UI
- Core functionality

### Phase 2
- Advanced routing
- Traffic statistics
- Auto-reconnect

### Phase 3
- Plugin system
- Custom protocols
- Advanced UI features

## Best Practices

### Code Quality
- Follow platform conventions
- Implement proper error handling
- Use dependency injection
- Write comprehensive tests

### Security
- Regular security audits
- Dependency updates
- Secure coding practices
- User data protection

### Performance
- Profile critical paths
- Optimize hot code
- Monitor resource usage
- Implement caching where appropriate