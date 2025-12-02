import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'dart:convert';

/// XrayDownloader - автоматическая загрузка xray-core
/// Поддерживает Windows и Android
class XrayDownloader {
  static final XrayDownloader instance = XrayDownloader._();
  XrayDownloader._();

  static const String GITHUB_REPO = 'XTLS/Xray-core';
  
  /// Получить путь к xray исполняемому файлу
  Future<String> getXrayPath() async {
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

  /// Проверить установлен ли xray
  Future<bool> isInstalled() async {
    try {
      final xrayPath = await getXrayPath();
      return await File(xrayPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Получить версию установленного xray
  Future<String?> getInstalledVersion() async {
    try {
      final xrayPath = await getXrayPath();
      
      if (!await File(xrayPath).exists()) {
        return null;
      }

      final result = await Process.run(
        xrayPath,
        ['version'],
        runInShell: Platform.isWindows,
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final versionRegex = RegExp(r'Xray (\d+\.\d+\.\d+)');
        final match = versionRegex.firstMatch(output);
        return match?.group(1);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверить доступность обновления
  Future<String?> checkForUpdate() async {
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
      
      if (installedVersion == null || !latestVersion.contains(installedVersion)) {
        return latestVersion;
      }
      
      return null;
    } catch (e) {
      print('[XrayDownloader] Failed to check for update: $e');
      return null;
    }
  }

  /// Загрузить и установить xray-core
  Future<bool> download({
    Function(int received, int total)? onProgress,
  }) async {
    try {
      print('[XrayDownloader] Fetching latest release info...');
      
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
      
      // Определяем нужный asset
      final pattern = _getAssetPattern();
      String? downloadUrl;
      
      for (final asset in assets) {
        final name = asset['name'] as String;
        if (name.contains(pattern)) {
          downloadUrl = asset['browser_download_url'] as String;
          break;
        }
      }
      
      if (downloadUrl == null) {
        throw Exception('No suitable asset found for $pattern');
      }
      
      print('[XrayDownloader] Downloading Xray-core version $version...');
      print('[XrayDownloader] URL: $downloadUrl');
      
      // Создаём директорию cores
      final xrayPath = await getXrayPath();
      final coresDir = Directory(xrayPath).parent;
      if (!await coresDir.exists()) {
        await coresDir.create(recursive: true);
      }
      
      // Загружаем файл
      final request = await http.Client().send(http.Request('GET', Uri.parse(downloadUrl)));
      final contentLength = request.contentLength ?? 0;
      
      final tempFile = File('$xrayPath.zip');
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
      
      print('[XrayDownloader] Download complete, extracting...');
      
      // Извлекаем ZIP
      await _extractZip(tempFile.path, coresDir.path);
      
      // Удаляем временный файл
      await tempFile.delete();
      
      // Устанавливаем права на выполнение (Linux/Android)
      if (!Platform.isWindows) {
        await Process.run('chmod', ['755', xrayPath]);
      }
      
      print('[XrayDownloader] ✓ Xray-core installed successfully');
      print('[XrayDownloader] Version: $version');
      print('[XrayDownloader] Path: $xrayPath');
      
      // Проверяем установку
      final installedVersion = await getInstalledVersion();
      if (installedVersion != null) {
        print('[XrayDownloader] Verified version: $installedVersion');
        return true;
      } else {
        print('[XrayDownloader] Warning: Could not verify installation');
        return true; // Всё равно считаем успехом
      }
      
    } catch (e, stack) {
      print('[XrayDownloader] Failed to download Xray-core: $e');
      print('[XrayDownloader] Stack: $stack');
      return false;
    }
  }

  /// Определить паттерн для поиска нужного asset
  String _getAssetPattern() {
    if (Platform.isWindows) {
      return 'windows-64.zip';
    } else if (Platform.isAndroid) {
      return 'android-arm64-v8a.zip';
    }
    return '';
  }

  /// Извлечь ZIP архив
  Future<void> _extractZip(String zipPath, String targetDir) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final executableName = Platform.isWindows ? 'xray.exe' : 'xray';
      
      for (final file in archive) {
        final filename = file.name;
        
        // Ищем исполняемый файл xray
        if (filename.toLowerCase().endsWith(executableName.toLowerCase())) {
          final filePath = '$targetDir${Platform.pathSeparator}$executableName';
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          print('[XrayDownloader] Extracted: $filePath');
          return;
        }
      }
      
      // Если не нашли в корне, ищем в подпапках
      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name.split('/').last;
          if (filename.toLowerCase() == executableName.toLowerCase()) {
            final filePath = '$targetDir${Platform.pathSeparator}$executableName';
            final outFile = File(filePath);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            print('[XrayDownloader] Extracted: $filePath');
            return;
          }
        }
      }
      
      throw Exception('Executable $executableName not found in archive');
      
    } catch (e) {
      print('[XrayDownloader] Failed to extract ZIP: $e');
      rethrow;
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
