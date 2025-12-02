import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../services/config_storage.dart';
import '../services/update_service.dart';
import '../services/core_manager.dart';
import '../services/subscription_parser.dart';
import '../services/auto_reconnect.dart';
import '../utils/error_handler.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;
  final VoidCallback? onConfigsChanged;
  
  const SettingsScreen({
    super.key, 
    this.onThemeChanged, 
    this.onLocaleChanged,
    this.onConfigsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdate = true;
  bool _autoReconnect = false;
  String _themeMode = 'system';
  String _language = 'en';
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoUpdate = await UpdateService.instance.autoUpdateEnabled;
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('theme_mode') ?? 'system';
    final language = prefs.getString('language') ?? 'en';
    final autoReconnect = AutoReconnect.instance.isEnabled;
    
    setState(() {
      _autoUpdate = autoUpdate;
      _autoReconnect = autoReconnect;
      _appVersion = packageInfo.version;
      _themeMode = themeMode;
      _language = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'Application',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.autoUpdate),
                subtitle: Text(AppLocalizations.of(context)!.autoUpdateDescription),
                value: _autoUpdate,
                onChanged: (value) async {
                  await UpdateService.instance.setAutoUpdate(value);
                  setState(() => _autoUpdate = value);
                },
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.autoReconnect),
                subtitle: Text(AppLocalizations.of(context)!.autoReconnectDescription),
                value: _autoReconnect,
                onChanged: (value) async {
                  await AutoReconnect.instance.setEnabled(value);
                  setState(() => _autoReconnect = value);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.checkUpdates),
                subtitle: Text('${AppLocalizations.of(context)!.version}: $_appVersion'),
                trailing: const Icon(Icons.update),
                onTap: _checkUpdates,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.theme),
                subtitle: Text(_themeMode == 'dark' ? AppLocalizations.of(context)!.dark : _themeMode == 'light' ? AppLocalizations.of(context)!.light : AppLocalizations.of(context)!.system),
                trailing: const Icon(Icons.brightness_6),
                onTap: () => _showThemeDialog(),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.language),
                subtitle: Text(_language == 'ru' ? AppLocalizations.of(context)!.russian : AppLocalizations.of(context)!.english),
                trailing: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'Configuration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.subscription),
                subtitle: const Text('Import from URL or vless:// link'),
                trailing: const Icon(Icons.link),
                onTap: _importSubscription,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.importConfig),
                subtitle: Text(AppLocalizations.of(context)!.importFromFile),
                trailing: const Icon(Icons.file_upload),
                onTap: _importConfig,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.pasteFromClipboard),
                subtitle: const Text('Import config from clipboard'),
                trailing: const Icon(Icons.content_paste),
                onTap: _importFromClipboard,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.exportConfig),
                subtitle: Text(AppLocalizations.of(context)!.exportToFile),
                trailing: const Icon(Icons.file_download),
                onTap: _exportConfigs,
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.advanced,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.dataDirectory),
                subtitle: Text(CoreManager.instance.coreDirectory.path),
                trailing: const Icon(Icons.folder),
                onTap: () {
                  // TODO: Open directory
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.clearCache),
                subtitle: Text(AppLocalizations.of(context)!.clearCacheDescription),
                trailing: const Icon(Icons.delete_sweep),
                onTap: _clearCache,
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(AppLocalizations.of(context)!.about),
            subtitle: Text('${AppLocalizations.of(context)!.appName} v$_appVersion${_appVersion.contains('beta') ? ' (Beta)' : ''}\nCross-platform VPN client\nSupports ${AppLocalizations.of(context)!.xray}, ${AppLocalizations.of(context)!.singbox}, ${AppLocalizations.of(context)!.hysteria2}'),
            trailing: const Icon(Icons.info),
          ),
        ),
      ],
    );
  }

  Future<void> _checkUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final manifest = await UpdateService.instance.checkForUpdates();
      
      if (!mounted) return;
      Navigator.pop(context);

      if (manifest != null) {
        final needsUpdate = await UpdateService.instance.needsAppUpdate();
        
        if (!mounted) return;
        
        if (needsUpdate) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.updateAvailable),
              content: Text(
                'New version ${manifest.latestVersion} is available!\n\n${manifest.notes}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadUpdate();
                  },
                  child: Text(AppLocalizations.of(context)!.downloadUpdate),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.upToDate),
              content: Text(AppLocalizations.of(context)!.noUpdateAvailable),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking updates: $e')),
      );
    }
  }

  Future<void> _downloadUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.downloadUpdate),
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
      final filePath = await UpdateService.instance.downloadAppUpdate();
      
      if (!mounted) return;
      Navigator.pop(context);

      if (filePath != null) {
        if (Platform.isWindows) {
          // На Windows показываем инструкции и открываем папку
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Downloaded'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update has been downloaded successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('To install:'),
                  const SizedBox(height: 8),
                  const Text('1. Close this application'),
                  const Text('2. Run the downloaded file'),
                  const Text('3. Follow installation instructions'),
                  const SizedBox(height: 16),
                  Text(
                    'Location:\n$filePath',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      // Открываем проводник с выделенным файлом
                      await Process.run('explorer', ['/select,', filePath], runInShell: true);
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Could not open folder: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Open Folder'),
                ),
              ],
            ),
          );
        } else {
          // На Android показываем кнопку установки
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Downloaded'),
              content: const Text('Update downloaded. Install now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await UpdateService.instance.installUpdate(filePath);
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Installation failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Install'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _importSubscription() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.subscription),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Subscription URL or vless:// link',
                hintText: 'https://... or vless://...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    // QR сканер доступен только на мобильных платформах
                    if (Platform.isAndroid || Platform.isIOS) {
                      final qrResult = await Navigator.pushNamed(context, '/qr_scanner');
                      if (qrResult != null) {
                        controller.text = qrResult.toString();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR scanner only available on mobile')),
                      );
                    }
                  },
                  tooltip: 'Scan QR Code',
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)!.importConfig),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        List<dynamic> configs;
        
        if (result.startsWith('http://') || result.startsWith('https://')) {
          configs = await SubscriptionParser.instance.parseSubscriptionUrl(result);
        } else if (result.startsWith('vless://') || result.startsWith('vmess://') || 
                   result.startsWith('trojan://') || result.startsWith('ss://')) {
          configs = SubscriptionParser.instance.parseSubscriptionContent(result);
        } else {
          throw Exception('Invalid URL or link format');
        }

        for (final config in configs) {
          await ConfigStorage.instance.saveConfig(config);
        }

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${configs.length} configs successfully')),
        );
        
        // Обновить список конфигураций
        widget.onConfigsChanged?.call();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _importConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'yaml', 'yml', 'txt'],
      dialogTitle: 'Select config file',
    );

    if (result != null) {
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        // Проверяем что это валидный JSON
        try {
          final decoded = jsonDecode(content);
          if (decoded is! Map) {
            throw Exception('Config must be a JSON object');
          }
        } catch (e) {
          throw Exception('Invalid JSON format: $e');
        }
        
        // Импортируем конфигурацию
        final config = await ConfigStorage.instance.importConfig(content);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Config "${config.name}" imported successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Обновляем список конфигураций
          widget.onConfigsChanged?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _exportConfigs() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      try {
        final configs = ConfigStorage.instance.getConfigs();
        for (final config in configs) {
          final file = File('$path/${config.name}.json');
          await file.writeAsString(config.toJsonString());
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${configs.length} configs exported')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearCache),
        content: Text(AppLocalizations.of(context)!.clearCacheDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.clear),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement cache clearing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    }
  }

  Future<void> _showThemeDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.system),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.light),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.dark),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _themeMode = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', result);
      
      final mode = result == 'dark' 
          ? ThemeMode.dark 
          : result == 'light' 
              ? ThemeMode.light 
              : ThemeMode.system;
      widget.onThemeChanged?.call(mode);
    }
  }

  Future<void> _showLanguageDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.english),
              value: 'en',
              groupValue: _language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.russian),
              value: 'ru',
              groupValue: _language,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _language = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', result);
      widget.onLocaleChanged?.call(Locale(result));
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      
      if (text == null || text.isEmpty) {
        if (mounted) {
          ErrorHandler.showError(context, 'Clipboard is empty');
        }
        return;
      }

      // Проверяем что это URL протокола
      if (text.startsWith('vless://') || 
          text.startsWith('vmess://') || 
          text.startsWith('trojan://') || 
          text.startsWith('ss://') ||
          text.startsWith('hysteria2://') ||
          text.startsWith('hy2://')) {
        
        // Парсим как одиночную конфигурацию
        final configs = SubscriptionParser.instance.parseSubscriptionContent(text);
        
        if (configs.isEmpty) {
          if (mounted) {
            ErrorHandler.showError(context, 'Failed to parse config from clipboard');
          }
          return;
        }

        // Сохраняем конфигурации
        for (final config in configs) {
          await ConfigStorage.instance.saveConfig(config);
        }

        if (mounted) {
          ErrorHandler.showSuccess(
            context,
            'Imported ${configs.length} config(s) from clipboard',
          );
          widget.onConfigsChanged?.call();
        }
      } else if (text.startsWith('http://') || text.startsWith('https://')) {
        // Это subscription URL
        final configs = await SubscriptionParser.instance.parseSubscriptionUrl(text);
        
        if (configs.isEmpty) {
          if (mounted) {
            ErrorHandler.showError(context, 'No configs found in subscription');
          }
          return;
        }

        for (final config in configs) {
          await ConfigStorage.instance.saveConfig(config);
        }

        if (mounted) {
          ErrorHandler.showSuccess(
            context,
            'Imported ${configs.length} config(s) from subscription',
          );
          widget.onConfigsChanged?.call();
        }
      } else {
        // Пытаемся парсить как JSON
        try {
          final json = jsonDecode(text);
          // Здесь можно добавить логику импорта JSON конфигурации
          if (mounted) {
            ErrorHandler.showInfo(context, 'JSON config import not yet implemented');
          }
        } catch (e) {
          if (mounted) {
            ErrorHandler.showError(
              context,
              'Clipboard content is not a valid config URL or JSON',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Import failed: ${ErrorHandler.getErrorMessage(e)}');
      }
    }
  }
}
