import '../models/core_type.dart';

class ConfigTemplates {
  static Map<String, dynamic> getXrayTemplate({
    required String protocol,
    required String address,
    required int port,
    String? id,
    String? password,
    Map<String, dynamic>? extra,
  }) {
    return {
      "log": {
        "loglevel": "info"
      },
      "inbounds": [
        {
          "port": 10808,
          "protocol": "socks",
          "settings": {
            "auth": "noauth",
            "udp": true
          },
          "tag": "socks-in"
        },
        {
          "port": 10809,
          "protocol": "http",
          "tag": "http-in"
        }
      ],
      "outbounds": [
        {
          "protocol": protocol,
          "settings": _getXrayOutboundSettings(protocol, address, port, id, password, extra),
          "tag": "proxy"
        },
        {
          "protocol": "freedom",
          "tag": "direct"
        },
        {
          "protocol": "blackhole",
          "tag": "block"
        }
      ],
      "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
          {
            "type": "field",
            "ip": ["geoip:private"],
            "outboundTag": "direct"
          }
        ]
      }
    };
  }

  static Map<String, dynamic> _getXrayOutboundSettings(
    String protocol,
    String address,
    int port,
    String? id,
    String? password,
    Map<String, dynamic>? extra,
  ) {
    switch (protocol.toLowerCase()) {
      case 'vmess':
        return {
          "vnext": [
            {
              "address": address,
              "port": port,
              "users": [
                {
                  "id": id ?? "",
                  "alterId": extra?['alterId'] ?? 0,
                  "security": extra?['security'] ?? "auto"
                }
              ]
            }
          ]
        };
      
      case 'vless':
        return {
          "vnext": [
            {
              "address": address,
              "port": port,
              "users": [
                {
                  "id": id ?? "",
                  "encryption": extra?['encryption'] ?? "none",
                  "flow": extra?['flow'] ?? ""
                }
              ]
            }
          ]
        };
      
      case 'trojan':
        return {
          "servers": [
            {
              "address": address,
              "port": port,
              "password": password ?? "",
              "email": extra?['email'] ?? ""
            }
          ]
        };
      
      case 'shadowsocks':
        return {
          "servers": [
            {
              "address": address,
              "port": port,
              "method": extra?['method'] ?? "aes-256-gcm",
              "password": password ?? ""
            }
          ]
        };
      
      default:
        return {};
    }
  }

  static Map<String, dynamic> getSingboxTemplate({
    required String protocol,
    required String address,
    required int port,
    String? id,
    String? password,
    Map<String, dynamic>? extra,
  }) {
    return {
      "log": {
        "level": "info"
      },
      "inbounds": [
        {
          "type": "mixed",
          "tag": "mixed-in",
          "listen": "127.0.0.1",
          "listen_port": 10808
        }
      ],
      "outbounds": [
        {
          "type": protocol,
          "tag": "proxy",
          "server": address,
          "server_port": port,
          ..._getSingboxOutboundSettings(protocol, id, password, extra),
        },
        {
          "type": "direct",
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "rules": [
          {
            "ip_cidr": ["224.0.0.0/3", "ff00::/8"],
            "outbound": "block"
          },
          {
            "geoip": "private",
            "outbound": "direct"
          }
        ],
        "final": "proxy"
      }
    };
  }

  static Map<String, dynamic> _getSingboxOutboundSettings(
    String protocol,
    String? id,
    String? password,
    Map<String, dynamic>? extra,
  ) {
    switch (protocol.toLowerCase()) {
      case 'vmess':
        return {
          "uuid": id ?? "",
          "security": extra?['security'] ?? "auto",
          "alter_id": extra?['alterId'] ?? 0,
        };
      
      case 'vless':
        return {
          "uuid": id ?? "",
          "flow": extra?['flow'] ?? "",
        };
      
      case 'trojan':
        return {
          "password": password ?? "",
        };
      
      case 'shadowsocks':
        return {
          "method": extra?['method'] ?? "aes-256-gcm",
          "password": password ?? "",
        };
      
      default:
        return {};
    }
  }

  static Map<String, dynamic> getHysteria2Template({
    required String address,
    required int port,
    required String password,
    Map<String, dynamic>? extra,
  }) {
    return {
      "server": "$address:$port",
      "auth": password,
      "tls": {
        "sni": extra?['sni'] ?? address,
        "insecure": extra?['insecure'] ?? false,
      },
      "bandwidth": {
        "up": extra?['upMbps'] ?? "100 mbps",
        "down": extra?['downMbps'] ?? "100 mbps",
      },
      "socks5": {
        "listen": "127.0.0.1:10808"
      },
      "http": {
        "listen": "127.0.0.1:10809"
      }
    };
  }

  static Map<String, dynamic> getTemplateForCore(
    CoreType coreType, {
    required String protocol,
    required String address,
    required int port,
    String? id,
    String? password,
    Map<String, dynamic>? extra,
  }) {
    switch (coreType) {
      case CoreType.xray:
        return getXrayTemplate(
          protocol: protocol,
          address: address,
          port: port,
          id: id,
          password: password,
          extra: extra,
        );
      
      case CoreType.singbox:
        return getSingboxTemplate(
          protocol: protocol,
          address: address,
          port: port,
          id: id,
          password: password,
          extra: extra,
        );
      
      case CoreType.hysteria2:
        return getHysteria2Template(
          address: address,
          port: port,
          password: password ?? id ?? "",
          extra: extra,
        );
    }
  }
}
