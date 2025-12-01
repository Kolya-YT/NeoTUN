import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import '../models/core_type.dart';
import '../models/vpn_config.dart';
import '../models/core_manifest.dart';
import 'download_service.dart';
import 'system_proxy.dart';
import 'tun_manager.dart';

class CoreManager {
  static final CoreManager instance = CoreManager._();
  CoreManager._();

  // Для тестирования используем локальный манифест, в продакшене замените на реальный URL
  static const manifestUrl = 'https://raw.githubusercontent.com/XTLS/Xray-core/main/release/version.json';

  late Directory _coreDir;
  Process? _runningProcess;
  VpnConfig? _activeConfig;
  CoreManifest? _manifest;
  
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  Future<void> init() async {
    try {
      if (Platform.isAndroid) {
        // На Android используем app support directory (имеет правильные SELinux контексты)
        final appDir = await getApplicationSupportDirectory();
        _coreDir = Directory('${appDir.path}/cores');
        if (!await _coreDir.exists()) {
          await _coreDir.create(recursive: true);
        }
        print('Using Android app support directory: ${_coreDir.path}');
      } else {
        // На других платформах используем локальную папку
        final currentDir = Directory.current;
        _coreDir = Directory('${currentDir.path}/cores');
        
        if (!await _coreDir.exists()) {
          await _coreDir.create(recursive: true);
        }
        print('Using cores directory: ${_coreDir.path}');
      }
    } catch (e) {
      print('Failed to initialize cores directory: $e');
      // Fallback to temp directory
      final tempDir = await getTemporaryDirectory();
      _coreDir = Directory('${tempDir.path}/cores');
      if (!await _coreDir.exists()) {
        await _coreDir.create(recursive: true);
      }
      print('Using fallback temp directory: ${_coreDir.path}');
    }
  }

  String getCorePath(CoreType coreType) {
    final ext = Platform.isWindows ? '.exe' : '';
    return '${_coreDir.path}/${coreType.executableName}$ext';
  }

  String getBackupCorePath(CoreType coreType) {
    final ext = Platform.isWindows ? '.exe' : '';
    return '${_coreDir.path}/${coreType.executableName}.backup$ext';
  }

  Future<bool> isCoreInstalled(CoreType coreType) async {
    final file = File(getCorePath(coreType));
    return await file.exists();
  }

  Future<String?> getCoreVersion(CoreType coreType) async {
    if (!await isCoreInstalled(coreType)) return null;
    try {
      final result = await Process.run(
        getCorePath(coreType), 
        ['version'], 
        runInShell: true,
      );
      
      // Try to parse version from output
      String output;
      if (result.stdout is List<int>) {
        // If stdout is bytes, decode as UTF-8
        output = utf8.decode(result.stdout as List<int>, allowMalformed: true);
      } else {
        output = result.stdout.toString();
      }
      
      // Extract version number using regex
      final versionRegex = RegExp(r'v?(\d+\.\d+\.\d+)');
      final match = versionRegex.firstMatch(output);
      
      if (match != null) {
        return match.group(1);
      }
      
      // If no version found, return "Installed"
      return 'Installed';
    } catch (e) {
      print('Error getting version for ${coreType.displayName}: $e');
      return 'Installed';
    }
  }

  Future<CoreManifest?> fetchManifest() async {
    try {
      final response = await http.get(Uri.parse(manifestUrl));
      if (response.statusCode == 200) {
        _manifest = CoreManifest.fromJsonString(response.body);
        return _manifest;
      }
    } catch (e) {
      print('Error fetching manifest: $e');
    }
    return null;
  }

  Future<void> downloadCore(CoreType coreType, {Function(int received, int total)? onProgress}) async {
    // Получаем URL напрямую из GitHub Releases
    String downloadUrl;
    
    try {
      final releaseUrl = _getReleaseApiUrl(coreType);
      final response = await http.get(Uri.parse(releaseUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch release info: ${response.statusCode}');
      }
      
      final releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      final assets = releaseData['assets'] as List<dynamic>;
      
      final pattern = _getAssetPattern(coreType);
      String? foundUrl;
      
      for (final asset in assets) {
        final name = asset['name'] as String;
        if (name.contains(pattern)) {
          foundUrl = asset['browser_download_url'] as String;
          break;
        }
      }
      
      if (foundUrl == null) {
        throw Exception('No suitable asset found for ${coreType.displayName}');
      }
      
      downloadUrl = foundUrl;
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
    
    final corePath = getCorePath(coreType);
    final tempPath = '$corePath.tmp';
    
    // Backup existing core
    if (await File(corePath).exists()) {
      await File(corePath).copy(getBackupCorePath(coreType));
    }
    
    try {
      // Скачиваем без проверки SHA256 (можно добавить позже)
      await DownloadService.instance.downloadFile(
        downloadUrl,
        tempPath,
        onProgress: onProgress,
      );
      
      // Если это zip, распаковываем
      if (downloadUrl.endsWith('.zip')) {
        await _extractZip(tempPath, _coreDir.path);
        await File(tempPath).delete();
        
        // После распаковки нужно найти исполняемый файл
        final executableName = coreType.executableName;
        final ext = Platform.isWindows ? '.exe' : '';
        
        // Ищем исполняемый файл рекурсивно
        bool found = false;
        await for (final entity in _coreDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.toLowerCase() == '$executableName$ext'.toLowerCase()) {
              // Копируем в корень папки cores
              await entity.copy(corePath);
              found = true;
              
              // Удаляем временные файлы
              try {
                final parentDir = entity.parent;
                if (parentDir.path != _coreDir.path) {
                  await parentDir.delete(recursive: true);
                }
              } catch (e) {
                print('Failed to cleanup temp files: $e');
              }
              break;
            }
          }
        }
        
        if (!found) {
          throw Exception('Executable $executableName$ext not found after extraction');
        }
      } else {
        final tempFile = File(tempPath);
        await tempFile.rename(corePath);
      }
      
      // Set executable permission on Unix/Android
      if (!Platform.isWindows) {
        try {
          // Try using chmod command
          final result = await Process.run('chmod', ['755', corePath]);
          if (result.exitCode != 0) {
            print('chmod failed: ${result.stderr}');
            // Try alternative method using File API
            final file = File(corePath);
            // On Android, we need to ensure the file is executable
            if (Platform.isAndroid) {
              // Copy to a location with executable permissions
              final execDir = Directory('${_coreDir.path}/bin');
              if (!await execDir.exists()) {
                await execDir.create(recursive: true);
              }
              final execPath = '${execDir.path}/${coreType.executableName}';
              await file.copy(execPath);
              await file.delete();
              await File(execPath).rename(corePath);
            }
          }
        } catch (e) {
          print('Failed to set executable permission: $e');
        }
      }
      
      // Delete backup on success
      final backup = File(getBackupCorePath(coreType));
      if (await backup.exists()) {
        await backup.delete();
      }
    } catch (e) {
      // Rollback on error
      final backup = File(getBackupCorePath(coreType));
      if (await backup.exists()) {
        await backup.copy(corePath);
        await backup.delete();
      }
      
      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.delete();
      }
      
      rethrow;
    }
  }
  
  String _getReleaseApiUrl(CoreType coreType) {
    switch (coreType) {
      case CoreType.xray:
        return 'https://api.github.com/repos/XTLS/Xray-core/releases/latest';
      case CoreType.singbox:
        return 'https://api.github.com/repos/SagerNet/sing-box/releases/latest';
      case CoreType.hysteria2:
        return 'https://api.github.com/repos/apernet/hysteria/releases/latest';
    }
  }
  
  String _getAssetPattern(CoreType coreType) {
    if (Platform.isWindows) {
      switch (coreType) {
        case CoreType.xray:
          return 'windows-64.zip';
        case CoreType.singbox:
          return 'windows-amd64.zip';
        case CoreType.hysteria2:
          return 'windows-amd64.exe';
      }
    } else if (Platform.isAndroid) {
      switch (coreType) {
        case CoreType.xray:
          return 'android-arm64-v8a.zip';
        case CoreType.singbox:
          return 'android-arm64.zip';
        case CoreType.hysteria2:
          return 'android-arm64';
      }
    }
    return '';
  }
  
  Future<void> _extractZip(String zipPath, String targetDir) async {
    try {
      // Используем пакет archive для кроссплатформенной распаковки
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        final filePath = '$targetDir${Platform.pathSeparator}$filename';
        
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
      
      print('Successfully extracted ${archive.length} files to $targetDir');
    } catch (e) {
      print('Failed to extract ZIP: $e');
      throw Exception('Failed to extract ZIP: $e');
    }
  }

  Future<void> rollbackCore(CoreType coreType) async {
    final backup = File(getBackupCorePath(coreType));
    if (!await backup.exists()) throw Exception('No backup found for ${coreType.displayName}');
    final corePath = getCorePath(coreType);
    await backup.copy(corePath);
    await backup.delete();
  }

  Future<void> startCore(VpnConfig config, {bool useTun = false}) async {
    if (_runningProcess != null) await stopCore();
    final corePath = getCorePath(config.coreType);
    if (!await File(corePath).exists()) throw Exception('Core ${config.coreType.displayName} not installed');
    
    final configFile = File('${_coreDir.path}/temp_config.json');
    
    // Если используем TUN, модифицируем конфигурацию
    Map<String, dynamic> finalConfig = config.config;
    if (useTun && config.coreType == CoreType.singbox) {
      finalConfig = TunManager.instance.createSingboxTunConfig(
        baseConfig: config.config,
      );
      _logController.add('[TUN] Using TUN mode for sing-box');
    }
    
    try {
      await configFile.writeAsString(jsonEncode(finalConfig));
      _logController.add('[CONFIG] Config file written: ${configFile.path}');
      _logController.add('[CONFIG] Config size: ${await configFile.length()} bytes');
      
      // Проверяем что файл действительно создан
      if (!await configFile.exists()) {
        throw Exception('Failed to create config file');
      }
    } catch (e) {
      _logController.add('[ERROR] Failed to write config: $e');
      throw Exception('Failed to write config file: $e');
    }
    
    // Получаем порт из конфигурации
    final port = SystemProxy.instance.getInboundPort(finalConfig);
    _logController.add('[PORT] Inbound port: ${port ?? 'not found'}');
    
    final args = _getStartArgs(config.coreType, configFile.path);
    _logController.add('[ARGS] Command arguments: ${args.join(' ')}');
    
    try {
      // On Android, we need to run through shell with explicit permissions
      if (Platform.isAndroid) {
        // Ensure executable permission before running
        await Process.run('chmod', ['755', corePath]);
        
        // Run through shell
        final command = '$corePath ${args.join(' ')}';
        _runningProcess = await Process.start(
          'sh',
          ['-c', command],
        );
      } else {
        _runningProcess = await Process.start(
          corePath, 
          args,
          runInShell: Platform.isWindows,
        );
      }
      _activeConfig = config;
      
      _logController.add('[START] Core ${config.coreType.displayName} started');
      _logController.add('[CONFIG] Using config: ${configFile.path}');
      _logController.add('[COMMAND] $corePath ${args.join(' ')}');
      
      // Проверяем что процесс не упал сразу
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Проверяем что процесс все еще работает
      try {
        final pid = _runningProcess!.pid;
        _logController.add('[PID] Process ID: $pid');
        
        // Ждем еще немного для полной инициализации
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Проверяем что процесс не завершился
        if (_runningProcess == null) {
          throw Exception('Process terminated immediately after start');
        }
      } catch (e) {
        _logController.add('[ERROR] Process check failed: $e');
        throw Exception('Failed to start core: $e');
      }
      
      // Включаем системный прокси только если не TUN режим
      if (!useTun && port != null) {
        final proxyEnabled = await SystemProxy.instance.enableProxy('127.0.0.1', port);
        if (proxyEnabled) {
          _logController.add('[PROXY] ✓ System proxy enabled: 127.0.0.1:$port');
          
          // Проверяем подключение
          await Future.delayed(const Duration(seconds: 1));
          final connected = await SystemProxy.instance.testConnection();
          if (connected) {
            _logController.add('[TEST] ✓ Proxy connection successful');
          } else {
            _logController.add('[TEST] ⚠ Proxy connection test failed');
          }
        } else {
          _logController.add('[PROXY] ⚠ Failed to enable system proxy');
        }
      }
      
      // Мониторинг вывода
      _runningProcess!.stdout.transform(utf8.decoder).listen((data) {
        _logController.add('[STDOUT] $data');
      });
      
      _runningProcess!.stderr.transform(utf8.decoder).listen((data) {
        _logController.add('[STDERR] $data');
      });
      
      _runningProcess!.exitCode.then((code) {
        _logController.add('[EXIT] Process exited with code $code');
        if (code != 0) {
          _logController.add('[ERROR] Core crashed or stopped unexpectedly');
        }
        _runningProcess = null;
        _activeConfig = null;
        
        // Отключаем прокси при остановке
        SystemProxy.instance.disableProxy();
      });
      
    } catch (e, stackTrace) {
      _logController.add('[ERROR] Failed to start core: $e');
      _logController.add('[STACK] ${stackTrace.toString().split('\n').take(5).join('\n')}');
      
      // Очищаем состояние
      if (_runningProcess != null) {
        try {
          _runningProcess!.kill();
        } catch (_) {}
      }
      _runningProcess = null;
      _activeConfig = null;
      
      rethrow;
    }
  }

  List<String> _getStartArgs(CoreType coreType, String configPath) {
    switch (coreType) {
      case CoreType.xray:
        return ['run', '-c', configPath];
      case CoreType.singbox:
        return ['run', '-c', configPath];
      case CoreType.hysteria2:
        return ['--config', configPath];
    }
  }

  Future<void> stopCore() async {
    if (_runningProcess != null) {
      _logController.add('[STOP] Stopping core...');
      
      // Отключаем системный прокси
      await SystemProxy.instance.disableProxy();
      _logController.add('[PROXY] ✓ System proxy disabled');
      
      // Останавливаем процесс
      _runningProcess!.kill(ProcessSignal.sigterm);
      await Future.delayed(const Duration(seconds: 2));
      
      if (_runningProcess != null) {
        _logController.add('[STOP] Force killing process...');
        _runningProcess!.kill(ProcessSignal.sigkill);
      }
      
      _runningProcess = null;
      _activeConfig = null;
      _logController.add('[STOP] ✓ Core stopped');
    }
  }



  bool get isRunning => _runningProcess != null;
  VpnConfig? get activeConfig => _activeConfig;
  Directory get coreDirectory => _coreDir;

  void dispose() {
    _logController.close();
  }
}
