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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lightning bolt + Label
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: colors.primaryRed,
                size: 18,
              ),
              const SizedBox(width: 3),
              Text(
                "Activate SOS by:",
                style: TextStyle(
                  color: colors.primaryRed,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildTriggerChip(
                    context,
                    icon: Icons.touch_app_outlined,
                    label: "Tap Button",
                  ),
                ),
                Expanded(
                  child: _buildTriggerChip(
                    context,
                    icon: Icons.vibration_rounded,
                    label: "Shake Device",
                  ),
                ),
                Expanded(
                  child: _buildTriggerChip(
                    context,
                    icon: Icons.volume_down_rounded,
                    label: "Long press Vol",
                  ),
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
          size: 16,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 9.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
