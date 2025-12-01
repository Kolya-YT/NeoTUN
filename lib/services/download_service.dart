import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DownloadService {
  static final DownloadService instance = DownloadService._();
  DownloadService._();

  Future<File> downloadFile(String url, String targetPath, {
    Function(int received, int total)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to download: ${response.statusCode}');
    }

    final file = File(targetPath);
    final sink = file.openWrite();
    
    int received = 0;
    final total = response.contentLength ?? 0;

    await for (var chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }

    await sink.close();
    return file;
  }

  Future<bool> verifyChecksum(File file, String expectedSha256) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString();
    return actualHash.toLowerCase() == expectedSha256.toLowerCase();
  }

  Future<File> downloadAndVerify(
    String url,
    String targetPath,
    String expectedSha256, {
    Function(int received, int total)? onProgress,
  }) async {
    final file = await downloadFile(url, targetPath, onProgress: onProgress);
    
    final isValid = await verifyChecksum(file, expectedSha256);
    if (!isValid) {
      await file.delete();
      throw Exception('Checksum verification failed');
    }

    return file;
  }
}
