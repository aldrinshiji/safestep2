import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class QuickActionCards extends StatelessWidget {
  final VoidCallback? onLiveVideoTap;
  final VoidCallback? onVoiceRecorderTap;
  final VoidCallback? onLiveLocationTap;
  final String themePreset;

  const QuickActionCards({
    super.key,
    this.onLiveVideoTap,
    this.onVoiceRecorderTap,
    this.onLiveLocationTap,
    this.themePreset = 'cyber_dark',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(themePreset);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              context: context,
              icon: Icons.videocam_outlined,
              title: "Live Video",
              subtitle: "Recording",
              iconColor: colors.primaryRed,
              tileBg: colors.primaryRed.withOpacity(0.15),
              onTap: onLiveVideoTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context: context,
              icon: Icons.mic_none_rounded,
              title: "Voice",
              subtitle: "Recorder",
              iconColor: colors.accentPurple,
              tileBg: colors.accentPurple.withOpacity(0.15),
              onTap: onVoiceRecorderTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context: context,
              icon: Icons.location_on_outlined,
              title: "Live Location",
              subtitle: "Share",
              iconColor: colors.accentCyan,
              tileBg: colors.accentCyan.withOpacity(0.15),
              onTap: onLiveLocationTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color tileBg,
    VoidCallback? onTap,
  }) {
    final colors = AppTheme.getColors(themePreset);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.4)),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
