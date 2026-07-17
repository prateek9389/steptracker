import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CircularProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0+
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? trackColor;
  final List<Color>? gradientColors;

  const CircularProgressRing({
    Key? key,
    required this.progress,
    required this.size,
    this.strokeWidth = 16.0,
    this.child,
    this.trackColor,
    this.gradientColors,
  }) : super(key: key);

  @override
  State<CircularProgressRing> createState() => _CircularProgressRingState();
}

class _CircularProgressRingState extends State<CircularProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RingPainter(
            progress: _animation.value,
            strokeWidth: widget.strokeWidth,
            isDark: Theme.of(context).brightness == Brightness.dark,
            trackColor: widget.trackColor,
            gradientColors: widget.gradientColors,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final bool isDark;
  final Color? trackColor;
  final List<Color>? gradientColors;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.isDark,
    this.trackColor,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Draw glowing shadow under the progress arc (only on dark mode for neon glow)
    if (isDark && trackColor == null) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..color = AppColors.primary.withOpacity(0.3);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        glowPaint,
      );
    }

    // Draw primary gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors ?? [
          AppColors.primary,
          AppColors.secondary,
          AppColors.primary,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -pi / 2,
      progress * 2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark || oldDelegate.trackColor != trackColor;
  }
}
