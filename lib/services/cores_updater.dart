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
    String url;
    switch (coreType) {
      case CoreType.xray:
        url = xrayReleaseUrl;
        break;
      case CoreType.singbox:
        url = singboxReleaseUrl;
        break;
      case CoreType.hysteria2:
        url = hysteria2ReleaseUrl;
        break;
    }

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
      switch (coreType) {
        case CoreType.xray:
          pattern = 'windows-64.zip';
          break;
        case CoreType.singbox:
          pattern = 'windows-amd64.zip';
          break;
        case CoreType.hysteria2:
          pattern = 'windows-amd64.exe';
          break;
      }
    } else if (Platform.isAndroid) {
      switch (coreType) {
        case CoreType.xray:
          pattern = 'android-arm64-v8a.zip';
          break;
        case CoreType.singbox:
          pattern = 'android-arm64.zip';
          break;
        case CoreType.hysteria2:
          pattern = 'android-arm64';
          break;
      }
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
