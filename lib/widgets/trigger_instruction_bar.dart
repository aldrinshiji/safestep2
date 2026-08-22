import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TriggerInstructionBar extends StatelessWidget {
  final String themePreset;

  const TriggerInstructionBar({
    super.key,
    this.themePreset = 'cyber_dark',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(themePreset);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lightning bolt + Label
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: colors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                "Activate SOS by:",
                style: TextStyle(
                  color: colors.primaryRed,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTriggerChip(
                  context,
                  icon: Icons.touch_app_outlined,
                  label: "Tap Button",
                ),
                _buildTriggerChip(
                  context,
                  icon: Icons.vibration_rounded,
                  label: "Shake Device",
                ),
                _buildTriggerChip(
                  context,
                  icon: Icons.volume_down_rounded,
                  label: "Long press Volume",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerChip(BuildContext context, {required IconData icon, required String label}) {
    final colors = AppTheme.getColors(themePreset);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: colors.primaryRed.withOpacity(0.85),
          size: 18,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
