import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_config.dart';

/// XrayWindowsService - сервис для работы с Xray на Windows
/// Архитектура как в v2rayN:
/// - Запуск xray.exe через Process
/// - Управление системным прокси через WinAPI
/// - Мониторинг статистики через API
/// 
/// Основано на: https://github.com/2dust/v2rayN
class XrayWindowsService {
  static final XrayWindowsService instance = XrayWindowsService._();
  XrayWindowsService._();

  Process? _process;
  VpnConfig? _activeConfig;
  final _logController = StreamController<String>.broadcast();
  Timer? _statsTimer;
  
  Stream<String> get logStream => _logController.stream;
  bool get isRunning => _process != null;
  VpnConfig? get activeConfig => _activeConfig;

  /// Запустить Xray с конфигурацией
  Future<void> start(VpnConfig config) async {
    if (_process != null) {
      await stop();
    }

    try {
      // Получаем путь к xray.exe
      final xrayPath = await _getXrayPath();
      
      // Проверяем что xray.exe существует
      if (!await File(xrayPath).exists()) {
        throw Exception('Xray not found at: $xrayPath\nPlease install Xray core first.');
      }

      // Создаём временный файл конфигурации
      final configFile = await _createConfigFile(config.config);
      
      _log('Starting Xray...');
      _log('Xray path: $xrayPath');
      _log('Config file: ${configFile.path}');

      // Запускаем xray.exe как в v2rayN
      _log('Executing: $xrayPath run -c ${configFile.path}');
      
      _process = await Process.start(
        xrayPath,
        ['run', '-c', configFile.path],
        runInShell: false, // Не используем shell для лучшего контроля
      );

      _activeConfig = config;
      _log('✓ Xray process started (PID: ${_process!.pid})');

      // Слушаем вывод
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _log('[STDOUT] $line');
          }
        }
      }, onError: (error) {
        _log('[STDOUT ERROR] $error');
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _log('[STDERR] $line');
          }
        }
      }, onError: (error) {
        _log('[STDERR ERROR] $error');
      });

      // Проверяем что процесс запустился
      _log('Waiting for process initialization...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Проверяем exitCode - если процесс уже завершился, будет доступен
      final exitCodeFuture = _process!.exitCode;
      final timeoutFuture = Future.delayed(const Duration(seconds: 3));
      
      _log('Checking process status...');
      final result = await Future.any([exitCodeFuture, timeoutFuture]);
      
      if (result is int) {
        // Процесс завершился с ошибкой
        _log('❌ Process terminated with exit code: $result');
        _log('Config file location: ${configFile.path}');
        _log('Xray path: $xrayPath');
        
        // Читаем конфиг для логирования
        try {
          final configContent = await configFile.readAsString();
          _log('Configuration used:');
          _log(configContent);
        } catch (e) {
          _log('Failed to read config: $e');
        }
        
        _process = null;
        _activeConfig = null;
        throw Exception('Xray process terminated with exit code: $result\n\nPossible causes:\n- Invalid configuration\n- Missing Xray core\n- Port already in use\n\nCheck logs above for details.');
      }
      
      _log('✓ Process is running');
      
      // Процесс работает, настраиваем обработчик завершения
      _process!.exitCode.then((code) {
        _log('⚠ Xray exited with code: $code');
        _process = null;
        _activeConfig = null;
        _statsTimer?.cancel();
      });

      // Запускаем мониторинг статистики
      _startStatsMonitoring();

      _log('✓ Xray started successfully');

    } catch (e, stack) {
      _log('❌ Failed to start Xray: $e');
      _log('Stack trace:');
      _log(stack.toString());
      _process = null;
      _activeConfig = null;
      rethrow;
    }
  }

  /// Остановить Xray
  Future<void> stop() async {
    if (_process != null) {
      _log('Stopping Xray...');
      
      _statsTimer?.cancel();
      _statsTimer = null;
      
      // Пытаемся graceful shutdown
      _process!.kill(ProcessSignal.sigterm);
      
      // Ждём завершения
      await Future.delayed(const Duration(seconds: 2));
      
      // Если не завершился - убиваем
      if (_process != null) {
        _process!.kill(ProcessSignal.sigkill);
      }
      
      _process = null;
      _activeConfig = null;
      
      _log('✓ Xray stopped');
    }
  }

  /// Получить путь к xray.exe
  Future<String> _getXrayPath() async {
    final currentDir = Directory.current;
    final xrayPath = '${currentDir.path}\\cores\\xray.exe';
    _log('Xray path: $xrayPath');
    _log('Current directory: ${currentDir.path}');
    
    // Проверяем существование
    final exists = await File(xrayPath).exists();
    _log('Xray exists: $exists');
    
    if (exists) {
      final stat = await File(xrayPath).stat();
      _log('Xray file size: ${stat.size} bytes');
      _log('Xray modified: ${stat.modified}');
    }
    
    return xrayPath;
  }

  /// Создать временный файл конфигурации
  Future<File> _createConfigFile(Map<String, dynamic> config) async {
    final tempDir = await getTemporaryDirectory();
    final configFile = File('${tempDir.path}\\xray_config.json');
    
    _log('Creating config file: ${configFile.path}');
    
    // Добавляем базовые настройки если их нет
    final finalConfig = _ensureBasicConfig(config);
    
    final configJson = const JsonEncoder.withIndent('  ').convert(finalConfig);
    await configFile.writeAsString(configJson);
    
    _log('Config file created (${configJson.length} bytes)');
    
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
          '1.1.1.1',
          '8.8.8.8',
          '8.8.4.4',
        ],
      };
    }

    // Inbounds - SOCKS и HTTP прокси
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
          'tag': 'socks-in',
        },
        {
          'port': 10809,
          'protocol': 'http',
          'tag': 'http-in',
        },
      ];
    }

    // API для статистики (как в v2rayN)
    if (!result.containsKey('api')) {
      result['api'] = {
        'tag': 'api',
        'services': ['StatsService'],
      };
    }

    // Stats для мониторинга трафика
    if (!result.containsKey('stats')) {
      result['stats'] = {};
    }

    // Policy для статистики
    if (!result.containsKey('policy')) {
      result['policy'] = {
        'system': {
          'statsInboundUplink': true,
          'statsInboundDownlink': true,
          'statsOutboundUplink': true,
          'statsOutboundDownlink': true,
        },
      };
    }

    // Routing - базовая маршрутизация
    if (!result.containsKey('routing')) {
      result['routing'] = {
        'domainStrategy': 'AsIs',
        'rules': [
          {
            'type': 'field',
            'inboundTag': ['api'],
            'outboundTag': 'api',
          },
          {
            'type': 'field',
            'ip': ['geoip:private'],
            'outboundTag': 'direct',
          },
        ],
      };
    } else {
      // Добавляем правило для API если его нет
      final routing = result['routing'] as Map<String, dynamic>;
      final rules = (routing['rules'] as List?) ?? [];
      
      if (!rules.any((r) => r['inboundTag']?.contains('api') == true)) {
        rules.insert(0, {
          'type': 'field',
          'inboundTag': ['api'],
          'outboundTag': 'api',
        });
        routing['rules'] = rules;
      }
    }

    // Outbounds - убедимся что есть direct, block и api
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
      
      if (!outbounds.any((o) => o['tag'] == 'api')) {
        outbounds.add({
          'protocol': 'dokodemo-door',
          'tag': 'api',
          'settings': {
            'address': '127.0.0.1',
          },
        });
      }
    }

    return result;
  }

  /// Запустить мониторинг статистики
  void _startStatsMonitoring() {
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _queryStats();
    });
  }

  /// Запросить статистику у Xray
  Future<void> _queryStats() async {
    // TODO: Реализовать запрос статистики через gRPC API
    // Пока просто логируем что процесс работает
    if (_process != null) {
      _log('[Stats] Xray is running');
    }
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
    print('[XrayWindowsService] $message');
    _logController.add(message);
  }

  void dispose() {
    _statsTimer?.cancel();
    _logController.close();
  }
}
