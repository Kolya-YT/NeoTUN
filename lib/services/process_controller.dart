import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class ProcessController {
  static final ProcessController instance = ProcessController._();
  ProcessController._();

  static const platform = MethodChannel('com.neotun.app/vpn');

  Process? _process;
  final _logController = StreamController<String>.broadcast();
  final _statusController = StreamController<ProcessStatus>.broadcast();
  
  Stream<String> get logStream => _logController.stream;
  Stream<ProcessStatus> get statusStream => _statusController.stream;
  
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<void> startProcess({
    required String corePath,
    required String configPath,
    required List<String> args,
  }) async {
    if (_isRunning) {
      await stopProcess();
    }

    try {
      if (Platform.isAndroid) {
        await _startAndroidProcess(corePath, configPath, args);
      } else {
        await _startDesktopProcess(corePath, configPath, args);
      }
      
      _isRunning = true;
      _statusController.add(ProcessStatus.running);
      _logController.add('[INFO] Process started successfully');
    } catch (e) {
      _statusController.add(ProcessStatus.error);
      _logController.add('[ERROR] Failed to start process: $e');
      rethrow;
    }
  }

  Future<void> _startAndroidProcess(
    String corePath,
    String configPath,
    List<String> args,
  ) async {
    try {
      final result = await platform.invokeMethod('startCore', {
        'corePath': corePath,
        'configPath': configPath,
        'args': args,
      });
      
      if (result != true) {
        throw Exception('Failed to start Android VPN service');
      }
    } on PlatformException catch (e) {
      throw Exception('Android platform error: ${e.message}');
    }
  }

  Future<void> _startDesktopProcess(
    String corePath,
    String configPath,
    List<String> args,
  ) async {
    final allArgs = [...args, configPath];
    
    _process = await Process.start(
      corePath,
      allArgs,
      runInShell: Platform.isWindows,
    );

    // Monitor stdout
    _process!.stdout.transform(utf8.decoder).listen(
      (data) {
        _logController.add('[STDOUT] $data');
      },
      onError: (error) {
        _logController.add('[ERROR] stdout error: $error');
      },
    );

    // Monitor stderr
    _process!.stderr.transform(utf8.decoder).listen(
      (data) {
        _logController.add('[STDERR] $data');
      },
      onError: (error) {
        _logController.add('[ERROR] stderr error: $error');
      },
    );

    // Monitor exit
    _process!.exitCode.then((code) {
      _logController.add('[EXIT] Process exited with code $code');
      _isRunning = false;
      _statusController.add(ProcessStatus.stopped);
      _process = null;
    });
  }

  Future<void> stopProcess() async {
    if (!_isRunning) return;

    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('stopCore');
      } else {
        _process?.kill(ProcessSignal.sigterm);
        await Future.delayed(const Duration(seconds: 2));
        if (_process != null) {
          _process?.kill(ProcessSignal.sigkill);
        }
      }
      
      _isRunning = false;
      _statusController.add(ProcessStatus.stopped);
      _logController.add('[INFO] Process stopped');
    } catch (e) {
      _logController.add('[ERROR] Failed to stop process: $e');
      rethrow;
    }
  }

  Future<bool> checkStatus() async {
    if (Platform.isAndroid) {
      try {
        final result = await platform.invokeMethod('isRunning');
        _isRunning = result == true;
        if (_isRunning) {
          _statusController.add(ProcessStatus.running);
        } else {
          _statusController.add(ProcessStatus.stopped);
        }
        return _isRunning;
      } catch (e) {
        return false;
      }
    }
    return _isRunning;
  }

  Future<bool> healthCheck(String corePath) async {
    try {
      final result = await Process.run(
        corePath,
        ['version'],
        runInShell: Platform.isWindows,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _logController.close();
    _statusController.close();
  }
}

enum ProcessStatus {
  stopped,
  starting,
  running,
  stopping,
  error,
}
