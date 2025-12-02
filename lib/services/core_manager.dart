import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import '../models/core_type.dart';
import '../models/vpn_config.dart';
import 'download_service.dart';
import 'xray_service.dart';
import 'system_proxy.dart';
import 'traffic_stats.dart';
import 'tun_manager.dart';

class CoreManager {
  static final CoreManager instance = CoreManager._();
  CoreManager._();

  late Directory _coreDir;
  
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  Future<void> init() async {
    print('[CoreManager] Initializing...');
    try {
      if (Platform.isAndroid) {
        print('[CoreManager] Platform: Android');
        final appDir = await getApplicationSupportDirectory();
        print('[CoreManager] App dir: ${appDir.path}');
        _coreDir = Directory('${appDir.path}/cores');
      } else {
        print('[CoreManager] Platform: ${Platform.operatingSystem}');
        final currentDir = Directory.current;
        print('[CoreManager] Current dir: ${currentDir.path}');
        _coreDir = Directory('${currentDir.path}/cores');
      }
      
      print('[CoreManager] Cores directory: ${_coreDir.path}');
      
      if (!await _coreDir.exists()) {
        print('[CoreManager] Creating cores directory...');
        await _coreDir.create(recursive: true);
        print('[CoreManager] ✓ Cores directory created');
      } else {
        print('[CoreManager] ✓ Cores directory exists');
      }
      
      _log('✓ CoreManager initialized: ${_coreDir.path}');
    } catch (e, stack) {
      print('[CoreManager] ERROR: $e');
      print('[CoreManager] Stack: $stack');
      _log('Failed to initialize cores directory: $e');
      
      try {
        final tempDir = await getTemporaryDirectory();
        print('[CoreManager] Using temp directory: ${tempDir.path}');
        _coreDir = Directory('${tempDir.path}/cores');
        if (!await _coreDir.exists()) {
          await _coreDir.create(recursive: true);
        }
        print('[CoreManager] ✓ Fallback directory created');
      } catch (e2) {
        print('[CoreManager] FATAL: Cannot create fallback directory: $e2');
        rethrow;
      }
    }
  }

  String getCorePath(CoreType coreType) {
    final ext = Platform.isWindows ? '.exe' : '';
    return '${_coreDir.path}/${coreType.executableName}$ext';
  }

  Future<bool> isCoreInstalled(CoreType coreType) async {
    final file = File(getCorePath(coreType));
    return await file.exists();
  }

  Future<String?> getCoreVersion(CoreType coreType) async {
    return await XrayService.instance.getVersion();
  }

  Future<void> downloadCore(CoreType coreType, {Function(int received, int total)? onProgress}) async {
    try {
      final releaseUrl = 'https://api.github.com/repos/XTLS/Xray-core/releases/latest';
      final response = await http.get(Uri.parse(releaseUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch release info: ${response.statusCode}');
      }
      
      final releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      final assets = releaseData['assets'] as List<dynamic>;
      
      final pattern = _getAssetPattern();
      String? foundUrl;
      
      for (final asset in assets) {
        final name = asset['name'] as String;
        if (name.contains(pattern)) {
          foundUrl = asset['browser_download_url'] as String;
          break;
        }
      }
      
      if (foundUrl == null) {
        throw Exception('No suitable asset found for Xray');
      }
      
      final corePath = getCorePath(coreType);
      final tempPath = '$corePath.tmp';
      
      _log('Downloading Xray from: $foundUrl');
      
      await DownloadService.instance.downloadFile(
        foundUrl,
        tempPath,
        onProgress: onProgress,
      );
      
      if (foundUrl.endsWith('.zip')) {
        _log('Extracting ZIP...');
        await _extractZip(tempPath, _coreDir.path);
        await File(tempPath).delete();
        
        // Ищем исполняемый файл
        final executableName = coreType.executableName;
        final ext = Platform.isWindows ? '.exe' : '';
        
        bool found = false;
        await for (final entity in _coreDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.toLowerCase() == '$executableName$ext'.toLowerCase()) {
              await entity.copy(corePath);
              found = true;
              
              try {
                final parentDir = entity.parent;
                if (parentDir.path != _coreDir.path) {
                  await parentDir.delete(recursive: true);
                }
              } catch (e) {
                _log('Failed to cleanup temp files: $e');
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
      
      // Set executable permission
      if (!Platform.isWindows) {
        try {
          await Process.run('chmod', ['755', corePath]);
        } catch (e) {
          _log('Failed to set executable permission: $e');
        }
      }
      
      _log('✓ Xray downloaded successfully');
    } catch (e) {
      _log('Failed to download Xray: $e');
      rethrow;
    }
  }
  
  String _getAssetPattern() {
    if (Platform.isWindows) {
      return 'windows-64.zip';
    } else if (Platform.isAndroid) {
      return 'android-arm64-v8a.zip';
    }
    return '';
  }
  
  Future<void> _extractZip(String zipPath, String targetDir) async {
    try {
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
      
      _log('Successfully extracted ${archive.length} files');
    } catch (e) {
      _log('Failed to extract ZIP: $e');
      throw Exception('Failed to extract ZIP: $e');
    }
  }

  Future<void> startCore(VpnConfig config, {bool useTun = false}) async {
    try {
      _log('Starting Xray...');
      
      // На Android принудительно используем TUN
      if (Platform.isAndroid) {
        useTun = true;
        _log('[ANDROID] Forcing TUN mode');
      }
      
      // Если TUN режим - используем TunManager
      if (useTun) {
        _log('[TUN] Starting in TUN mode');
        
        // Создаём временный конфиг файл
        final tempDir = await getTemporaryDirectory();
        final configFile = File('${tempDir.path}/xray_tun_config.json');
        
        // Модифицируем конфиг для TUN
        final tunConfig = TunManager.instance.createXrayTunConfig(
          baseConfig: config.config,
        );
        
        await configFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(tunConfig),
        );
        
        // Запускаем через TunManager
        final success = await TunManager.instance.enableTun(
          coreType: CoreType.xray,
          configPath: configFile.path,
        );
        
        if (!success) {
          throw Exception('Failed to start TUN mode');
        }
        
        _log('[TUN] ✓ TUN mode started');
      } else {
        // Proxy режим - запускаем через XrayService
        await XrayService.instance.start(config);
        
        // Включаем системный прокси
        final port = 10808; // SOCKS порт
        final proxyEnabled = await SystemProxy.instance.enableProxy('127.0.0.1', port);
        if (proxyEnabled) {
          _log('✓ System proxy enabled: 127.0.0.1:$port');
        } else {
          _log('⚠ Failed to enable system proxy');
        }
      }
      
      // Start traffic statistics
      TrafficStats.instance.startSession();
      
      _log('✓ Xray started successfully');
    } catch (e) {
      _log('Failed to start Xray: $e');
      rethrow;
    }
  }

  Future<void> stopCore() async {
    _log('Stopping Xray...');
    
    // Останавливаем TUN если активен
    if (TunManager.instance.isTunEnabled) {
      await TunManager.instance.disableTun();
      _log('[TUN] ✓ TUN mode disabled');
    }
    
    // Останавливаем XrayService
    await XrayService.instance.stop();
    
    // Отключаем системный прокси
    await SystemProxy.instance.disableProxy();
    
    // Останавливаем статистику
    TrafficStats.instance.stopSession();
    
    _log('✓ Xray stopped');
  }

  bool get isRunning => XrayService.instance.isRunning || TunManager.instance.isTunEnabled;
  VpnConfig? get activeConfig => XrayService.instance.activeConfig;
  Directory get coreDirectory => _coreDir;

  void _log(String message) {
    print('[CoreManager] $message');
    _logController.add(message);
  }

  void dispose() {
    _logController.close();
    XrayService.instance.dispose();
  }
}
