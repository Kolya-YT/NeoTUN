import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/traffic_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: TrafficStats.instance.statsStream,
        initialData: TrafficStats.instance.currentStats,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          final sessionUpload = stats['session_upload'] ?? 0;
          final sessionDownload = stats['session_download'] ?? 0;
          final totalUpload = stats['total_upload'] ?? 0;
          final totalDownload = stats['total_download'] ?? 0;
          final duration = stats['session_duration'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsCard(
                AppLocalizations.of(context)!.currentSession,
                [
                  _buildStatRow(
                    Icons.upload,
                    AppLocalizations.of(context)!.upload,
                    TrafficStats.instance.formatBytes(sessionUpload),
                    Colors.blue,
                  ),
                  _buildStatRow(
                    Icons.download,
                    AppLocalizations.of(context)!.download,
                    TrafficStats.instance.formatBytes(sessionDownload),
                    Colors.green,
                  ),
                  _buildStatRow(
                    Icons.timer,
                    AppLocalizations.of(context)!.duration,
                    TrafficStats.instance.formatDuration(duration),
                    Colors.orange,
                  ),
                ],
                isDark,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                AppLocalizations.of(context)!.totalStatistics,
                [
                  _buildStatRow(
                    Icons.upload,
                    AppLocalizations.of(context)!.totalUpload,
                    TrafficStats.instance.formatBytes(totalUpload),
                    Colors.blue,
                  ),
                  _buildStatRow(
                    Icons.download,
                    AppLocalizations.of(context)!.totalDownload,
                    TrafficStats.instance.formatBytes(totalDownload),
                    Colors.green,
                  ),
                  _buildStatRow(
                    Icons.swap_vert,
                    AppLocalizations.of(context)!.totalTraffic,
                    TrafficStats.instance.formatBytes(totalUpload + totalDownload),
                    Colors.purple,
                  ),
                ],
                isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetStatistics),
        content: Text(AppLocalizations.of(context)!.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TrafficStats.instance.resetTotal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.statisticsReset)),
        );
      }
    }
  }
}
