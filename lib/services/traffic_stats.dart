import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TrafficStats {
  static final TrafficStats instance = TrafficStats._();
  TrafficStats._();

  int _uploadBytes = 0;
  int _downloadBytes = 0;
  int _totalUploadBytes = 0;
  int _totalDownloadBytes = 0;
  DateTime? _sessionStart;
  
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _totalUploadBytes = prefs.getInt('total_upload') ?? 0;
    _totalDownloadBytes = prefs.getInt('total_download') ?? 0;
  }

  void startSession() {
    _sessionStart = DateTime.now();
    _uploadBytes = 0;
    _downloadBytes = 0;
    _notifyListeners();
  }

  void stopSession() async {
    if (_sessionStart != null) {
      _totalUploadBytes += _uploadBytes;
      _totalDownloadBytes += _downloadBytes;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_upload', _totalUploadBytes);
      await prefs.setInt('total_download', _totalDownloadBytes);
      
      _sessionStart = null;
      _notifyListeners();
    }
  }

  void addUpload(int bytes) {
    _uploadBytes += bytes;
    _notifyListeners();
  }

  void addDownload(int bytes) {
    _downloadBytes += bytes;
    _notifyListeners();
  }

  Future<void> resetTotal() async {
    _totalUploadBytes = 0;
    _totalDownloadBytes = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_upload');
    await prefs.remove('total_download');
    _notifyListeners();
  }

  void _notifyListeners() {
    _statsController.add({
      'session_upload': _uploadBytes,
      'session_download': _downloadBytes,
      'total_upload': _totalUploadBytes,
      'total_download': _totalDownloadBytes,
      'session_duration': _sessionStart != null 
          ? DateTime.now().difference(_sessionStart!).inSeconds 
          : 0,
    });
  }

  Map<String, dynamic> get currentStats => {
    'session_upload': _uploadBytes,
    'session_download': _downloadBytes,
    'total_upload': _totalUploadBytes,
    'total_download': _totalDownloadBytes,
    'session_duration': _sessionStart != null 
        ? DateTime.now().difference(_sessionStart!).inSeconds 
        : 0,
  };

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  void dispose() {
    _statsController.close();
  }
}
