import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/plant_phase.dart';

class PlantCanvas extends StatelessWidget {
  const PlantCanvas({
    super.key,
    required this.growth,
    required this.phase,
  });

  final double growth;
  final PlantPhase phase;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _PlantPainter(growth: growth, phase: phase),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter({required this.growth, required this.phase});

  final double growth;
  final PlantPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final soil = Paint()..color = const Color(0xFF3F2E1F);
    final ground = Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22);
    canvas.drawRRect(RRect.fromRectAndRadius(ground, const Radius.circular(28)), soil);

    final withered = phase == PlantPhase.withered;
    final bloomed = phase == PlantPhase.bloomed;
    final stemColor = withered ? const Color(0xFF8B6914) : const Color(0xFF047857);
    final leafColor = withered ? const Color(0xFFA16207) : AppColors.mint;
    final t = growth.clamp(0.0, 1.0);

    final origin = Offset(size.width * 0.5, size.height * 0.78);
    final stemH = size.height * (0.18 + t * 0.42);
    final lean = withered ? 0.22 : 0.0;
    final top = Offset(origin.dx + size.width * lean * t, origin.dy - stemH);

    final stem = Paint()
      ..color = stemColor
      ..strokeWidth = 7 + t * 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(origin, top, stem);

    if (t > 0.18) {
      _leaf(canvas, origin.translate(-18, -stemH * 0.45), -1.1, t, leafColor, withered);
      _leaf(canvas, origin.translate(16, -stemH * 0.55), 0.9, t, leafColor, withered);
    }
    if (t > 0.45) {
      _leaf(canvas, origin.translate(-28, -stemH * 0.72), -0.7, t, leafColor, withered);
      _leaf(canvas, origin.translate(24, -stemH * 0.7), 0.55, t, leafColor, withered);
    }

    if (bloomed || (t > 0.85 && !withered)) {
      final glow = Paint()
        ..color = AppColors.mint.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(top, 22, glow);
      canvas.drawCircle(top, 10, Paint()..color = AppColors.mintSoft);
    } else if (t > 0.28) {
      canvas.drawCircle(top, 6 + t * 4, Paint()..color = leafColor);
    }
  }

  void _leaf(
    Canvas canvas,
    Offset from,
    double angle,
    double t,
    Color color,
    bool withered,
  ) {
    final path = Path();
    final len = 28 + t * 26;
    final tip = from + Offset(math.cos(angle) * len, math.sin(angle) * (withered ? len * 0.9 : -len * 0.15));
    path.moveTo(from.dx, from.dy);
    path.quadraticBezierTo(
      (from.dx + tip.dx) / 2 + (withered ? 12 : -8),
      (from.dy + tip.dy) / 2,
      tip.dx,
      tip.dy,
    );
    path.quadraticBezierTo(
      (from.dx + tip.dx) / 2 + (withered ? -6 : 10),
      (from.dy + tip.dy) / 2 + 8,
      from.dx,
      from.dy,
    );
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return oldDelegate.growth != growth || oldDelegate.phase != phase;
  }
}
