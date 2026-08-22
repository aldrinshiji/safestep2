import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isRecording;
  final String themePreset;
  final double? targetDiameter;

  const SOSButton({
    super.key,
    required this.onTap,
    this.isRecording = false,
    this.themePreset = 'cyber_dark',
    this.targetDiameter,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(widget.themePreset);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic maximum diameter based on available container width
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final baseDiameter = widget.targetDiameter ?? min(availableWidth, 230.0);

        final outerGlowSize = baseDiameter;
        final outerRingSize = baseDiameter * 0.94;
        final innerRingSize = baseDiameter * 0.86;
        final orbSize = baseDiameter * 0.72;

        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _isPressed ? 0.94 : (widget.isRecording ? _pulseAnimation.value : 1.0);
            final glowOpacity = widget.isRecording ? 0.9 : _glowAnimation.value;

            return GestureDetector(
              onTapDown: (_) {
                HapticFeedback.heavyImpact();
                setState(() => _isPressed = true);
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: outerGlowSize,
                  height: outerGlowSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // --- Layer 1: Ambient Outer Neon Glow Wave ---
                      Container(
                        width: outerGlowSize,
                        height: outerGlowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primaryRed.withOpacity(glowOpacity * 0.4),
                              blurRadius: 32,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),

                      // --- Layer 2: Outer Ring Accent ---
                      Container(
                        width: outerRingSize,
                        height: outerRingSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primaryRed.withOpacity(0.35),
                            width: 1.8,
                          ),
                        ),
                      ),

                      // --- Layer 3: Concentric Neon Ring ---
                      Container(
                        width: innerRingSize,
                        height: innerRingSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primaryRed.withOpacity(0.8),
                            width: 3.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primaryRed.withOpacity(0.45),
                              blurRadius: 12,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),

                      // --- Layer 4: Main SOS 3D Sphere Button ---
                      Container(
                        width: orbSize,
                        height: orbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: widget.isRecording
                                ? [
                                    const Color(0xFFFF5252),
                                    colors.primaryRed,
                                    const Color(0xFF88001B),
                                  ]
                                : [
                                    const Color(0xFFFF4D6D),
                                    colors.primaryRed,
                                    const Color(0xFF990024),
                                  ],
                            center: const Alignment(-0.25, -0.35),
                            radius: 0.85,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primaryRed.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.isRecording) ...[
                                Icon(
                                  Icons.videocam_rounded,
                                  size: orbSize * 0.22,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 2),
                              ],
                              FittedBox(
                                child: Text(
                                  widget.isRecording ? "RECORDING" : "SOS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: widget.isRecording ? 18 : orbSize * 0.26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: widget.isRecording ? 1.5 : 3.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.isRecording) ...[
                                const SizedBox(height: 2),
                                const Text(
                                  "EVIDENCE COLLECTION",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}