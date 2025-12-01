import 'dart:convert';
import 'core_type.dart';

class VpnConfig {
  final String id;
  final String name;
  final CoreType coreType;
  final Map<String, dynamic> config;
  final bool isActive;

  VpnConfig({
    required this.id,
    required this.name,
    required this.coreType,
    required this.config,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coreType': coreType.name,
        'config': config,
        'isActive': isActive,
      };

  factory VpnConfig.fromJson(Map<String, dynamic> json) => VpnConfig(
        id: json['id'],
        name: json['name'],
        coreType: CoreType.values.firstWhere((e) => e.name == json['coreType']),
        config: json['config'],
        isActive: json['isActive'] ?? false,
      );

  String toJsonString() => jsonEncode(toJson());

  factory VpnConfig.fromJsonString(String str) =>
      VpnConfig.fromJson(jsonDecode(str));
}
