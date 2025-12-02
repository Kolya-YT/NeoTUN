import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_config.dart';

/// Android VPN сервис для Xray
/// Использует нативный V2rayVpnService через MethodChannel
class XrayAndroidService {
  static final XrayAndroidService instance = XrayAndroidService._();
  XrayAndroidService._();

  static const platform = MethodChannel('com.neotun.app/vpn');
  
  VpnConfig? _activeConfig;
  final _logController = StreamController<String>.broadcast();
  
  Stream<String> get logStream => _logController.stream;
  VpnConfig? get activeConfig => _activeConfig;

  /// Проверить запущен ли VPN
  Future<bool> isRunning() async {
    try {
      final result = await platform.invokeMethod('isRunning');
      return result as bool;
    } catch (e) {
      _log('Error checking VPN status: $e');
      return false;
    }
  }

  /// Запустить VPN с конфигурацией
  Future<void> start(VpnConfig config) async {
    try {
      _log('Starting Android VPN...');
      
      // Создаём файл конфигурации
      final configFile = await _createConfigFile(config.config);
      _log('Config file created: ${configFile.path}');
      
      // Запускаем VPN через нативный сервис
      await platform.invokeMethod('startTun', {
        'coreType': 'xray',
        'configPath': configFile.path,
      });
      
      _activeConfig = config;
      _log('✓ Android VPN started successfully');
      
    } catch (e, stack) {
      _log('Failed to start Android VPN: $e');
      _log('Stack: $stack');
      _activeConfig = null;
      rethrow;
    }
  }

  /// Остановить VPN
  Future<void> stop() async {
    try {
      _log('Stopping Android VPN...');
      
      await platform.invokeMethod('stopTun');
      
      _activeConfig = null;
      _log('✓ Android VPN stopped');
      
    } catch (e) {
      _log('Error stopping Android VPN: $e');
      rethrow;
    }
  }

  /// Создать файл конфигурации
  Future<File> _createConfigFile(Map<String, dynamic> config) async {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File('${appDir.path}/xray_config.json');
    
    // Добавляем базовые настройки если их нет
    final finalConfig = _ensureBasicConfig(config);
    
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(finalConfig),
    );
    
    return configFile;
  }

  /// Убедиться что конфигурация содержит базовые настройки для Android VPN
  Map<String, dynamic> _ensureBasicConfig(Map<String, dynamic> config) {
    final result = Map<String, dynamic>.from(config);

    // Log
    if (!result.containsKey('log')) {
      result['log'] = {
        'loglevel': 'warning',
      };
    }

    // DNS
    if (!result.containsKey('dns')) {
      result['dns'] = {
        'servers': [
          '1.1.1.1',
          '8.8.8.8',
        ],
      };
    }

    // Inbounds - для Android VPN нужен dokodemo-door
    if (!result.containsKey('inbounds') || (result['inbounds'] as List).isEmpty) {
      result['inbounds'] = [
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
        },
      ];
    }

    // Routing
    if (!result.containsKey('routing')) {
      result['routing'] = {
        'domainStrategy': 'AsIs',
        'rules': [
          {
            'type': 'field',
            'ip': ['geoip:private'],
            'outboundTag': 'direct',
          },
        ],
      };
    }

    // Outbounds
    if (result.containsKey('outbounds')) {
      final outbounds = result['outbounds'] as List;
      
      if (!outbounds.any((o) => o['tag'] == 'direct')) {
        outbounds.add({
          'protocol': 'freedom',
          'tag': 'direct',
        });
      }
      
      if (!outbounds.any((o) => o['tag'] == 'block')) {
        outbounds.add({
          'protocol': 'blackhole',
          'tag': 'block',
        });
      }
    }

    return result;
  }

  void _log(String message) {
    print('[XrayAndroidService] $message');
    _logController.add(message);
  }

  void dispose() {
    _logController.close();
  }
}
