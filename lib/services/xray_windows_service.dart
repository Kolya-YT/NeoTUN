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
    _log('=== Starting Xray on Windows ===');
    
    if (_process != null) {
      _log('Stopping existing Xray process...');
      await stop();
    }

    String? lastStderr;
    final stderrBuffer = StringBuffer();

    try {
      // Получаем путь к xray.exe
      final xrayPath = await _getXrayPath();
      _log('Step 1: Xray path: $xrayPath');
      
      // Проверяем что xray.exe существует
      final xrayFile = File(xrayPath);
      if (!await xrayFile.exists()) {
        _log('✗ ERROR: Xray not found at: $xrayPath');
        throw Exception('Xray not found at: $xrayPath\nPlease install Xray core first.');
      }
      _log('✓ Xray executable found');
      
      // Проверяем размер файла
      final fileSize = await xrayFile.length();
      _log('Xray file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Проверяем версию Xray для диагностики
      _log('Step 2: Checking Xray version...');
      try {
        final versionResult = await Process.run(xrayPath, ['version']);
        if (versionResult.exitCode == 0) {
          final versionOutput = versionResult.stdout.toString();
          _log('✓ Xray version: ${versionOutput.split('\n').first}');
        } else {
          _log('⚠ Warning: Xray version check returned code ${versionResult.exitCode}');
          _log('Version stderr: ${versionResult.stderr}');
        }
      } catch (e) {
        _log('⚠ Warning: Could not check Xray version: $e');
      }

      // Создаём временный файл конфигурации
      _log('Step 3: Creating config file...');
      final configFile = await _createConfigFile(config.config);
      _log('✓ Config file created: ${configFile.path}');
      
      // Проверяем что файл конфигурации создан
      if (!await configFile.exists()) {
        _log('✗ ERROR: Config file was not created!');
        throw Exception('Failed to create config file');
      }
      
      final configSize = await configFile.length();
      _log('Config file size: $configSize bytes');
      
      // Валидируем конфигурацию через xray
      _log('Step 4: Validating configuration...');
      try {
        final testResult = await Process.run(
          xrayPath,
          ['run', '-test', '-c', configFile.path],
          runInShell: false,
        );
        
        if (testResult.exitCode == 0) {
          _log('✓ Configuration is valid');
        } else {
          _log('✗ Configuration validation failed with code ${testResult.exitCode}');
          _log('Validation stdout: ${testResult.stdout}');
          _log('Validation stderr: ${testResult.stderr}');
          throw Exception('Invalid configuration (exit code ${testResult.exitCode}): ${testResult.stderr}');
        }
      } catch (e) {
        _log('✗ Configuration validation error: $e');
        // Логируем содержимое конфигурации для отладки
        try {
          final configContent = await configFile.readAsString();
          _log('Config content:\n$configContent');
        } catch (e2) {
          _log('Could not read config: $e2');
        }
        rethrow;
      }

      // Запускаем xray.exe
      _log('Step 5: Starting Xray process...');
      _log('Command: "$xrayPath" run -c "${configFile.path}"');
      _log('Working directory: ${Directory.current.path}');
      
      _process = await Process.start(
        xrayPath,
        ['run', '-c', configFile.path],
        runInShell: false,
        workingDirectory: Directory.current.path,
      );

      _activeConfig = config;
      _log('✓ Xray process started (PID: ${_process!.pid})');

      // Слушаем stdout
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _log('[Xray OUT] $line');
          }
        }
      });

      // Слушаем stderr с буферизацией
      _process!.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        lastStderr = data;
        
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            _log('[Xray ERR] $line');
            print('[Xray STDERR] $line');
          }
        }
      });

      // Проверяем что процесс запустился
      _log('Step 6: Waiting for process initialization...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Проверяем exitCode - если процесс уже завершился, будет доступен
      final exitCodeFuture = _process!.exitCode;
      final timeoutFuture = Future.delayed(const Duration(seconds: 3));
      
      final result = await Future.any([exitCodeFuture, timeoutFuture]);
      
      if (result is int) {
        // Процесс завершился с ошибкой
        _log('✗✗✗ Xray process terminated immediately with exit code: $result ✗✗✗');
        
        // Ждём немного чтобы получить все stderr
        await Future.delayed(const Duration(milliseconds: 500));
        
        final errorDetails = StringBuffer();
        errorDetails.writeln('Exit code: $result');
        
        if (stderrBuffer.isNotEmpty) {
          errorDetails.writeln('Error output:');
          errorDetails.writeln(stderrBuffer.toString());
        }
        
        // Специфичные сообщения для известных кодов ошибок
        String errorHint = '';
        switch (result) {
          case 23:
            errorHint = '\n\nExit code 23 usually means:\n'
                '- Invalid JSON in configuration\n'
                '- Missing required fields in config\n'
                '- Incompatible Xray version\n'
                '- Port already in use\n\n'
                'Try:\n'
                '1. Check if ports 10808/10809 are free\n'
                '2. Verify server configuration\n'
                '3. Update Xray core to latest version';
            break;
          case 1:
            errorHint = '\n\nExit code 1 usually means:\n'
                '- Configuration syntax error\n'
                '- Invalid protocol settings';
            break;
        }
        
        _process = null;
        _activeConfig = null;
        
        throw Exception('Xray process terminated with exit code: $result$errorHint\n\n${errorDetails.toString()}');
      }
      
      _log('✓ Process is running after 3 seconds');
      
      // Процесс работает, настраиваем обработчик завершения
      _process!.exitCode.then((code) {
        _log('⚠ Xray exited with code: $code');
        if (stderrBuffer.isNotEmpty) {
          _log('Last error output: ${stderrBuffer.toString()}');
        }
        _process = null;
        _activeConfig = null;
        _statsTimer?.cancel();
      });

      // Запускаем мониторинг статистики
      _startStatsMonitoring();

      _log('✓✓✓ Xray started successfully ✓✓✓');

    } catch (e, stack) {
      _log('✗✗✗ Failed to start Xray ✗✗✗');
      _log('Error: $e');
      _log('Stack trace: $stack');
      
      if (lastStderr != null) {
        _log('Last stderr: $lastStderr');
      }
      
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
    return '${currentDir.path}\\cores\\xray.exe';
  }

  /// Создать временный файл конфигурации
  Future<File> _createConfigFile(Map<String, dynamic> config) async {
    final tempDir = await getTemporaryDirectory();
    final configFile = File('${tempDir.path}\\xray_config.json');
    
    _log('Creating config file at: ${configFile.path}');
    
    // Проверяем что исходная конфигурация валидна
    if (config.isEmpty) {
      _log('⚠ Warning: Empty config provided');
    }
    
    // Добавляем базовые настройки если их нет
    final finalConfig = _ensureBasicConfig(config);
    
    // Проверяем порты перед запуском
    await _checkPorts([10808, 10809]);
    
    // Сохраняем конфигурацию
    String configJson;
    try {
      configJson = const JsonEncoder.withIndent('  ').convert(finalConfig);
    } catch (e) {
      _log('✗ Error encoding config to JSON: $e');
      _log('Config structure: ${finalConfig.keys.join(', ')}');
      rethrow;
    }
    
    await configFile.writeAsString(configJson);
    
    _log('✓ Config file created: ${configFile.path} (${configJson.length} bytes)');
    
    // Проверяем что файл записался
    if (!await configFile.exists()) {
      throw Exception('Config file was not created at ${configFile.path}');
    }
    
    return configFile;
  }
  
  /// Проверить доступность портов
  Future<void> _checkPorts(List<int> ports) async {
    for (final port in ports) {
      try {
        final socket = await ServerSocket.bind('127.0.0.1', port);
        await socket.close();
        _log('✓ Port $port is available');
      } catch (e) {
        _log('⚠ Warning: Port $port may be in use: $e');
        // Не бросаем исключение, просто предупреждаем
      }
    }
  }

  /// Убедиться что конфигурация содержит базовые настройки
  Map<String, dynamic> _ensureBasicConfig(Map<String, dynamic> config) {
    _log('Ensuring basic config...');
    final result = Map<String, dynamic>.from(config);

    // Log - увеличиваем уровень для отладки
    if (!result.containsKey('log')) {
      result['log'] = {
        'loglevel': 'debug', // Используем debug для получения больше информации
      };
      _log('Added default log config (debug level)');
    } else {
      _log('Log config present: ${result['log']}');
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
      _log('Added default DNS config');
    } else {
      _log('DNS config present');
    }

    // Inbounds - SOCKS и HTTP прокси
    if (!result.containsKey('inbounds') || (result['inbounds'] as List).isEmpty) {
      result['inbounds'] = [
        {
          'port': 10808,
          'listen': '127.0.0.1',
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
          'listen': '127.0.0.1',
          'protocol': 'http',
          'tag': 'http-in',
        },
      ];
      _log('Added default inbounds (SOCKS:10808, HTTP:10809)');
    } else {
      final inbounds = result['inbounds'] as List;
      _log('Inbounds present: ${inbounds.length} entries');
      for (var i = 0; i < inbounds.length; i++) {
        final inbound = inbounds[i];
        _log('  Inbound $i: ${inbound['protocol']} on port ${inbound['port']}');
      }
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
      _log('Outbounds present: ${outbounds.length} entries');
      
      // Логируем существующие outbounds
      for (var i = 0; i < outbounds.length; i++) {
        final outbound = outbounds[i];
        _log('  Outbound $i: ${outbound['protocol']} (tag: ${outbound['tag']})');
      }
      
      if (!outbounds.any((o) => o['tag'] == 'direct')) {
        outbounds.add({
          'protocol': 'freedom',
          'tag': 'direct',
        });
        _log('Added direct outbound');
      }
      
      if (!outbounds.any((o) => o['tag'] == 'block')) {
        outbounds.add({
          'protocol': 'blackhole',
          'tag': 'block',
        });
        _log('Added block outbound');
      }
      
      if (!outbounds.any((o) => o['tag'] == 'api')) {
        outbounds.add({
          'protocol': 'dokodemo-door',
          'tag': 'api',
          'settings': {
            'address': '127.0.0.1',
          },
        });
        _log('Added API outbound');
      }
    } else {
      _log('⚠ Warning: No outbounds in config!');
    }

    _log('✓ Config validation complete');
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
