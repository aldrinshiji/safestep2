import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final bool isSafe;
  final bool gpsReady;
  final bool cameraReady;
  final bool micReady;
  final bool internetReady;
  final VoidCallback? onTapPermissions;

  const StatusCard({
    super.key,
    required this.isSafe,
    required this.gpsReady,
    required this.cameraReady,
    required this.micReady,
    required this.internetReady,
    this.onTapPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isSafe
        ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3E1F1F) : const Color(0xFFFFEBEE));

    final borderColor = isSafe ? Colors.green : AppTheme.primaryRed;

    return GestureDetector(
      onTap: onTapPermissions,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSafe
                        ? Icons.shield_rounded
                        : Icons.warning_amber_rounded,
                    color: borderColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSafe ? "System Protected" : "EMERGENCY ACTIVATED",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSafe
                            ? "Shake device or press SOS to send alert"
                            : "Capturing evidence & notifying guardian...",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTapPermissions != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge("GPS", gpsReady, Icons.location_on_rounded),
                _buildBadge("Camera", cameraReady, Icons.videocam_rounded),
                _buildBadge("Mic", micReady, Icons.mic_rounded),
                _buildBadge("Internet", internetReady, Icons.wifi_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, bool active, IconData icon) {
    final color = active ? Colors.green : AppTheme.primaryOrange;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
