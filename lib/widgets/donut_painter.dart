import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutPainter extends CustomPainter {
  DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - 17,
    );
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / total) * math.pi * 2;
      final adjustedSweep = math.max(0.0, sweep - 0.05);

      paint.color = colors[index % colors.length];
      
      canvas.drawArc(rect, start + 0.025, adjustedSweep, false, paint);
        start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => true;
}
