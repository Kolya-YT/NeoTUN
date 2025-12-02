import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/core_type.dart';

enum TunMode {
  proxy,  // Системный прокси (HTTP/SOCKS)
  tun,    // TUN режим (полный перехват трафика)
}

class TunManager {
  static final TunManager instance = TunManager._();
  TunManager._();

  static const platform = MethodChannel('com.neotun.app/vpn');

  TunMode _currentMode = TunMode.proxy;
  bool _isTunEnabled = false;

  TunMode get currentMode => _currentMode;
  bool get isTunEnabled => _isTunEnabled;

  /// Включить TUN режим
  Future<bool> enableTun({
    required CoreType coreType,
    required String configPath,
  }) async {
    try {
      if (Platform.isAndroid) {
        return await _enableAndroidTun(coreType, configPath);
      } else if (Platform.isWindows) {
        return await _enableWindowsTun(coreType, configPath);
      }
      return false;
    } catch (e) {
      print('Failed to enable TUN: $e');
      return false;
    }
  }

  /// Отключить TUN режим
  Future<bool> disableTun() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('stopTun');
      } else if (Platform.isWindows) {
        await _disableWindowsTun();
      }
      
      _isTunEnabled = false;
      _currentMode = TunMode.proxy;
      return true;
    } catch (e) {
      print('Failed to disable TUN: $e');
      return false;
    }
  }

  /// Android TUN через VpnService
  Future<bool> _enableAndroidTun(CoreType coreType, String configPath) async {
    try {
      final result = await platform.invokeMethod('startTun', {
        'coreType': coreType.name,
        'configPath': configPath,
      });
      
      if (result == true) {
        _isTunEnabled = true;
        _currentMode = TunMode.tun;
        print('✓ Android TUN enabled');
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      print('Android TUN error: ${e.message}');
      return false;
    }
  }

  /// Windows TUN через sing-box или xray-tun
  Future<bool> _enableWindowsTun(CoreType coreType, String configPath) async {
    try {
      // Для Windows нужен специальный драйвер TUN/TAP
      // Проверяем наличие Wintun или TAP-Windows
      
      final hasWintun = await _checkWintunDriver();
      
      if (!hasWintun) {
        print('⚠ Wintun driver not found. TUN mode requires Wintun driver.');
        print('Download from: https://www.wintun.net/');
        return false;
      }

      // sing-box имеет встроенную поддержку TUN
      if (coreType == CoreType.singbox) {
        _isTunEnabled = true;
        _currentMode = TunMode.tun;
        print('✓ Windows TUN enabled (sing-box)');
        return true;
      }

      // Для XRay нужна дополнительная настройка
      print('⚠ TUN mode for XRay on Windows requires additional setup');
      return false;
      
    } catch (e) {
      print('Windows TUN error: $e');
      return false;
    }
  }

  Future<bool> _disableWindowsTun() async {
    // Просто останавливаем процесс, TUN интерфейс закроется автоматически
    return true;
  }

  /// Проверить наличие Wintun драйвера
  Future<bool> _checkWintunDriver() async {
    try {
      // Проверяем наличие wintun.dll
      final dllPaths = [
        'C:\\Windows\\System32\\wintun.dll',
        'wintun.dll', // В текущей директории
      ];

      for (final path in dllPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Проверяем через драйвер
      final result = await Process.run('sc', ['query', 'wintun']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Создать TUN конфигурацию для sing-box
  Map<String, dynamic> createSingboxTunConfig({
    required Map<String, dynamic> baseConfig,
    String tunAddress = '172.19.0.1/30',
    List<Map<String, dynamic>>? dnsServers,
  }) {
    final config = Map<String, dynamic>.from(baseConfig);
    
    print('[TUN] Creating sing-box TUN config');
    print('[TUN] Base config has ${baseConfig.keys.length} keys');
    
    // Добавляем TUN inbound
    config['inbounds'] = [
      {
        'type': 'tun',
        'tag': 'tun-in',
        'interface_name': 'neotun0',
        'inet4_address': tunAddress,
        'mtu': 9000,
        'auto_route': true,
        'strict_route': true,
        'stack': 'system',
        'sniff': true,
        'sniff_override_destination': true,
      }
    ];

    // Настраиваем DNS
    config['dns'] = {
      'servers': dnsServers ?? [
        {
          'tag': 'dns-remote',
          'address': '8.8.8.8',
          'detour': 'proxy',
        },
        {
          'tag': 'dns-local',
          'address': 'local',
          'detour': 'direct',
        }
      ],
      'rules': [
        {
          'geosite': 'cn',
          'server': 'dns-local',
        }
      ],
      'strategy': 'prefer_ipv4',
    };
    
    // Убеждаемся что route настроен правильно
    if (config['route'] != null) {
      final route = config['route'] as Map<String, dynamic>;
      route['auto_detect_interface'] = true;
    }

    print('[TUN] TUN config created with ${config['inbounds'].length} inbounds');
    return config;
  }

  /// Создать TUN конфигурацию для XRay (через dokodemo-door)
  Map<String, dynamic> createXrayTunConfig({
    required Map<String, dynamic> baseConfig,
  }) {
    final config = Map<String, dynamic>.from(baseConfig);
    
    print('[TUN] Creating Xray TUN config (dokodemo-door mode)');
    
    // Для Xray используем dokodemo-door для перехвата трафика
    // Это работает с нативной библиотекой AndroidLibXrayLite
    config['inbounds'] = [
      {
        'tag': 'tun-in',
        'port': 10808,
        'protocol': 'dokodemo-door',
        'settings': {
          'network': 'tcp,udp',
          'followRedirect': true,
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
      }
    ];
    
    // Настраиваем DNS
    config['dns'] = {
      'servers': [
        '8.8.8.8',
        '8.8.4.4',
        'localhost',
      ],
    };
    
    // Настраиваем routing для TUN
    config['routing'] = {
      'domainStrategy': 'IPIfNonMatch',
      'rules': [
        {
          'type': 'field',
          'ip': ['geoip:private'],
          'outboundTag': 'direct',
        },
        {
          'type': 'field',
          'inboundTag': ['tun-in'],
          'outboundTag': 'proxy',
        },
      ],
    };
    
    print('[TUN] Xray TUN config created');
    return config;
  }

  /// Получить рекомендуемый режим для платформы
  TunMode getRecommendedMode() {
    if (Platform.isAndroid) {
      return TunMode.tun; // На Android TUN работает лучше
    } else if (Platform.isWindows) {
      return TunMode.proxy; // На Windows проще использовать прокси
    }
    return TunMode.proxy;
  }

  /// Проверить поддержку TUN на текущей платформе
  Future<bool> isTunSupported() async {
    if (Platform.isAndroid) {
      return true; // Android всегда поддерживает VpnService
    } else if (Platform.isWindows) {
      return await _checkWintunDriver();
    }
    return false;
  }
}
