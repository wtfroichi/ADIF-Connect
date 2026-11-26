import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.blurSigma = 20,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final surface = backgroundColor ??
        (isDark
            ? const Color(0xFF161F2A).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.78));
    final edge = borderColor ??
        (isDark ? const Color(0xFF2B394A) : const Color(0xFFD0D9E2));

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppTheme.adifTeal)
                .withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: edge, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}
