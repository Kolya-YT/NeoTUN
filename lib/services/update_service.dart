import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_manifest.dart';
import 'download_service.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  static const manifestUrl = 'https://raw.githubusercontent.com/Kolya-YT/NeoTUN/main/app_update.json';
  static const platform = MethodChannel('com.neotun.app/vpn');
  
  UpdateManifest? _latestManifest;

  Future<void> init() async {
    // Initialization if needed
  }

  Future<bool> get autoUpdateEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_update_enabled') ?? true;
  }

  Future<void> setAutoUpdate(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update_enabled', enabled);
  }

  Future<UpdateManifest?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(manifestUrl));
      if (response.statusCode == 200) {
        _latestManifest = UpdateManifest.fromJsonString(response.body);
        return _latestManifest;
      }
    } catch (e) {
      print('Error checking updates: $e');
    }
    return null;
  }

  Future<bool> needsAppUpdate() async {
    if (_latestManifest == null) {
      await checkForUpdates();
    }
    if (_latestManifest == null) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    return _compareVersions(_latestManifest!.latestVersion, packageInfo.version) > 0;
  }

  Future<String?> downloadAppUpdate({
    Function(int received, int total)? onProgress,
  }) async {
    if (_latestManifest == null) {
      await checkForUpdates();
    }
    if (_latestManifest == null) return null;

    final platform = _getPlatformKey();
    final platformUpdate = _latestManifest!.platforms[platform];
    if (platformUpdate == null) {
      throw Exception('No update available for platform $platform');
    }

    final tempDir = await getTemporaryDirectory();
    final ext = Platform.isWindows ? '.exe' : '.apk';
    final targetPath = '${tempDir.path}/neotun_update$ext';

    await DownloadService.instance.downloadAndVerify(
      platformUpdate.url,
      targetPath,
      platformUpdate.sha256,
      onProgress: onProgress,
    );

    return targetPath;
  }

  Future<void> installUpdate(String filePath) async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('installApk', {'filePath': filePath});
      } on PlatformException catch (e) {
        throw Exception('Failed to install APK: ${e.message}');
      }
    } else if (Platform.isWindows) {
      // On Windows, launch installer
      await Process.start(filePath, [], runInShell: true);
      exit(0);
    }
  }

  String _getPlatformKey() {
    if (Platform.isWindows) {
      return 'windows-x64';
    } else if (Platform.isAndroid) {
      // Определяем архитектуру Android
      // По умолчанию используем arm64 как самую распространенную
      return 'android-arm64';
    } else if (Platform.isLinux) {
      return 'linux-x64';
    } else if (Platform.isMacOS) {
      return 'macos-x64';
    }
    throw Exception('Unsupported platform');
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  UpdateManifest? get latestManifest => _latestManifest;
}
