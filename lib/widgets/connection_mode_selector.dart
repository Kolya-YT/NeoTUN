import 'package:flutter/material.dart';
import '../services/tun_manager.dart';

class ConnectionModeSelector extends StatefulWidget {
  final TunMode currentMode;
  final Function(TunMode) onModeChanged;
  final bool enabled;

  const ConnectionModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.enabled = true,
  });

  @override
  State<ConnectionModeSelector> createState() => _ConnectionModeSelectorState();
}

class _ConnectionModeSelectorState extends State<ConnectionModeSelector> {
  bool _tunSupported = false;

  @override
  void initState() {
    super.initState();
    _checkTunSupport();
  }

  Future<void> _checkTunSupport() async {
    final supported = await TunManager.instance.isTunSupported();
    if (mounted) {
      setState(() {
        _tunSupported = supported;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.swap_horiz, size: 20),
                SizedBox(width: 8),
                Text(
                  'Connection Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<TunMode>(
              segments: [
                const ButtonSegment<TunMode>(
                  value: TunMode.proxy,
                  label: Text('Proxy'),
                  icon: Icon(Icons.language),
                ),
                ButtonSegment<TunMode>(
                  value: TunMode.tun,
                  label: const Text('TUN'),
                  icon: const Icon(Icons.vpn_lock),
                  enabled: _tunSupported,
                ),
              ],
              selected: {widget.currentMode},
              onSelectionChanged: widget.enabled
                  ? (Set<TunMode> newSelection) {
                      widget.onModeChanged(newSelection.first);
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _getModeDescription(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (!_tunSupported && widget.currentMode == TunMode.tun)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'TUN mode not supported on this device',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getModeDescription() {
    switch (widget.currentMode) {
      case TunMode.proxy:
        return 'System proxy mode - Works with most apps, requires manual proxy configuration in some cases';
      case TunMode.tun:
        return 'TUN mode - Full traffic capture, works with all apps automatically (requires VPN permission on Android)';
    }
  }
}
