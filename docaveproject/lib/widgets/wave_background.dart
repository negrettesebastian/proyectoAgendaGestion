import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Fondo degradado
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyMid, AppColors.navy],
          ),
        ),
      ),
      // Onda cian derecha
      Positioned(
        right: -60,
        top: 40,
        child: SizedBox(
          width: 300,
          height: 520,
          child: CustomPaint(painter: _WavePainter()),
        ),
      ),
      // Orbe izquierdo
      Positioned(
        left: -100,
        bottom: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan.withOpacity(0.07),
          ),
        ),
      ),
      // Orbe derecho
      Positioned(
        right: -60,
        top: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blue.withOpacity(0.09),
          ),
        ),
      ),
    ]);
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 14; i++) {
      final opacity = (0.05 + i * 0.018).clamp(0.0, 0.35);
      paint.color = AppColors.cyan.withOpacity(opacity);
      final path = Path();
      final yBase = 100.0 + i * 22;
      for (double x = 0; x <= size.width; x += 2) {
        final y = yBase +
            28 * sin(x / size.width * pi + i * 0.3) +
            16 * sin(x / size.width * 2 * pi - i * 0.15);
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
