import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'core_manager.dart';
import '../models/vpn_config.dart';

class AutoReconnect {
  static final AutoReconnect instance = AutoReconnect._();
  AutoReconnect._();

  Timer? _checkTimer;
  bool _isEnabled = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _checkInterval = Duration(seconds: 10);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('auto_reconnect') ?? false;
    
    if (_isEnabled) {
      startMonitoring();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_reconnect', enabled);
    
    if (enabled) {
      startMonitoring();
    } else {
      stopMonitoring();
    }
  }

  void startMonitoring() {
    stopMonitoring();
    
    _checkTimer = Timer.periodic(_checkInterval, (timer) {
      _checkConnection();
    });
    
    print('[AutoReconnect] Monitoring started');
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _reconnectAttempts = 0;
  }

  Future<void> _checkConnection() async {
    // Проверяем что VPN должен быть подключен
    final activeConfig = CoreManager.instance.activeConfig;
    if (activeConfig == null) {
      // VPN не должен быть подключен
      _reconnectAttempts = 0;
      return;
    }

    // Проверяем что VPN действительно работает
    final isRunning = CoreManager.instance.isRunning;
    if (!isRunning) {
      print('[AutoReconnect] Connection lost, attempting to reconnect...');
      await _attemptReconnect(activeConfig);
    } else {
      // Соединение активно, сбрасываем счетчик
      _reconnectAttempts = 0;
    }
  }

  Future<void> _attemptReconnect(VpnConfig config) async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[AutoReconnect] Max reconnect attempts reached, giving up');
      _reconnectAttempts = 0;
      return;
    }

    _reconnectAttempts++;
    print('[AutoReconnect] Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');

    try {
      // Ждем перед попыткой переподключения
      await Future.delayed(_reconnectDelay);
      
      // Пытаемся переподключиться
      await CoreManager.instance.startCore(config, useTun: true);
      
      print('[AutoReconnect] Reconnection successful');
      _reconnectAttempts = 0;
    } catch (e) {
      print('[AutoReconnect] Reconnection failed: $e');
      
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        print('[AutoReconnect] All reconnect attempts failed');
      }
    }
  }

  void dispose() {
    stopMonitoring();
  }
}
