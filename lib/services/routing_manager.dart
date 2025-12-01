import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RoutingManager {
  static final RoutingManager instance = RoutingManager._();
  RoutingManager._();

  late Directory _rulesDir;
  final Map<String, RoutingRule> _rules = {};

  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _rulesDir = Directory('${appDir.path}/neotun/routing');
    if (!await _rulesDir.exists()) {
      await _rulesDir.create(recursive: true);
    }
    await _loadDefaultRules();
  }

  Future<void> _loadDefaultRules() async {
    // Default routing rules
    _rules['direct'] = RoutingRule(
      id: 'direct',
      name: 'Direct',
      type: RuleType.direct,
      domains: ['localhost', 'lan'],
      ips: ['127.0.0.0/8', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'],
    );

    _rules['proxy'] = RoutingRule(
      id: 'proxy',
      name: 'Proxy',
      type: RuleType.proxy,
      domains: [],
      ips: [],
    );

    _rules['block'] = RoutingRule(
      id: 'block',
      name: 'Block Ads',
      type: RuleType.block,
      domains: ['ads', 'analytics', 'tracker'],
      ips: [],
    );
  }

  Map<String, dynamic> generateXrayRouting(List<String> ruleIds) {
    final rules = <Map<String, dynamic>>[];
    
    for (final id in ruleIds) {
      final rule = _rules[id];
      if (rule == null) continue;

      final ruleConfig = <String, dynamic>{};
      
      if (rule.domains.isNotEmpty) {
        ruleConfig['domain'] = rule.domains;
      }
      
      if (rule.ips.isNotEmpty) {
        ruleConfig['ip'] = rule.ips;
      }

      switch (rule.type) {
        case RuleType.direct:
          ruleConfig['outboundTag'] = 'direct';
          break;
        case RuleType.proxy:
          ruleConfig['outboundTag'] = 'proxy';
          break;
        case RuleType.block:
          ruleConfig['outboundTag'] = 'block';
          break;
      }

      rules.add(ruleConfig);
    }

    return {
      'domainStrategy': 'IPIfNonMatch',
      'rules': rules,
    };
  }

  Map<String, dynamic> generateSingboxRouting(List<String> ruleIds) {
    final rules = <Map<String, dynamic>>[];
    
    for (final id in ruleIds) {
      final rule = _rules[id];
      if (rule == null) continue;

      final ruleConfig = <String, dynamic>{};
      
      if (rule.domains.isNotEmpty) {
        ruleConfig['domain'] = rule.domains;
      }
      
      if (rule.ips.isNotEmpty) {
        ruleConfig['ip_cidr'] = rule.ips;
      }

      switch (rule.type) {
        case RuleType.direct:
          ruleConfig['outbound'] = 'direct';
          break;
        case RuleType.proxy:
          ruleConfig['outbound'] = 'proxy';
          break;
        case RuleType.block:
          ruleConfig['outbound'] = 'block';
          break;
      }

      rules.add(ruleConfig);
    }

    return {
      'rules': rules,
      'final': 'proxy',
    };
  }

  List<RoutingRule> getRules() => _rules.values.toList();
  
  void addRule(RoutingRule rule) {
    _rules[rule.id] = rule;
  }

  void removeRule(String id) {
    _rules.remove(id);
  }
}

class RoutingRule {
  final String id;
  final String name;
  final RuleType type;
  final List<String> domains;
  final List<String> ips;

  RoutingRule({
    required this.id,
    required this.name,
    required this.type,
    required this.domains,
    required this.ips,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'domains': domains,
        'ips': ips,
      };

  factory RoutingRule.fromJson(Map<String, dynamic> json) => RoutingRule(
        id: json['id'],
        name: json['name'],
        type: RuleType.values.firstWhere((e) => e.name == json['type']),
        domains: List<String>.from(json['domains']),
        ips: List<String>.from(json['ips']),
      );
}

enum RuleType {
  direct,
  proxy,
  block,
}
