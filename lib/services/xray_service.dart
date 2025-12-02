import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_config.dart';
import 'xray_android_service.dart';

/// Минималистичный сервис для работы с Xray-core
/// Только самое необходимое для работы
class XrayService {
  static final XrayService instance = XrayService._();
  XrayService._();

  Process? _process;
  VpnConfig? _activeConfig;
  final _logController = StreamController<String>.broadcast();
  
  Stream<String> get logStream => _logController.stream;
  
  bool get isRunning {
    if (Platform.isAndroid) {
      // На Android проверяем через нативный сервис
      return _activeConfig != null;
    }
    return _process != null;
  }
  
  VpnConfig? get activeConfig => _activeConfig;

  /// Запустить Xray с конфигурацией
  Future<void> start(VpnConfig config) async {
    // На Android используем VPN сервис
    if (Platform.isAndroid) {
      _log('Using Android VPN service...');
      await XrayAndroidService.instance.start(config);
      _activeConfig = config;
      
      // Подписываемся на логи Android сервиса
      XrayAndroidService.instance.logStream.listen((log) {
        _logController.add(log);
      });
      
      return;
    }
    
    // На других платформах используем Process
    if (_process != null) {
      await stop();
    }

    try {
      // Получаем путь к xray
      final xrayPath = await _getXrayPath();
      
      // Проверяем что xray существует
      if (!await File(xrayPath).exists()) {
        throw Exception('Xray not found at: $xrayPath\nPlease install Xray core first.');
      }

      // Создаём временный файл конфигурации
      final configFile = await _createConfigFile(config.config);
      
      _log('Starting Xray...');
      _log('Xray path: $xrayPath');
      _log('Config file: ${configFile.path}');

      // Запускаем xray
      if (Platform.isWindows) {
        _process = await Process.start(
          xrayPath,
          ['run', '-c', configFile.path],
          runInShell: true,
        );
      } else {
        _process = await Process.start(
          xrayPath,
          ['run', '-c', configFile.path],
        );
      }

      _activeConfig = config;
      _log('✓ Xray started successfully');

      // Слушаем вывод
      _process!.stdout.transform(utf8.decoder).listen((data) {
        _log('[OUT] $data');
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        _log('[ERR] $data');
      });

      _process!.exitCode.then((code) {
        _log('Xray exited with code: $code');
        _process = null;
        _activeConfig = null;
      });

      // Ждём инициализации
      await Future.delayed(const Duration(seconds: 2));

    } catch (e, stack) {
      _log('Failed to start Xray: $e');
      _log('Stack: $stack');
      _process = null;
      _activeConfig = null;
      rethrow;
    }
  }

  /// Остановить Xray
  Future<void> stop() async {
    // На Android используем VPN сервис
    if (Platform.isAndroid) {
      await XrayAndroidService.instance.stop();
      _activeConfig = null;
      return;
    }
    
    // На других платформах используем Process
    if (_process != null) {
      _log('Stopping Xray...');
      
      _process!.kill(ProcessSignal.sigterm);
      await Future.delayed(const Duration(seconds: 1));
      
      if (_process != null) {
        _process!.kill(ProcessSignal.sigkill);
      }
      
      _process = null;
      _activeConfig = null;
      
      _log('✓ Xray stopped');
    }
  }

  /// Получить путь к xray исполняемому файлу
  Future<String> _getXrayPath() async {
    if (Platform.isAndroid) {
      final appDir = await getApplicationSupportDirectory();
      return '${appDir.path}/cores/xray';
    } else if (Platform.isWindows) {
      final currentDir = Directory.current;
      return '${currentDir.path}\\cores\\xray.exe';
    } else {
      return 'cores/xray';
    }
  }

  /// Создать временный файл конфигурации
  Future<File> _createConfigFile(Map<String, dynamic> config) async {
    final tempDir = await getTemporaryDirectory();
    final configFile = File('${tempDir.path}/xray_config.json');
    
    // Добавляем базовые настройки если их нет
    final finalConfig = _ensureBasicConfig(config);
    
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(finalConfig),
    );
    
    return configFile;
  }

  /// Убедиться что конфигурация содержит базовые настройки
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
          '8.8.8.8',
          '8.8.4.4',
          '1.1.1.1',
        ],
      };
    }

    // Inbounds - если нет, добавляем SOCKS и HTTP
    if (!result.containsKey('inbounds') || (result['inbounds'] as List).isEmpty) {
      result['inbounds'] = [
        {
          'port': 10808,
          'protocol': 'socks',
          'settings': {
            'auth': 'noauth',
            'udp': true,
          },
          'sniffing': {
            'enabled': true,
            'destOverride': ['http', 'tls'],
          },
        },
        {
          'port': 10809,
          'protocol': 'http',
        },
      ];
    }

    // Routing - базовая маршрутизация
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

    // Outbounds - убедимся что есть direct и block
    if (result.containsKey('outbounds')) {
      final outbounds = result['outbounds'] as List;
      
      // Проверяем наличие direct
      if (!outbounds.any((o) => o['tag'] == 'direct')) {
        outbounds.add({
          'protocol': 'freedom',
          'tag': 'direct',
        });
      }
      
      // Проверяем наличие block
      if (!outbounds.any((o) => o['tag'] == 'block')) {
        outbounds.add({
          'protocol': 'blackhole',
          'tag': 'block',
        });
      }
    }

    return result;
  }

  /// Проверить установлен ли Xray
  Future<bool> isInstalled() async {
    try {
      final xrayPath = await _getXrayPath();
      return await File(xrayPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Получить версию Xray
  Future<String?> getVersion() async {
    try {
      final xrayPath = await _getXrayPath();
      
      if (!await File(xrayPath).exists()) {
        return null;
      }

      final result = await Process.run(xrayPath, ['version']);
      final output = result.stdout.toString();
      
      // Парсим версию из вывода
      final versionRegex = RegExp(r'Xray (\d+\.\d+\.\d+)');
      final match = versionRegex.firstMatch(output);
      
      return match?.group(1) ?? 'Installed';
    } catch (e) {
      return null;
    }
  }

  void _log(String message) {
    print('[XrayService] $message');
    _logController.add(message);
  }

  void dispose() {
    _logController.close();
  }
}
