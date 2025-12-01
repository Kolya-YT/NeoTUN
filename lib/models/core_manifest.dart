import 'dart:convert';

class CoreManifest {
  final Map<String, PlatformCores> platforms;

  CoreManifest({required this.platforms});

  factory CoreManifest.fromJson(Map<String, dynamic> json) {
    final platforms = <String, PlatformCores>{};
    final platformsJson = json['platforms'] as Map<String, dynamic>;
    
    platformsJson.forEach((key, value) {
      platforms[key] = PlatformCores.fromJson(value as Map<String, dynamic>);
    });
    
    return CoreManifest(platforms: platforms);
  }

  factory CoreManifest.fromJsonString(String str) =>
      CoreManifest.fromJson(jsonDecode(str));

  Map<String, dynamic> toJson() => {
        'platforms': platforms.map((key, value) => MapEntry(key, value.toJson())),
      };

  String toJsonString() => jsonEncode(toJson());
}

class PlatformCores {
  final CoreInfo? xray;
  final CoreInfo? singbox;
  final CoreInfo? hysteria2;

  PlatformCores({this.xray, this.singbox, this.hysteria2});

  factory PlatformCores.fromJson(Map<String, dynamic> json) {
    return PlatformCores(
      xray: json['xray'] != null ? CoreInfo.fromJson(json['xray']) : null,
      singbox: json['sing-box'] != null ? CoreInfo.fromJson(json['sing-box']) : null,
      hysteria2: json['hysteria2'] != null ? CoreInfo.fromJson(json['hysteria2']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (xray != null) 'xray': xray!.toJson(),
        if (singbox != null) 'sing-box': singbox!.toJson(),
        if (hysteria2 != null) 'hysteria2': hysteria2!.toJson(),
      };

  CoreInfo? getCoreInfo(String coreType) {
    switch (coreType) {
      case 'xray':
        return xray;
      case 'singbox':
        return singbox;
      case 'hysteria2':
        return hysteria2;
      default:
        return null;
    }
  }
}

class CoreInfo {
  final String version;
  final String url;
  final String sha256;
  final String? signature;

  CoreInfo({
    required this.version,
    required this.url,
    required this.sha256,
    this.signature,
  });

  factory CoreInfo.fromJson(Map<String, dynamic> json) {
    return CoreInfo(
      version: json['version'] as String,
      url: json['url'] as String,
      sha256: json['sha256'] as String,
      signature: json['signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'url': url,
        'sha256': sha256,
        if (signature != null) 'signature': signature,
      };
}
