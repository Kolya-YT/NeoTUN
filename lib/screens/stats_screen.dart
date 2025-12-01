import 'package:flutter/material.dart';
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
        title: const Text('Statistics'),
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
                'Current Session',
                [
                  _buildStatRow(
                    Icons.upload,
                    'Upload',
                    TrafficStats.instance.formatBytes(sessionUpload),
                    Colors.blue,
                  ),
                  _buildStatRow(
                    Icons.download,
                    'Download',
                    TrafficStats.instance.formatBytes(sessionDownload),
                    Colors.green,
                  ),
                  _buildStatRow(
                    Icons.timer,
                    'Duration',
                    TrafficStats.instance.formatDuration(duration),
                    Colors.orange,
                  ),
                ],
                isDark,
              ),
              const SizedBox(height: 16),
              _buildStatsCard(
                'Total Statistics',
                [
                  _buildStatRow(
                    Icons.upload,
                    'Total Upload',
                    TrafficStats.instance.formatBytes(totalUpload),
                    Colors.blue,
                  ),
                  _buildStatRow(
                    Icons.download,
                    'Total Download',
                    TrafficStats.instance.formatBytes(totalDownload),
                    Colors.green,
                  ),
                  _buildStatRow(
                    Icons.swap_vert,
                    'Total Traffic',
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
        title: const Text('Reset Statistics'),
        content: const Text('Are you sure you want to reset all statistics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TrafficStats.instance.resetTotal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistics reset successfully')),
        );
      }
    }
  }
}
