import 'package:flutter/material.dart';

/// Custom vector painter rendering iconic high-speed and regional train silhouettes.
class TrainSilhouetteIcon extends StatelessWidget {
  final String trainType;
  final Color color;
  final double width;
  final double height;

  const TrainSilhouetteIcon({
    super.key,
    required this.trainType,
    required this.color,
    this.width = 36,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isBulletTrain = trainType.contains('AVE') ||
        trainType.contains('Avlo') ||
        trainType.contains('Freccia') ||
        trainType.contains('TGV') ||
        trainType.contains('Iryo') ||
        trainType.contains('Ouigo') ||
        trainType.contains('S-106');

    return CustomPaint(
      size: Size(width, height),
      painter: _TrainSilhouettePainter(
        color: color,
        isBulletTrain: isBulletTrain,
      ),
    );
  }
}

class _TrainSilhouettePainter extends CustomPainter {
  final Color color;
  final bool isBulletTrain;

  _TrainSilhouettePainter({
    required this.color,
    required this.isBulletTrain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isBulletTrain) {
      // Aerodynamic pointed bullet nose (AVE / Frecciarossa / S-106 / TGV)
      path.moveTo(0, h * 0.85); // bottom left
      path.lineTo(w * 0.70, h * 0.85); // bottom flat body
      // Aerodynamic sleek nose curve
      path.cubicTo(w * 0.88, h * 0.85, w * 0.98, h * 0.65, w, h * 0.50);
      path.cubicTo(w * 0.98, h * 0.35, w * 0.82, h * 0.20, w * 0.65, h * 0.20);
      path.lineTo(w * 0.15, h * 0.20); // roof line
      // Cab / tail slant
      path.lineTo(0, h * 0.35);
      path.close();

      // Cockpit windshield cutout
      final windowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      final windowPath = Path()
        ..moveTo(w * 0.66, h * 0.30)
        ..lineTo(w * 0.82, h * 0.35)
        ..lineTo(w * 0.78, h * 0.50)
        ..lineTo(w * 0.66, h * 0.45)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(windowPath, windowPaint);
    } else {
      // Classic regional and commuter nose.
      path.moveTo(0, h * 0.85);
      path.lineTo(w * 0.80, h * 0.85);
      path.cubicTo(w * 0.95, h * 0.85, w, h * 0.75, w, h * 0.55);
      path.lineTo(w * 0.95, h * 0.25);
      path.lineTo(0, h * 0.25);
      path.close();

      final windowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      final windowPath = Path()
        ..moveTo(w * 0.75, h * 0.35)
        ..lineTo(w * 0.92, h * 0.38)
        ..lineTo(w * 0.90, h * 0.55)
        ..lineTo(w * 0.75, h * 0.55)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(windowPath, windowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrainSilhouettePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isBulletTrain != isBulletTrain;
  }
}
