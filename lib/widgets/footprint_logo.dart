import 'package:flutter/material.dart';

class FootprintLogo extends StatelessWidget {
  final double size;
  final Color color;

  const FootprintLogo({
    super.key,
    this.size = 28.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: _FootprintPainter(color: color),
    );
  }
}

class _FootprintPainter extends CustomPainter {
  final Color color;

  _FootprintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // --- Left Footprint ---
    // Sole
    final leftSole = Path();
    leftSole.moveTo(w * 0.15, h * 0.55);
    leftSole.cubicTo(w * 0.05, h * 0.65, w * 0.08, h * 0.88, w * 0.25, h * 0.92);
    leftSole.cubicTo(w * 0.40, h * 0.95, w * 0.42, h * 0.72, w * 0.35, h * 0.52);
    leftSole.cubicTo(w * 0.30, h * 0.38, w * 0.18, h * 0.42, w * 0.15, h * 0.55);
    leftSole.close();
    canvas.drawPath(leftSole, paint);

    // Left Toes (5 oval dots)
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.32, w * 0.09, h * 0.13), paint); // Big toe
    canvas.drawCircle(Offset(w * 0.25, h * 0.35), w * 0.035, paint);
    canvas.drawCircle(Offset(w * 0.19, h * 0.38), w * 0.03, paint);
    canvas.drawCircle(Offset(w * 0.13, h * 0.42), w * 0.026, paint);
    canvas.drawCircle(Offset(w * 0.08, h * 0.47), w * 0.022, paint);

    // --- Right Footprint (slightly higher and offset) ---
    // Sole
    final rightSole = Path();
    rightSole.moveTo(w * 0.65, h * 0.35);
    rightSole.cubicTo(w * 0.55, h * 0.45, w * 0.58, h * 0.68, w * 0.75, h * 0.72);
    rightSole.cubicTo(w * 0.90, h * 0.75, w * 0.92, h * 0.52, w * 0.85, h * 0.32);
    rightSole.cubicTo(w * 0.80, h * 0.18, w * 0.68, h * 0.22, w * 0.65, h * 0.35);
    rightSole.close();
    canvas.drawPath(rightSole, paint);

    // Right Toes (5 oval dots)
    canvas.drawOval(Rect.fromLTWH(w * 0.58, h * 0.12, w * 0.09, h * 0.13), paint); // Big toe
    canvas.drawCircle(Offset(w * 0.71, h * 0.15), w * 0.035, paint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.18), w * 0.03, paint);
    canvas.drawCircle(Offset(w * 0.84, h * 0.22), w * 0.026, paint);
    canvas.drawCircle(Offset(w * 0.89, h * 0.27), w * 0.022, paint);
  }

  @override
  bool shouldRepaint(covariant _FootprintPainter oldDelegate) =>
      oldDelegate.color != color;
}
