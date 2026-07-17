import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? fillColor;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.blur = 0.0,
    this.borderColor,
    this.fillColor,
    this.shadow,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? const Color(0x1AFFFFFF)
                  : const Color(0x1F000000)),
          width: 1.5,
        ),
        gradient: gradient ??
            LinearGradient(
              colors: isDark
                  ? [
                      fillColor ?? const Color(0x15FFFFFF),
                      fillColor?.withOpacity(0.5) ?? const Color(0x05FFFFFF),
                    ]
                  : [
                      fillColor ?? const Color(0xFFFFFFFF),
                      fillColor?.withOpacity(0.9) ?? const Color(0xFFF5F3FF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      ),
      child: child,
    );

    if (blur > 0.0) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: cardContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow ??
            [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.black12,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: cardContent,
    );
  }
}
