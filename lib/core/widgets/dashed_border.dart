import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DashedBorder extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const DashedBorder({
    super.key,
    required this.child,
    required this.borderColor,
    required this.backgroundColor,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: borderColor,
          radius: borderRadius,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final rect = ui.Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final path = ui.Path()
      ..addRRect(ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)));
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 7) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + 4).clamp(0.0, metric.length).toDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
