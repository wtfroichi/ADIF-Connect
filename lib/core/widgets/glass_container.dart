import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_container.dart';

/// Shared card surface with restrained Liquid Glass materials on iOS.
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
    this.borderRadius = 24,
    this.blurSigma = 26.0,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return LiquidGlassContainer(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        blurSigma: blurSigma,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        glowColor: glowColor,
        onTap: onTap,
        child: child,
      );
    }

    final theme = Theme.of(context);
    final edge = borderColor ??
        (glowColor == null
            ? theme.brightness == Brightness.dark
                ? AppTheme.darkCardBorder
                : AppTheme.lightCardBorder
            : glowColor!.withValues(alpha: 0.24));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: edge, width: 0.8),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: backgroundColor ?? AppTheme.getSurfaceColor(context),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
