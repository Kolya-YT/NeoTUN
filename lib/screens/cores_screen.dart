import 'package:flutter/material.dart';
import 'dart:io';
import '../models/core_type.dart';
import '../services/core_manager.dart';
import '../services/xray_downloader.dart';
import '../services/libxray_downloader.dart';

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
    
    // Проверяем Xray-core
    final xrayInstalled = await XrayDownloader.instance.isInstalled();
    _installed[CoreType.xray] = xrayInstalled;
    
    if (xrayInstalled) {
      _versions[CoreType.xray] = await XrayDownloader.instance.getInstalledVersion();
    }
    
    // Для Android также проверяем libxray
    if (Platform.isAndroid) {
      final libxrayInstalled = await LibxrayDownloader.instance.isInstalled();
      // libxray проверка убрана - устанавливается автоматически через AAR
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
                    'Manage Xray-core - automatic download and updates',
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
                            onPressed: _loading ? null : () => _checkCoreUpdate(core),
                            icon: const Icon(Icons.update),
                            label: const Text('Check Update'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : () => _reinstallCore(core),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reinstall'),
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
      final releaseInfo = await XrayDownloader.instance.getLatestReleaseInfo();
      
      if (releaseInfo != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Latest Xray-core Release'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Version: ${releaseInfo['version']}'),
                  const SizedBox(height: 8),
                  Text('Published: ${releaseInfo['published_at']}'),
                  const SizedBox(height: 16),
                  const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(releaseInfo['body'] ?? 'No release notes available'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
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
      // Используем новый XrayDownloader
      final success = await XrayDownloader.instance.download(
        onProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress[core] = received / total;
            });
          }
        },
      );
      
      if (success) {
        await _checkCores();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${core.displayName} installed successfully')),
          );
        }
      } else {
        throw Exception('Download failed');
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

  Future<void> _checkCoreUpdate(CoreType core) async {
    setState(() => _loading = true);
    
    try {
      final newVersion = await XrayDownloader.instance.checkForUpdate();
      
      if (newVersion != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Available'),
              content: Text('New version available: $newVersion\n\nDo you want to update?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Update'),
                ),
              ],
            ),
          );
          
          if (result == true) {
            await _reinstallCore(core);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have the latest version')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking update: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reinstallCore(CoreType core) async {
    await _installCore(core);
  }
}
