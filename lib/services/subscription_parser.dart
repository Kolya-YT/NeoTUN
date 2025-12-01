import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vpn_config.dart';
import '../models/core_type.dart';

class SubscriptionParser {
  static final SubscriptionParser instance = SubscriptionParser._();
  SubscriptionParser._();

  Future<List<VpnConfig>> parseSubscriptionUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = utf8.decode(base64.decode(response.body));
        return parseSubscriptionContent(content);
      }
    } catch (e) {
      print('Error fetching subscription: $e');
    }
    return [];
  }

  List<VpnConfig> parseSubscriptionContent(String content) {
    final configs = <VpnConfig>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.startsWith('vless://')) {
        final config = parseVlessUrl(trimmed);
        if (config != null) configs.add(config);
      } else if (trimmed.startsWith('vmess://')) {
        final config = parseVmessUrl(trimmed);
        if (config != null) configs.add(config);
      } else if (trimmed.startsWith('trojan://')) {
        final config = parseTrojanUrl(trimmed);
        if (config != null) configs.add(config);
      } else if (trimmed.startsWith('ss://')) {
        final config = parseShadowsocksUrl(trimmed);
        if (config != null) configs.add(config);
      }
    }
    
    return configs;
  }

  VpnConfig? parseVlessUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final uuid = uri.userInfo;
      final address = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      
      final name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '$address:$port');
      
      final config = {
        'outbounds': [
          {
            'protocol': 'vless',
            'settings': {
              'vnext': [
                {
                  'address': address,
                  'port': port,
                  'users': [
                    {
                      'id': uuid,
                      'encryption': params['encryption'] ?? 'none',
                      'flow': params['flow'] ?? '',
                    }
                  ]
                }
              ]
            },
            'streamSettings': {
              'network': params['type'] ?? 'tcp',
              'security': params['security'] ?? 'none',
              if (params['security'] == 'tls' || params['security'] == 'reality')
                'tlsSettings': {
                  'serverName': params['sni'] ?? address,
                  'allowInsecure': params['allowInsecure'] == '1',
                }
            }
          }
        ]
      };
      
      return VpnConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        coreType: CoreType.xray,
        config: config,
      );
    } catch (e) {
      print('Error parsing vless URL: $e');
      return null;
    }
  }

  VpnConfig? parseVmessUrl(String url) {
    try {
      final base64Str = url.substring('vmess://'.length);
      final jsonStr = utf8.decode(base64.decode(base64Str));
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final config = {
        'outbounds': [
          {
            'protocol': 'vmess',
            'settings': {
              'vnext': [
                {
                  'address': json['add'],
                  'port': int.parse(json['port'].toString()),
                  'users': [
                    {
                      'id': json['id'],
                      'alterId': int.parse(json['aid']?.toString() ?? '0'),
                      'security': json['scy'] ?? 'auto',
                    }
                  ]
                }
              ]
            },
            'streamSettings': {
              'network': json['net'] ?? 'tcp',
              'security': json['tls'] ?? 'none',
            }
          }
        ]
      };
      
      return VpnConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['ps'] ?? '${json['add']}:${json['port']}',
        coreType: CoreType.xray,
        config: config,
      );
    } catch (e) {
      print('Error parsing vmess URL: $e');
      return null;
    }
  }

  VpnConfig? parseTrojanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final password = uri.userInfo;
      final address = uri.host;
      final port = uri.port;
      final params = uri.queryParameters;
      
      final name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '$address:$port');
      
      final config = {
        'outbounds': [
          {
            'protocol': 'trojan',
            'settings': {
              'servers': [
                {
                  'address': address,
                  'port': port,
                  'password': password,
                }
              ]
            },
            'streamSettings': {
              'network': params['type'] ?? 'tcp',
              'security': 'tls',
              'tlsSettings': {
                'serverName': params['sni'] ?? address,
              }
            }
          }
        ]
      };
      
      return VpnConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        coreType: CoreType.xray,
        config: config,
      );
    } catch (e) {
      print('Error parsing trojan URL: $e');
      return null;
    }
  }

  VpnConfig? parseShadowsocksUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final userInfo = utf8.decode(base64.decode(uri.userInfo));
      final parts = userInfo.split(':');
      final method = parts[0];
      final password = parts[1];
      final address = uri.host;
      final port = uri.port;
      
      final name = Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '$address:$port');
      
      final config = {
        'outbounds': [
          {
            'protocol': 'shadowsocks',
            'settings': {
              'servers': [
                {
                  'address': address,
                  'port': port,
                  'method': method,
                  'password': password,
                }
              ]
            }
          }
        ]
      };
      
      return VpnConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        coreType: CoreType.xray,
        config: config,
      );
    } catch (e) {
      print('Error parsing shadowsocks URL: $e');
      return null;
    }
  }
}
