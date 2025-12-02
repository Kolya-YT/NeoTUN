import 'package:flutter/material.dart';
import '../services/traffic_stats.dart';

class SpeedIndicator extends StatelessWidget {
  final bool isCompact;
  
  const SpeedIndicator({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: TrafficStats.instance.statsStream,
      initialData: TrafficStats.instance.currentStats,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final uploadSpeed = stats['upload_speed'] ?? 0;
        final downloadSpeed = stats['download_speed'] ?? 0;
        
        if (isCompact) {
          return _buildCompactView(uploadSpeed, downloadSpeed);
        }
        
        return _buildFullView(context, uploadSpeed, downloadSpeed);
      },
    );
  }

  Widget _buildCompactView(int uploadSpeed, int downloadSpeed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward, size: 12, color: Colors.blue.shade300),
        const SizedBox(width: 2),
        Text(
          _formatSpeed(uploadSpeed),
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_downward, size: 12, color: Colors.green.shade300),
        const SizedBox(width: 2),
        Text(
          _formatSpeed(downloadSpeed),
          style: TextStyle(
            fontSize: 10,
            color: Colors.green.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFullView(BuildContext context, int uploadSpeed, int downloadSpeed) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpeedItem(
            Icons.arrow_upward,
            _formatSpeed(uploadSpeed),
            Colors.blue,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 20,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(width: 16),
          _buildSpeedItem(
            Icons.arrow_downward,
            _formatSpeed(downloadSpeed),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedItem(IconData icon, String speed, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          speed,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond}B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)}KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)}MB/s';
    }
  }
}
