import 'package:flutter/material.dart';
import '../models/core_type.dart';
import '../services/xray_downloader.dart';
import '../l10n/app_localizations.dart';

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
    
    final xrayInstalled = await XrayDownloader.instance.isInstalled();
    _installed[CoreType.xray] = xrayInstalled;
    
    if (xrayInstalled) {
      _versions[CoreType.xray] = await XrayDownloader.instance.getInstalledVersion();
    }
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _checkCores,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.settings_system_daydream,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.coreManagement,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Xray-core ${l10n.autoUpdate.toLowerCase()}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _loading ? null : _checkForUpdates,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.checkUpdates),
                      ),
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
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: installed 
                                  ? Colors.green.withOpacity(0.1)
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.flight,
                              size: 28,
                              color: installed ? Colors.green : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  core.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (version != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.version}: $version',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (installed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.active,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.downloadingCore} ${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (installed) ...[
                            TextButton.icon(
                              onPressed: _loading ? null : () => _checkCoreUpdate(core),
                              icon: const Icon(Icons.update, size: 18),
                              label: Text(l10n.updateCore),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _loading ? null : () => _reinstallCore(core),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(l10n.refresh),
                            ),
                          ] else
                            FilledButton.icon(
                              onPressed: _loading ? null : () => _installCore(core),
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(l10n.installCore),
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
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    
    try {
      final releaseInfo = await XrayDownloader.instance.getLatestReleaseInfo();
      
      if (releaseInfo != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${l10n.latestVersion} Xray-core'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${l10n.version}: ${releaseInfo['version']}'),
                  const SizedBox(height: 8),
                  Text('${l10n.today}: ${releaseInfo['published_at']}'),
                  const SizedBox(height: 16),
                  Text(
                    'Release Notes:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(releaseInfo['body'] ?? l10n.noData),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _installCore(CoreType core) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _downloadProgress[core] = 0.0;
    });
    
    try {
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
            SnackBar(content: Text(l10n.coreInstalled)),
          );
        }
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.coreInstallFailed}: $e')),
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    
    try {
      final newVersion = await XrayDownloader.instance.checkForUpdate();
      
      if (newVersion != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.updateAvailable),
              content: Text('${l10n.latestVersion}: $newVersion\n\n${l10n.downloadUpdate}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.updateCore),
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
            SnackBar(content: Text(l10n.upToDate)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
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
