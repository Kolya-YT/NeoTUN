import 'package:flutter/material.dart';
import '../services/config_storage.dart';
import '../services/core_manager.dart';
import '../models/vpn_config.dart';
import '../models/core_type.dart';
import 'config_editor_screen.dart';
import 'cores_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<_ConfigListTabState> _configListKey = GlobalKey();

  void _refreshConfigs() {
    _configListKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeoTUN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addConfig(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ConfigListTab(key: _configListKey),
          const CoresScreen(),
          SettingsScreen(
            onThemeChanged: widget.onThemeChanged,
            onConfigsChanged: _refreshConfigs,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Configs'),
          NavigationDestination(icon: Icon(Icons.settings_applications), label: 'Cores'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _addConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigEditorScreen()),
    ).then((_) => setState(() {}));
  }
}

class ConfigListTab extends StatefulWidget {
  const ConfigListTab({super.key});

  @override
  State<ConfigListTab> createState() => _ConfigListTabState();
}

class _ConfigListTabState extends State<ConfigListTab> with AutomaticKeepAliveClientMixin {
  final List<String> _logs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    CoreManager.instance.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 100) _logs.removeAt(0);
        });
      }
    });
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isRunning ? Colors.green.shade100 : Colors.grey.shade200,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isRunning ? Icons.check_circle : Icons.circle_outlined,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRunning ? 'Connected: ${activeConfig?.name}' : 'Disconnected',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isRunning)
                    ElevatedButton.icon(
                      onPressed: _stopCore,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              if (isRunning && _logs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: configs.isEmpty
              ? const Center(child: Text('No configs. Tap + to add.'))
              : ListView.builder(
                  itemCount: configs.length,
                  itemBuilder: (context, index) {
                    final config = configs[index];
                    final isActive = activeConfig?.id == config.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isActive ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          _getCoreIcon(config.coreType),
                          color: isActive ? Colors.green : null,
                        ),
                        title: Text(
                          config.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(config.coreType.displayName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () => _startConfig(config),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteConfig(config),
                            ),
                          ],
                        ),
                        onTap: () => _editConfig(config),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getCoreIcon(CoreType coreType) {
    switch (coreType) {
      case CoreType.xray:
        return Icons.flight;
      case CoreType.singbox:
        return Icons.inbox;
      case CoreType.hysteria2:
        return Icons.speed;
    }
  }

  Future<void> _startConfig(VpnConfig config) async {
    try {
      // Check if core is installed
      if (!await CoreManager.instance.isCoreInstalled(config.coreType)) {
        if (mounted) {
          final download = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Core Not Installed'),
              content: Text('${config.coreType.displayName} is not installed. Download now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Download'),
                ),
              ],
            ),
          );
          
          if (download == true && mounted) {
            // Переключаемся на вкладку Cores
            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
            homeState?.setState(() {
              homeState._selectedIndex = 1;
            });
            return;
          }
        }
        return;
      }

      await CoreManager.instance.startCore(config);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopCore() async {
    await CoreManager.instance.stopCore();
    setState(() {
      _logs.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected')),
      );
    }
  }

  Future<void> _deleteConfig(VpnConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Config'),
        content: Text('Delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ConfigStorage.instance.deleteConfig(config.id);
      setState(() {});
    }
  }

  void _editConfig(VpnConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigEditorScreen(config: config),
      ),
    ).then((_) => setState(() {}));
  }
}
