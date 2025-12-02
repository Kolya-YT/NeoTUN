import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/core_type.dart';
import 'download_service.dart';

class CoresUpdater {
  static final CoresUpdater instance = CoresUpdater._();
  CoresUpdater._();

  // Реальные URL для скачивания ядер
  static const xrayReleaseUrl = 'https://api.github.com/repos/XTLS/Xray-core/releases/latest';
  static const singboxReleaseUrl = 'https://api.github.com/repos/SagerNet/sing-box/releases/latest';
  static const hysteria2ReleaseUrl = 'https://api.github.com/repos/apernet/hysteria/releases/latest';

  Future<Map<String, dynamic>?> getLatestRelease(CoreType coreType) async {
    // Only Xray now
    final url = xrayReleaseUrl;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(
          Uri.splitQueryString(response.body)
        );
      }
    } catch (e) {
      print('Error fetching release info: $e');
    }
    return null;
  }

  String? getDownloadUrl(Map<String, dynamic> release, CoreType coreType) {
    final assets = release['assets'] as List?;
    if (assets == null) return null;

    String pattern;
    if (Platform.isWindows) {
      pattern = 'windows-64.zip';
    } else if (Platform.isAndroid) {
      pattern = 'android-arm64-v8a.zip';
    } else {
      return null;
    }

    for (final asset in assets) {
      final name = asset['name'] as String?;
      if (name != null && name.contains(pattern)) {
        return asset['browser_download_url'] as String?;
      }
    }

    return null;
  }

  Future<void> downloadAndInstallCore(
    CoreType coreType,
    String downloadUrl,
    String targetPath, {
    Function(int received, int total)? onProgress,
  }) async {
    final tempPath = '$targetPath.tmp';
    
    // Скачиваем файл
    await DownloadService.instance.downloadFile(
      downloadUrl,
      tempPath,
      onProgress: onProgress,
    );

    // Если это zip, нужно распаковать
    if (downloadUrl.endsWith('.zip')) {
      // TODO: Добавить распаковку zip
      // Для простоты пока просто переименуем
      await File(tempPath).rename(targetPath);
    } else {
      await File(tempPath).rename(targetPath);
    }

    // Установить права на выполнение для Unix
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', targetPath]);
    }
  }
}
