import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'footprint_logo.dart';

class StatusCard extends StatelessWidget {
  final bool isSafe;
  final bool gpsReady;
  final bool cameraReady;
  final bool micReady;
  final bool internetReady;
  final VoidCallback? onTapPermissions;
  final String themePreset;

  const StatusCard({
    super.key,
    required this.isSafe,
    required this.gpsReady,
    required this.cameraReady,
    required this.micReady,
    required this.internetReady,
    this.onTapPermissions,
    this.themePreset = 'cyber_dark',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(themePreset);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // --- 1. Top Header & Safety Status Pill Row ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SafeStep Footprint Logo & Tagline
            Expanded(
              child: Row(
                children: [
                  FootprintLogo(
                    size: 26,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Safe",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: "Step",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primaryRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "YOUR SAFETY • OUR PRIORITY",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Top-Right Glowing "You are Safe" Status Pill (Responsive with FittedBox)
            InkWell(
              onTap: onTapPermissions,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSafe
                      ? colors.safeGreen.withOpacity(0.15)
                      : colors.primaryRed.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSafe
                        ? colors.safeGreen.withOpacity(0.5)
                        : colors.primaryRed.withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSafe ? colors.safeGreen : colors.primaryRed)
                          .withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSafe ? colors.safeGreen : colors.primaryRed,
                        boxShadow: [
                          BoxShadow(
                            color: isSafe ? colors.safeGreen : colors.primaryRed,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSafe ? "You are Safe" : "SOS Active",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSafe ? colors.safeGreen : colors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // --- 2. Emergency Mode Ready Banner Card ---
        InkWell(
          onTap: onTapPermissions,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        colors.primaryRed.withOpacity(0.22),
                        colors.cardBg,
                      ]
                    : [
                        colors.primaryRed.withOpacity(0.12),
                        Colors.white,
                      ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primaryRed.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primaryRed.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Warning Triangle Tile
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primaryRed.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colors.primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSafe ? "Emergency Mode Ready" : "EMERGENCY IN PROGRESS",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSafe
                            ? "Tap SOS or use shake/volume button to activate"
                            : "Capturing evidence & alerting guardian...",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.primaryRed.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
