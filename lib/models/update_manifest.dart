import 'dart:convert';

class UpdateManifest {
  final String latestVersion;
  final String notes;
  final Map<String, PlatformUpdate> platforms;

  UpdateManifest({
    required this.latestVersion,
    required this.notes,
    required this.platforms,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final platformsMap = <String, PlatformUpdate>{};
    if (json['platforms'] != null) {
      (json['platforms'] as Map<String, dynamic>).forEach((key, value) {
        platformsMap[key] = PlatformUpdate.fromJson(value);
      });
    }

    return UpdateManifest(
      latestVersion: json['latest_version'] ?? json['latestVersion'] ?? '1.0.0',
      notes: json['notes'] ?? '',
      platforms: platformsMap,
    );
  }

  factory UpdateManifest.fromJsonString(String str) =>
      UpdateManifest.fromJson(jsonDecode(str));

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'notes': notes,
        'platforms': platforms.map((key, value) => MapEntry(key, value.toJson())),
      };

  String toJsonString() => jsonEncode(toJson());
}

class PlatformUpdate {
  final String url;
  final String sha256;

  PlatformUpdate({
    required this.url,
    required this.sha256,
  });

  factory PlatformUpdate.fromJson(Map<String, dynamic> json) {
    return PlatformUpdate(
      url: json['url'] as String,
      sha256: json['sha256'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'sha256': sha256,
      };
}
