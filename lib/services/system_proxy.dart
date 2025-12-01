import 'dart:io';

class SystemProxy {
  static final SystemProxy instance = SystemProxy._();
  SystemProxy._();

  bool _isProxyEnabled = false;
  String? _currentHost;
  int? _currentPort;

  /// Включить системный прокси
  Future<bool> enableProxy(String host, int port) async {
    try {
      if (Platform.isWindows) {
        // Включаем прокси через реестр
        final enableResult = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v',
          'ProxyEnable',
          '/t',
          'REG_DWORD',
          '/d',
          '1',
          '/f'
        ]);

        if (enableResult.exitCode != 0) {
          print('Failed to enable proxy flag: ${enableResult.stderr}');
          return false;
        }

        final serverResult = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v',
          'ProxyServer',
          '/t',
          'REG_SZ',
          '/d',
          '$host:$port',
          '/f'
        ]);

        if (serverResult.exitCode != 0) {
          print('Failed to set proxy server: ${serverResult.stderr}');
          return false;
        }

        // Добавляем bypass для локальных адресов
        await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v',
          'ProxyOverride',
          '/t',
          'REG_SZ',
          '/d',
          'localhost;127.*;10.*;172.16.*;172.31.*;192.168.*;<local>',
          '/f'
        ]);

        // Обновляем настройки через netsh
        await Process.run('netsh', ['winhttp', 'import', 'proxy', 'source=ie']);
        
        _isProxyEnabled = true;
        _currentHost = host;
        _currentPort = port;
        
        print('✓ System proxy enabled: $host:$port');
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to enable proxy: $e');
      return false;
    }
  }

  /// Отключить системный прокси
  Future<bool> disableProxy() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('reg', [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v',
          'ProxyEnable',
          '/t',
          'REG_DWORD',
          '/d',
          '0',
          '/f'
        ]);

        if (result.exitCode != 0) {
          print('Failed to disable proxy: ${result.stderr}');
          return false;
        }

        // Обновляем настройки через netsh
        await Process.run('netsh', ['winhttp', 'reset', 'proxy']);
        
        _isProxyEnabled = false;
        _currentHost = null;
        _currentPort = null;
        
        print('✓ System proxy disabled');
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to disable proxy: $e');
      return false;
    }
  }

  /// Проверить, включен ли прокси
  Future<bool> isProxyEnabled() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('reg', [
          'query',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
          '/v',
          'ProxyEnable'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          return output.contains('0x1');
        }
      }
    } catch (e) {
      print('Failed to check proxy status: $e');
    }
    return false;
  }

  /// Проверить подключение через прокси
  Future<bool> testConnection() async {
    if (!_isProxyEnabled || _currentHost == null || _currentPort == null) {
      return false;
    }

    try {
      // Пробуем подключиться к прокси
      final socket = await Socket.connect(_currentHost!, _currentPort!, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (e) {
      print('Proxy connection test failed: $e');
      return false;
    }
  }

  /// Получить текущий порт из конфигурации
  int? getInboundPort(Map<String, dynamic> config) {
    try {
      if (config['inbounds'] != null) {
        final inbounds = config['inbounds'] as List;
        if (inbounds.isNotEmpty) {
          final firstInbound = inbounds[0] as Map<String, dynamic>;
          return firstInbound['port'] as int?;
        }
      }
      
      // Для sing-box
      if (config['inbound'] != null) {
        final inbound = config['inbound'] as Map<String, dynamic>;
        return inbound['listen_port'] as int?;
      }
    } catch (e) {
      print('Failed to get inbound port: $e');
    }
    return 10808; // Default port
  }

  bool get isEnabled => _isProxyEnabled;
  String? get currentHost => _currentHost;
  int? get currentPort => _currentPort;
}
