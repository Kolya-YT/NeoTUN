import 'package:flutter/material.dart';
import '../models/core_type.dart';
import '../services/core_manager.dart';

class CoresScreen extends StatefulWidget {
  const CoresScreen({super.key});

  @override
  State<CoresScreen> createState() => _CoresScreenState();
}

class _CoresScreenState extends State<CoresScreen> {
  final Map<CoreType, bool> _installed = {};
  final Map<CoreType, String?> _versions = {};
  final Map<CoreType, double> _downloadProgress = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkCores();
  }

  Future<void> _checkCores() async {
    setState(() => _loading = true);
    for (final core in CoreType.values) {
      _installed[core] = await CoreManager.instance.isCoreInstalled(core);
      if (_installed[core] == true) {
        _versions[core] = await CoreManager.instance.getCoreVersion(core);
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _checkCores,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Core Manager',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage proxy cores: Xray, sing-box, and Hysteria2',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _checkForUpdates,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check for Updates'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...CoreType.values.map((core) {
            final installed = _installed[core] ?? false;
            final version = _versions[core];
            final progress = _downloadProgress[core];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCoreIcon(core),
                          size: 32,
                          color: installed ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                core.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (version != null)
                                Text(
                                  'Version: $version',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (installed)
                          Chip(
                            label: const Text('Installed'),
                            backgroundColor: Colors.green.shade100,
                          ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (installed) ...[
                          TextButton.icon(
                            onPressed: _loading ? null : () => _rollbackCore(core),
                            icon: const Icon(Icons.undo),
                            label: const Text('Rollback'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : () => _updateCore(core),
                            icon: const Icon(Icons.update),
                            label: const Text('Update'),
                          ),
                        ] else
                          ElevatedButton.icon(
                            onPressed: _loading ? null : () => _installCore(core),
                            icon: const Icon(Icons.download),
                            label: const Text('Install'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getCoreIcon(CoreType coreType) {
    return Icons.flight; // Xray icon
  }

  Future<void> _checkForUpdates() async {
    setState(() => _loading = true);
    try {
      // Manifest checking removed - only Xray now
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xray is the only core')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _installCore(CoreType core) async {
    setState(() {
      _loading = true;
      _downloadProgress[core] = 0.0;
    });
    
    try {
      await CoreManager.instance.downloadCore(
        core,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress[core] = received / total;
            });
          }
        },
      );
      
      await _checkCores();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${core.displayName} installed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation failed: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
        _downloadProgress.remove(core);
      });
    }
  }

  Future<void> _updateCore(CoreType core) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Core'),
        content: Text('Update ${core.displayName} to the latest version?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _downloadProgress[core] = 0.0;
    });
    
    try {
      await CoreManager.instance.downloadCore(
        core,
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress[core] = received / total;
            });
          }
        },
      );
      
      await _checkCores();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${core.displayName} updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
        _downloadProgress.remove(core);
      });
    }
  }

  Future<void> _rollbackCore(CoreType core) async {
    // Rollback functionality removed - simplified core management
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rollback not available in simplified version')),
      );
    }
  }
}
