import 'package:flutter/material.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../models/vpn_config.dart';
import '../models/core_type.dart';
import '../services/config_storage.dart';

class ConfigEditorScreen extends StatefulWidget {
  final VpnConfig? config;

  const ConfigEditorScreen({super.key, this.config});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _configController;
  late CoreType _selectedCore;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _configController = TextEditingController(
      text: widget.config != null
          ? const JsonEncoder.withIndent('  ').convert(widget.config!.config)
          : '{}',
    );
    _selectedCore = widget.config?.coreType ?? CoreType.xray;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? AppLocalizations.of(context)!.addConfig : AppLocalizations.of(context)!.editConfig),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.configName),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CoreType>(
              value: _selectedCore,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.coreType),
              items: CoreType.values.map((core) {
                return DropdownMenuItem(
                  value: core,
                  child: Text(core.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCore = value!),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _configController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.jsonConfig,
                  border: const OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    try {
      final config = VpnConfig(
        id: widget.config?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        coreType: _selectedCore,
        config: jsonDecode(_configController.text),
      );

      await ConfigStorage.instance.saveConfig(config);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _configController.dispose();
    super.dispose();
  }
}
