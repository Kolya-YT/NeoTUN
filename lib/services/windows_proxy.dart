import 'dart:io';

/// WindowsProxy - управление системным прокси на Windows
/// Архитектура как в v2rayN - использует WinAPI
/// 
/// Основано на: https://github.com/2dust/v2rayN
class WindowsProxy {
  static final WindowsProxy instance = WindowsProxy._();
  WindowsProxy._();

  bool _isEnabled = false;
  
  bool get isEnabled => _isEnabled;

  /// Включить системный прокси
  Future<bool> enableProxy(String host, int port) async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // Устанавливаем новый прокси через reg
      final proxyServer = '$host:$port';
      
      // Включаем прокси
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);
      
      // Устанавливаем адрес прокси
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);
      
      // Исключения для локальных адресов
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyOverride',
        '/t',
        'REG_SZ',
        '/d',
        'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>',
        '/f',
      ]);
      
      // Уведомляем систему об изменениях
      await _notifyProxyChange();
      
      _isEnabled = true;
      print('[WindowsProxy] ✓ Proxy enabled: $proxyServer');
      return true;
      
    } catch (e) {
      print('[WindowsProxy] Failed to enable proxy: $e');
      return false;
    }
  }

  /// Отключить системный прокси
  Future<bool> disableProxy() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // Отключаем прокси
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);
      
      // Очищаем адрес прокси
      await Process.run('reg', [
        'delete',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyServer',
        '/f',
      ]);
      
      // Уведомляем систему об изменениях
      await _notifyProxyChange();
      
      _isEnabled = false;
      print('[WindowsProxy] ✓ Proxy disabled');
      return true;
      
    } catch (e) {
      print('[WindowsProxy] Failed to disable proxy: $e');
      return false;
    }
  }



  /// Уведомить систему об изменении настроек прокси
  Future<void> _notifyProxyChange() async {
    // Используем PowerShell для уведомления системы
    await Process.run('powershell', [
      '-Command',
      r'''
      $signature = @"
      [DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
      public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
      "@
      $type = Add-Type -MemberDefinition $signature -Name WinINet -Namespace InternetSettings -PassThru
      $type::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
      $type::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null
      '''
    ]);
  }

  /// Проверить текущее состояние прокси
  Future<bool> checkProxyStatus() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      final result = await Process.run('reg', [
        'query',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'ProxyEnable\s+REG_DWORD\s+0x(\d+)').firstMatch(output);
        if (match != null) {
          final value = int.tryParse(match.group(1)!, radix: 16) ?? 0;
          _isEnabled = value == 1;
          return _isEnabled;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
