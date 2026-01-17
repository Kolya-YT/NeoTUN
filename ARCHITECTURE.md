# NeoTUN Architecture Overview

## Core Design Principles

1. **Separation of Concerns**: Clear boundaries between networking, UI, and configuration layers
2. **Platform Abstraction**: Shared core logic with platform-specific implementations
3. **Dependency Injection**: Loose coupling and testability
4. **Security First**: Secure process management and data handling
5. **Maintainability**: Clean code with comprehensive logging and error handling

## Layer Architecture

```
┌─────────────────────────────────────────┐
│                UI Layer                 │
│  (Android: Jetpack Compose)            │
│  (Windows: WPF)                        │
├─────────────────────────────────────────┤
│            Application Layer            │
│  - ViewModels/Presenters               │
│  - Navigation                          │
│  - State Management                    │
├─────────────────────────────────────────┤
│             Domain Layer                │
│  - Use Cases                           │
│  - Domain Models                       │
│  - Repository Interfaces               │
├─────────────────────────────────────────┤
│         Infrastructure Layer            │
│  - Xray Process Management             │
│  - Configuration Parsing               │
│  - Local Storage                       │
│  - Platform-specific Tunneling         │
└─────────────────────────────────────────┘
```

## Core Components

### 1. Configuration Management
- **ConfigParser**: Parse URI schemes (vmess://, vless://, etc.)
- **XrayConfigGenerator**: Generate valid Xray JSON configurations
- **ProfileRepository**: Store and manage VPN profiles

### 2. Tunnel Management
- **TunnelService**: Abstract tunnel interface
- **AndroidTunnelService**: VpnService implementation
- **WindowsTunnelService**: Wintun implementation

### 3. Process Management
- **XrayProcessManager**: Manage Xray subprocess lifecycle
- **LogCollector**: Capture and parse Xray logs
- **HealthMonitor**: Monitor connection health

### 4. Data Models
- **VpnProfile**: Core profile data structure
- **ConnectionState**: Current connection status
- **LogEntry**: Structured log entries

## Platform-Specific Implementations

### Android
- **VpnService**: System VPN service integration
- **Room Database**: Local profile storage
- **Jetpack Compose**: Modern reactive UI
- **WorkManager**: Background tasks and auto-reconnect

### Windows
- **Wintun**: TUN interface management
- **WPF**: Desktop UI framework
- **Windows Service**: Optional system service mode
- **Registry**: Settings storage

## Security Considerations

1. **Process Isolation**: Xray runs in separate process
2. **Privilege Management**: Minimal required permissions
3. **Data Protection**: Encrypted profile storage
4. **Network Security**: Proper certificate validation
5. **Log Sanitization**: Remove sensitive data from logs

## Error Handling Strategy

1. **Graceful Degradation**: Fallback mechanisms
2. **User-Friendly Messages**: Clear error communication
3. **Comprehensive Logging**: Debug information without sensitive data
4. **Recovery Mechanisms**: Auto-reconnect and retry logic