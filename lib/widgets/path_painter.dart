import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PathPainter extends CustomPainter {
  final int itemCount;
  final double itemHeight;
  final double animationValue;

  PathPainter({
    required this.itemCount,
    required this.itemHeight,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount == 0) return;

    final centerX = size.width / 2;
    final paint = Paint()
      ..color = const Color(AppConstants.primaryGreen).withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Começar do primeiro ponto
    path.moveTo(centerX, 0);

    // Criar curva serpenteante conectando os pontos
    for (int i = 0; i < itemCount; i++) {
      final y = i * itemHeight;
      final nextY = (i + 1) * itemHeight;

      // Alternar direção da curva
      final isLeft = i % 2 == 0;
      final curveOffset = isLeft ? -30.0 : 30.0;

      if (i < itemCount - 1) {
        // Ponto de controle para curva Bézier
        final controlY = y + (itemHeight / 2);

        path.quadraticBezierTo(centerX + curveOffset, controlY, centerX, nextY);
      }
    }

    // Desenhar apenas a porção animada do caminho
    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * animationValue);

    canvas.drawPath(animatedPath, paint);

    // Desenhar pontos/marcos
    final markerPaint = Paint()
      ..color = const Color(AppConstants.primaryGreen)
      ..style = PaintingStyle.fill;

    final markerOutlinePaint = Paint()
      ..color = const Color(AppConstants.primaryGreen).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final markerBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < itemCount; i++) {
      if (i / itemCount <= animationValue) {
        final y = i * itemHeight;

        // Círculo externo (halo)
        canvas.drawCircle(Offset(centerX, y), 20, markerOutlinePaint);

        // Círculo interno
        canvas.drawCircle(Offset(centerX, y), 8, markerPaint);

        // Borda branca
        canvas.drawCircle(Offset(centerX, y), 8, markerBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.itemHeight != itemHeight ||
        oldDelegate.animationValue != animationValue;
  }
}
