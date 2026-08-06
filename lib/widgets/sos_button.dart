import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isRecording;

  const SOSButton({
    super.key,
    required this.onTap,
    this.isRecording = false,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFF5252),
                    AppTheme.primaryRed,
                    Color(0xFFB71C1C),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(widget.isRecording ? 0.8 : 0.4),
                    spreadRadius: widget.isRecording ? 16 : 8,
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isRecording
                          ? Icons.videocam_rounded
                          : Icons.touch_app_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isRecording ? "RECORDING" : "SOS",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isRecording
                          ? "EVIDENCE COLLECTION"
                          : "PRESS FOR EMERGENCY",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}