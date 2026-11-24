import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// iOS 26/27 Liquid Crystal / Glass frosted container.
/// Features BackdropFilter blur, specular subtle border gradient, and optional operator ambient glow.
class GlassContainer extends StatelessWidget {
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

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final defaultBg =
        isDark ? AppTheme.darkGlassSurface : AppTheme.lightGlassSurface;
    final defaultBorder =
        isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (glowColor != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
