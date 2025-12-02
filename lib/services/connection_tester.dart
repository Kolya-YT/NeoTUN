import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ConnectionTester {
  static final ConnectionTester instance = ConnectionTester._();
  ConnectionTester._();

  /// Тест пинга до указанного хоста
  Future<int> testPing(String host, {int timeout = 5}) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Пытаемся подключиться к хосту
      final socket = await Socket.connect(
        host,
        80,
        timeout: Duration(seconds: timeout),
      );
      
      stopwatch.stop();
      socket.destroy();
      
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      print('Ping test failed: $e');
      return -1; // Ошибка
    }
  }

  /// Тест HTTP соединения
  Future<int> testHttpConnection(String url, {int timeout = 10}) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(Duration(seconds: timeout));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      } else {
        return -1;
      }
    } catch (e) {
      print('HTTP test failed: $e');
      return -1;
    }
  }

  /// Тест скорости загрузки
  Future<double> testDownloadSpeed({
    String testUrl = 'http://speedtest.tele2.net/1MB.zip',
    int timeout = 30,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(testUrl),
      ).timeout(Duration(seconds: timeout));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final speedBytesPerSecond = bytes / seconds;
        
        // Возвращаем скорость в Mbps
        return (speedBytesPerSecond * 8) / (1024 * 1024);
      }
      
      return -1;
    } catch (e) {
      print('Download speed test failed: $e');
      return -1;
    }
  }

  /// Комплексный тест соединения
  Future<ConnectionTestResult> testConnection({
    String? customHost,
    bool testSpeed = false,
  }) async {
    final result = ConnectionTestResult();
    
    // Тест пинга к популярным серверам
    final hosts = customHost != null 
        ? [customHost]
        : ['8.8.8.8', 'google.com', 'cloudflare.com'];
    
    int totalPing = 0;
    int successfulPings = 0;
    
    for (final host in hosts) {
      final ping = await testPing(host);
      if (ping > 0) {
        totalPing += ping;
        successfulPings++;
      }
    }
    
    if (successfulPings > 0) {
      result.averagePing = totalPing ~/ successfulPings;
      result.isConnected = true;
    } else {
      result.isConnected = false;
      result.averagePing = -1;
    }
    
    // Тест HTTP соединения
    result.httpLatency = await testHttpConnection('http://www.google.com');
    
    // Тест скорости (опционально, занимает время)
    if (testSpeed && result.isConnected) {
      result.downloadSpeed = await testDownloadSpeed();
    }
    
    return result;
  }

  /// Быстрый тест доступности
  Future<bool> quickTest() async {
    try {
      final result = await testPing('8.8.8.8', timeout: 3);
      return result > 0;
    } catch (e) {
      return false;
    }
  }
}

class ConnectionTestResult {
  bool isConnected = false;
  int averagePing = -1; // ms
  int httpLatency = -1; // ms
  double downloadSpeed = -1; // Mbps

  String get pingQuality {
    if (averagePing < 0) return 'N/A';
    if (averagePing < 50) return 'Excellent';
    if (averagePing < 100) return 'Good';
    if (averagePing < 200) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'Connected: $isConnected, Ping: ${averagePing}ms ($pingQuality), '
           'HTTP: ${httpLatency}ms, Speed: ${downloadSpeed.toStringAsFixed(2)} Mbps';
  }
}
