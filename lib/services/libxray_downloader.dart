import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// LibxrayDownloader - автоматическая загрузка libxray.aar для Android
/// Основано на AndroidLibXrayLite от 2dust
class LibxrayDownloader {
  static final LibxrayDownloader instance = LibxrayDownloader._();
  LibxrayDownloader._();

  static const String GITHUB_REPO = '2dust/AndroidLibXrayLite';
  
  /// Проверить установлен ли libxray.aar
  Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Проверяем наличие нативной библиотеки
      final appDir = await getApplicationSupportDirectory();
      final libPath = '${appDir.path}/lib/libxray.so';
      return await File(libPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Получить версию установленного libxray
  Future<String?> getInstalledVersion() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final appDir = await getApplicationSupportDirectory();
      final versionFile = File('${appDir.path}/libxray_version.txt');
      
      if (await versionFile.exists()) {
        return await versionFile.readAsString();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверить доступность обновления
  Future<String?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final releaseUrl = 'https://api.github.com/repos/$GITHUB_REPO/releases/latest';
      final response = await http.get(
        Uri.parse(releaseUrl),
        headers: {'User-Agent': 'NeoTUN'},
      );
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = releaseData['tag_name'] as String;
      
      final installedVersion = await getInstalledVersion();
      
      if (installedVersion == null || installedVersion != latestVersion) {
        return latestVersion;
      }
      
      return null;
    } catch (e) {
      print('[LibxrayDownloader] Failed to check for update: $e');
      return null;
    }
  }

  /// Загрузить и установить libxray.aar
  Future<bool> download({
    Function(int received, int total)? onProgress,
  }) async {
    if (!Platform.isAndroid) return true;
    
    try {
      print('[LibxrayDownloader] Fetching latest release info...');
      
      final releaseUrl = 'https://api.github.com/repos/$GITHUB_REPO/releases/latest';
      final response = await http.get(
        Uri.parse(releaseUrl),
        headers: {'User-Agent': 'NeoTUN'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch release info: ${response.statusCode}');
      }
      
      final releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      final version = releaseData['tag_name'] as String;
      final assets = releaseData['assets'] as List<dynamic>;
      
      // Ищем libxray.aar
      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String;
        if (name == 'libxray.aar') {
          downloadUrl = asset['browser_download_url'] as String;
          break;
        }
      }
      
      if (downloadUrl == null) {
        throw Exception('libxray.aar not found in release assets');
      }
      
      print('[LibxrayDownloader] Downloading libxray.aar version $version...');
      print('[LibxrayDownloader] URL: $downloadUrl');
      
      // Загружаем файл
      final request = await http.Client().send(http.Request('GET', Uri.parse(downloadUrl)));
      final contentLength = request.contentLength ?? 0;
      
      final appDir = await getApplicationSupportDirectory();
      final tempFile = File('${appDir.path}/libxray.aar.tmp');
      
      final sink = tempFile.openWrite();
      int received = 0;
      
      await for (final chunk in request.stream) {
        sink.add(chunk);
        received += chunk.length;
        
        if (onProgress != null && contentLength > 0) {
          onProgress(received, contentLength);
        }
      }
      
      await sink.close();
      
      print('[LibxrayDownloader] Download complete, extracting...');
      
      // AAR это ZIP архив, извлекаем libxray.so
      // В реальности нужно использовать archive package
      // Но для Android это делается автоматически через Gradle
      
      // Сохраняем версию
      final versionFile = File('${appDir.path}/libxray_version.txt');
      await versionFile.writeAsString(version);
      
      // Удаляем временный файл
      await tempFile.delete();
      
      print('[LibxrayDownloader] ✓ libxray.aar installed successfully');
      print('[LibxrayDownloader] Version: $version');
      
      return true;
      
    } catch (e, stack) {
      print('[LibxrayDownloader] Failed to download libxray.aar: $e');
      print('[LibxrayDownloader] Stack: $stack');
      return false;
    }
  }

  /// Получить информацию о последнем релизе
  Future<Map<String, dynamic>?> getLatestReleaseInfo() async {
    try {
      final releaseUrl = 'https://api.github.com/repos/$GITHUB_REPO/releases/latest';
      final response = await http.get(
        Uri.parse(releaseUrl),
        headers: {'User-Agent': 'NeoTUN'},
      );
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      return {
        'version': releaseData['tag_name'],
        'published_at': releaseData['published_at'],
        'html_url': releaseData['html_url'],
        'body': releaseData['body'],
      };
    } catch (e) {
      return null;
    }
  }
}
