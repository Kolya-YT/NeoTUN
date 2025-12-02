import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../services/config_storage.dart';
import '../services/core_manager.dart';
import '../services/process_controller.dart';
import '../services/connection_tester.dart';
import '../services/subscription_parser.dart';
import '../widgets/speed_indicator.dart';
import '../utils/error_handler.dart';

import '../models/vpn_config.dart';
import '../models/core_type.dart';
import 'config_editor_screen.dart';
import 'cores_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;
  
  const HomeScreen({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<_ConfigListTabState> _configListKey = GlobalKey();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Проверяем состояние VPN при запуске (для Android)
    _checkVpnStatus();
  }
  
  Future<void> _checkVpnStatus() async {
    try {
      await ProcessController.instance.checkStatus();
    } catch (e) {
      print('Failed to check VPN status: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _refreshConfigs() {
    _configListKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF6366F1), // Indigo
                      const Color(0xFF8B5CF6), // Purple
                    ]
                  : [
                      const Color(0xFF6366F1),
                      const Color(0xFFA855F7),
                    ],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.vpn_lock, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'NeoTUN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart, size: 20),
            ),
            onPressed: () => _openStats(),
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
            onSelected: (value) {
              if (value == 'manual') {
                _addConfig();
              } else if (value == 'clipboard') {
                _importFromClipboard();
              } else if (value == 'test_all') {
                _testAllConfigs();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.addConfig),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clipboard',
                child: Row(
                  children: [
                    const Icon(Icons.content_paste),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.importFromClipboard),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test_all',
                child: Row(
                  children: [
                    const Icon(Icons.speed),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.testAllConfigs),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ConfigListTab(
            key: _configListKey,
            pulseController: _pulseController,
          ),
          const CoresScreen(),
          SettingsScreen(
            onThemeChanged: widget.onThemeChanged,
            onLocaleChanged: widget.onLocaleChanged,
            onConfigsChanged: _refreshConfigs,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          height: 70,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: AppLocalizations.of(context)!.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.dns_outlined),
              selectedIcon: const Icon(Icons.dns),
              label: AppLocalizations.of(context)!.cores,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: AppLocalizations.of(context)!.settings,
            ),
          ],
        ),
      ),
    );
  }

  void _addConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigEditorScreen()),
    ).then((_) => setState(() {}));
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsScreen()),
    );
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text == null || text.isEmpty) {
        if (mounted) {
          ErrorHandler.showError(
            context,
            AppLocalizations.of(context)!.clipboardEmpty,
          );
        }
        return;
      }

      // Показываем диалог загрузки
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loading),
            ],
          ),
        ),
      );

      List<VpnConfig> importedConfigs = [];

      // Пробуем разные форматы
      try {
        // 1. Проверяем, это JSON конфигурация
        final jsonData = json.decode(text);
        if (jsonData is Map) {
          // Определяем тип ядра по структуре
          CoreType coreType = CoreType.xray;
          if (jsonData.containsKey('inbounds') && jsonData.containsKey('outbounds')) {
            if (jsonData['outbounds'] is List && 
                (jsonData['outbounds'] as List).any((o) => o['type'] != null)) {
              coreType = CoreType.singbox;
            }
          } else if (jsonData.containsKey('server') && jsonData.containsKey('auth')) {
            coreType = CoreType.hysteria2;
          }

          final config = VpnConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Imported ${DateTime.now().toString().substring(0, 19)}',
            coreType: coreType,
            config: jsonData as Map<String, dynamic>,
          );
          importedConfigs.add(config);
        }
      } catch (e) {
        // Не JSON, пробуем как subscription URL или share links
        final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
        
        for (final line in lines) {
          final trimmed = line.trim();
          
          // Проверяем различные форматы ссылок
          if (trimmed.startsWith('vless://') || 
              trimmed.startsWith('vmess://') ||
              trimmed.startsWith('trojan://') ||
              trimmed.startsWith('ss://') ||
              trimmed.startsWith('hysteria2://') ||
              trimmed.startsWith('hy2://')) {
            
            try {
              final parsed = await SubscriptionParser.parseShareUrl(trimmed);
              if (parsed != null) {
                importedConfigs.add(parsed);
              }
            } catch (e) {
              print('Failed to parse share URL: $e');
            }
          } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
            // Subscription URL
            try {
              final configs = await SubscriptionParser.fetchSubscription(trimmed);
              importedConfigs.addAll(configs);
            } catch (e) {
              print('Failed to fetch subscription: $e');
            }
          }
        }
      }

      if (mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
      }

      if (importedConfigs.isEmpty) {
        if (mounted) {
          ErrorHandler.showError(
            context,
            AppLocalizations.of(context)!.noValidConfigFound,
          );
        }
        return;
      }

      // Сохраняем конфигурации
      for (final config in importedConfigs) {
        await ConfigStorage.instance.saveConfig(config);
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.configImported}: ${importedConfigs.length}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог если открыт
        ErrorHandler.showError(
          context,
          '${AppLocalizations.of(context)!.error}: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    }
  }

  Future<void> _testAllConfigs() async {
    final configs = ConfigStorage.instance.getConfigs();
    if (configs.isEmpty) return;

    if (!mounted) return;
    
    // Показываем диалог с прогрессом
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.testAllConfigs),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.testingConfigs),
              ],
            ),
          );
        },
      ),
    );

    final results = <String, ConnectionTestResult>{};

    for (final config in configs) {
      try {
        // Запускаем конфигурацию
        await CoreManager.instance.startCore(config, useTun: false);
        await Future.delayed(const Duration(seconds: 2));

        // Тестируем
        final result = await ConnectionTester.instance.testConnection();
        results[config.id] = result;

        // Останавливаем
        await CoreManager.instance.stopCore();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Failed to test config ${config.name}: $e');
        final failedResult = ConnectionTestResult();
        failedResult.isConnected = false;
        failedResult.averagePing = -1;
        failedResult.httpLatency = -1;
        results[config.id] = failedResult;
      }
    }

    if (mounted) {
      Navigator.pop(context); // Закрываем диалог прогресса

      // Показываем результаты
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.testAllConfigs),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: configs.length,
              itemBuilder: (context, index) {
                final config = configs[index];
                final result = results[config.id];
                
                return ListTile(
                  leading: Icon(
                    result?.isConnected == true ? Icons.check_circle : Icons.error,
                    color: result?.isConnected == true ? Colors.green : Colors.red,
                  ),
                  title: Text(config.name),
                  subtitle: result != null
                      ? Text(
                          result.isConnected
                              ? '${AppLocalizations.of(context)!.ping}: ${result.averagePing}ms'
                              : AppLocalizations.of(context)!.testFailed,
                        )
                      : Text(AppLocalizations.of(context)!.error),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        ),
      );
    }
  }
}

class ConfigListTab extends StatefulWidget {
  final AnimationController pulseController;
  
  const ConfigListTab({
    super.key,
    required this.pulseController,
  });

  @override
  State<ConfigListTab> createState() => _ConfigListTabState();
}

class _ConfigListTabState extends State<ConfigListTab> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final List<String> _logs = [];
  late AnimationController _slideController;
  bool _useTunMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    CoreManager.instance.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 100) _logs.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final configs = ConfigStorage.instance.getConfigs();
    final isRunning = CoreManager.instance.isRunning;
    final activeConfig = CoreManager.instance.activeConfig;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Status Card with Gradient
        AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRunning
                      ? [
                          const Color(0xFF10B981), // Emerald
                          const Color(0xFF06B6D4), // Cyan
                        ]
                      : isDark
                          ? [
                              const Color(0xFF475569),
                              const Color(0xFF334155),
                            ]
                          : [
                              const Color(0xFF94A3B8),
                              const Color(0xFF64748B),
                            ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isRunning ? Colors.green : Colors.grey).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Animated background
                    if (isRunning)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WavePainter(
                            animation: widget.pulseController,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // TUN Mode Toggle (at top)
                          if (!isRunning)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _useTunMode ? Icons.vpn_lock : Icons.language,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _useTunMode ? AppLocalizations.of(context)!.tunMode : AppLocalizations.of(context)!.proxyMode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _useTunMode,
                                    onChanged: (value) {
                                      setState(() {
                                        _useTunMode = value;
                                      });
                                    },
                                    activeTrackColor: Colors.green.shade300,
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              // Status Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRunning ? Icons.check_circle : Icons.power_settings_new,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Status Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isRunning ? AppLocalizations.of(context)!.connected : AppLocalizations.of(context)!.disconnected,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isRunning && activeConfig != null) ...[
                                      Text(
                                        activeConfig.name,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      const SpeedIndicator(isCompact: true),
                                    ],
                                  ],
                                ),
                              ),
                              // Stop Button
                              if (isRunning)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _stopCore,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.stop_circle,
                                              color: Colors.red.shade400,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!.stop,
                                              style: TextStyle(
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Logs
                          if (isRunning && _logs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                itemCount: _logs.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  final log = _logs[_logs.length - 1 - index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        color: _getLogColor(log),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Configs List
        Expanded(
          child: configs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noConfigurations,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.tapToAddConfig,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: configs.length,
                    itemBuilder: (context, index) {
                      final config = configs[index];
                      final isActive = activeConfig?.id == config.id;
                      return _buildConfigCard(context, config, isActive, isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildConfigCard(BuildContext context, VpnConfig config, bool isActive, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
              )
            : null,
        color: isActive ? null : (isDark ? Colors.grey.shade800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.blue : Colors.grey).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () => _startConfig(config),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCoreIcon(config.coreType),
                    color: isActive ? Colors.white : Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              config.coreType.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.active,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive) ...[
                      IconButton(
                        icon: Icon(
                          Icons.speed,
                          color: Colors.orange.shade400,
                          size: 24,
                        ),
                        onPressed: () => _testConfig(config),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_filled,
                          color: Colors.green.shade400,
                          size: 32,
                        ),
                        onPressed: () => _startConfig(config),
                      ),
                    ],
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: isActive ? Colors.white : Colors.red.shade400,
                      ),
                      onPressed: () => _deleteConfig(config.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('[ERROR]') || log.contains('[STDERR]')) {
      return Colors.red.shade300;
    } else if (log.contains('[PROXY]') || log.contains('✓')) {
      return Colors.green.shade300;
    } else if (log.contains('[STDOUT]')) {
      return Colors.blue.shade300;
    }
    return Colors.white70;
  }

  IconData _getCoreIcon(CoreType coreType) {
    switch (coreType) {
      case CoreType.xray:
        return Icons.flash_on;
      case CoreType.singbox:
        return Icons.inbox;
      case CoreType.hysteria2:
        return Icons.speed;
    }
  }

  Future<void> _startConfig(VpnConfig config) async {
    try {
      await CoreManager.instance.startCore(config, useTun: _useTunMode);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopCore() async {
    await CoreManager.instance.stopCore();
    if (mounted) setState(() {});
  }

  Future<void> _deleteConfig(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfig),
        content: Text(AppLocalizations.of(context)!.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConfigStorage.instance.deleteConfig(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _testConfig(VpnConfig config) async {
    // Показываем диалог с прогрессом
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.testConnection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loading),
          ],
        ),
      ),
    );

    try {
      // Временно запускаем конфигурацию для теста
      await CoreManager.instance.startCore(config, useTun: _useTunMode);
      
      // Ждем инициализации
      await Future.delayed(const Duration(seconds: 2));
      
      // Тестируем соединение
      final result = await ConnectionTester.instance.testConnection();
      
      // Останавливаем
      await CoreManager.instance.stopCore();
      
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог прогресса
        
        // Показываем результаты
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.testConnection),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestResultRow(
                  Icons.wifi,
                  'Status',
                  result.isConnected ? 'Connected' : 'Failed',
                  result.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                _buildTestResultRow(
                  Icons.speed,
                  AppLocalizations.of(context)!.ping,
                  result.averagePing > 0 ? '${result.averagePing}ms' : 'N/A',
                  _getPingColor(result.averagePing),
                ),
                const SizedBox(height: 8),
                _buildTestResultRow(
                  Icons.http,
                  'HTTP Latency',
                  result.httpLatency > 0 ? '${result.httpLatency}ms' : 'N/A',
                  _getPingColor(result.httpLatency),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог прогресса
        ErrorHandler.showError(
          context,
          'Test failed: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    }
  }

  Widget _buildTestResultRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getPingColor(int ping) {
    if (ping < 0) return Colors.grey;
    if (ping < 100) return Colors.green;
    if (ping < 300) return Colors.orange;
    return Colors.red;
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 20.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height - waveHeight * math.sin((i / waveLength + animation.value * 2) * math.pi),
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
