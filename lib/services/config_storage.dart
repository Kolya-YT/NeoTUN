import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_config.dart';

class ConfigStorage {
  static final ConfigStorage instance = ConfigStorage._();
  ConfigStorage._();

  late Directory _configDir;
  final List<VpnConfig> _configs = [];

  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _configDir = Directory('${appDir.path}/neotun/configs');
      if (!await _configDir.exists()) {
        await _configDir.create(recursive: true);
      }
      await _loadConfigs();
    } catch (e) {
      print('ConfigStorage init error: $e');
      // Fallback to temp directory
      final tempDir = Directory.systemTemp;
      _configDir = Directory('${tempDir.path}/neotun/configs');
      if (!await _configDir.exists()) {
        await _configDir.create(recursive: true);
      }
    }
  }

  Future<void> _loadConfigs() async {
    _configs.clear();
    final files = _configDir.listSync().whereType<File>();
    for (final file in files) {
      if (file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          _configs.add(VpnConfig.fromJsonString(content));
        } catch (e) {
          print('Error loading config ${file.path}: $e');
        }
      }
    }
  }

  List<VpnConfig> getConfigs() => List.unmodifiable(_configs);

  Future<void> saveConfig(VpnConfig config) async {
    final file = File('${_configDir.path}/${config.id}.json');
    await file.writeAsString(config.toJsonString());
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      _configs[index] = config;
    } else {
      _configs.add(config);
    }
  }

  Future<void> deleteConfig(String id) async {
    final file = File('${_configDir.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
    _configs.removeWhere((c) => c.id == id);
  }

  Future<String> exportConfig(String id) async {
    final config = _configs.firstWhere((c) => c.id == id);
    return config.toJsonString();
  }

  Future<VpnConfig> importConfig(String jsonString) async {
    final config = VpnConfig.fromJsonString(jsonString);
    await saveConfig(config);
    return config;
  }
}
